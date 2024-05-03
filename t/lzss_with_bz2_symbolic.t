#!perl -T

use 5.036;
use Test::More;
use Compression::Util qw(:all);

plan tests =>4;

foreach my $file (__FILE__, __FILE__) {

    my $str = do {
        local $/;
        open my $fh, '<:raw', $file;
        <$fh>;
    };

    my $enc = lzss_compress($str, \&bz2_compress_symbolic);
    my $dec = lzss_decompress($enc, \&bz2_decompress_symbolic);

    ok(length($enc) < length($str));
    is($str, $dec);

     $Compression::Util::LZ_THRESHOLD = 0;    # always use LZSS + hash table
}
