#!/usr/bin/perl

# Author: Trizen
# Date: 13 January 2024
# Edit: 05 April 2024
# https://github.com/trizen

# Create a valid Gzip container, using DEFLATE's Block Type 1: LZSS + fixed-length prefix codes.

# Reference:
#   Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip)
#   https://youtube.com/watch?v=SJPvNi4HrWQ

use 5.036;
use lib               qw(../lib);
use File::Basename    qw(basename);
use Compression::Util qw(:all);

use constant {CHUNK_SIZE => (1 << 18) - 1,};

local $Compression::Util::LZ_MIN_LEN       = 4;                # minimum match length in LZ parsing
local $Compression::Util::LZ_MAX_LEN       = 258;              # maximum match length in LZ parsing
local $Compression::Util::LZ_MAX_DIST      = (1 << 15) - 1;    # maximum allowed back-reference distance in LZ parsing
local $Compression::Util::LZ_MAX_CHAIN_LEN = 64;               # how many recent positions to remember in LZ parsing

my $MAGIC  = pack('C*', 0x1f, 0x8b);                           # magic MIME type
my $CM     = chr(0x08);                                        # 0x08 = DEFLATE
my $FLAGS  = chr(0x00);                                        # flags
my $MTIME  = pack('C*', (0x00) x 4);                           # modification time
my $XFLAGS = chr(0x00);                                        # extra flags
my $OS     = chr(0x03);                                        # 0x03 = Unix

my $input  = $ARGV[0] // die "usage: $0 [input] [output.gz]\n";
my $output = $ARGV[1] // (basename($input) . '.gz');

open my $in_fh, '<:raw', $input
  or die "Can't open file <<$input>> for reading: $!";

open my $out_fh, '>:raw', $output
  or die "Can't open file <<$output>> for writing: $!";

print $out_fh $MAGIC, $CM, $FLAGS, $MTIME, $XFLAGS, $OS;

my $total_length = 0;
my $crc32        = 0;

my $bitstring  = '';
my $block_type = '10';    # 00 = store; 10 = LZSS + Fixed codes; 01 = LZSS + Dynamic codes

my @code_lengths = (0) x 288;
foreach my $i (0 .. 143) {
    $code_lengths[$i] = 8;
}
foreach my $i (144 .. 255) {
    $code_lengths[$i] = 9;
}
foreach my $i (256 .. 279) {
    $code_lengths[$i] = 7;
}
foreach my $i (280 .. 287) {
    $code_lengths[$i] = 8;
}

my ($dict)      = huffman_from_code_lengths(\@code_lengths);
my ($dist_dict) = huffman_from_code_lengths([(5) x 32]);

my ($DISTANCE_SYMBOLS, $LENGTH_SYMBOLS, $LENGTH_INDICES) = make_deflate_tables();

if (eof($in_fh)) {    # empty file
    $bitstring = '1' . '10' . $dict->{256};
}

while (read($in_fh, (my $chunk), CHUNK_SIZE)) {

    my $chunk_len    = length($chunk);
    my $is_last      = eof($in_fh) ? '1' : '0';
    my $block_header = join('', $is_last, $block_type);

    $bitstring .= $block_header;
    my ($literals, $indices, $lengths) = lzss_encode($chunk);

    foreach my $k (0 .. $#$literals) {

        if ($lengths->[$k] == 0) {
            $bitstring .= $dict->{$literals->[$k]};
            next;
        }

        my $len  = $lengths->[$k];
        my $dist = $indices->[$k];

        {
            my $len_idx = $LENGTH_INDICES->[$len];
            my ($min, $bits) = @{$LENGTH_SYMBOLS->[$len_idx]};

            $bitstring .= $dict->{$len_idx + 256 - 1};
            $bitstring .= int2bits_lsb($len - $min, $bits) if ($bits > 0);
        }

        {
            my $dist_idx = find_deflate_index($dist, $DISTANCE_SYMBOLS);
            my ($min, $bits) = @{$DISTANCE_SYMBOLS->[$dist_idx]};

            $bitstring .= $dist_dict->{$dist_idx - 1};
            $bitstring .= int2bits_lsb($dist - $min, $bits) if ($bits > 0);
        }
    }

    $bitstring .= $dict->{256};    # end-of-block symbol

    my $bits_len = length($bitstring);
    print $out_fh pack('b*', substr($bitstring, 0, $bits_len - ($bits_len % 8), ''));

    $crc32 = crc32($chunk, $crc32);
    $total_length += $chunk_len;
}

if ($bitstring ne '') {
    print $out_fh pack('b*', $bitstring);
}

print $out_fh pack('b*', int2bits_lsb($crc32,        32));
print $out_fh pack('b*', int2bits_lsb($total_length, 32));

close $in_fh;
close $out_fh;
