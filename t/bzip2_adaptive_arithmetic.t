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

    my $enc = bz2_compress($str, undef, \&create_adaptive_ac_entry);
    my $dec = bz2_decompress($enc, undef, \&decode_adaptive_ac_entry);

    ok(length($enc) < length($str));
    is($str, $dec);
}
