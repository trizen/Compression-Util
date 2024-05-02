#!perl -T

use 5.036;
use Test::More;
use Compression::Util qw(:all);

plan tests => 4;

foreach my $file (__FILE__, __FILE__) {

    my $str = do {
        local $/;
        open my $fh, '<:raw', $file;
        <$fh>;
    };

    my $enc = lz77_compress($str);
    my $dec = lz77_decompress($enc);

    ok(length($enc) < length($str));
    is($str, $dec);

    $Compression::Util::LZ_THRESHOLD = 0;    # always use LZ77 + hash table
}
