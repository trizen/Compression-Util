#!perl -T

use 5.036;
use Test::More;
use Compression::Util qw(:all);

plan tests => 3;

foreach my $file (__FILE__) {

    my $data = do { open my $fh, '<:raw', $file; local $/; <$fh> };

    my ($u1, $i1, $l1) = lzss_encode($data);
    my ($u2, $i2, $l2) = lz77_encode($data);
    my ($u3, $i3, $l3) = lzssf_encode($data);

    my $str1 = lz77_decode($u1, $i1, $l1);
    my $str2 = lz77_decode($u2, $i2, $l2);
    my $str3 = lz77_decode($u3, $i3, $l3);

    is($str1, $data);
    is($str2, $data);
    is($str3, $data);
}
