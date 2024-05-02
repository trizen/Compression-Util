#!perl -T

use 5.036;
use Test::More;
use Compression::Util qw(:all);

plan tests => 2;

foreach my $file (__FILE__) {

    my $str = do {
        local $/;
        open my $fh, '<:raw', $file;
        <$fh>;
    };

    my $enc = lzhd_compress_symbolic(string2symbols($str), undef, \&create_ac_entry, \&lzssf_encode);
    my $dec = lzhd_decompress_symbolic($enc, \&decode_ac_entry);

    ok(length($enc) < length($str));
    is($str, symbols2string($dec));
}
