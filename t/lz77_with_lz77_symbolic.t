#!perl -T

use 5.036;
use Test::More;
use Compression::Util qw(:all);

plan tests => 1;

foreach my $file (__FILE__) {

    my $str = do {
        local $/;
        open my $fh, '<:raw', $file;
        <$fh>;
    };

    my $enc = lz77_compress($str, \&lz77_compress_symbolic);
    my $dec = lz77_decompress($enc, \&lz77_decompress_symbolic);

    is($str, $dec);
}
