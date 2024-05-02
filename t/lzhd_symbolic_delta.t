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

    my $enc = lzhd_compress_symbolic($str, undef, \&delta_encode);
    my $dec = lzhd_decompress_symbolic($enc, \&delta_decode);

    ok(length($enc) < length($str));
    is($str, symbols2string($dec));
}
