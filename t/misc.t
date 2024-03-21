#!perl -T

use 5.036;
use Test::More;
use Compression::Util qw(:all);
use List::Util        qw(shuffle);

plan tests => 17;

##################################

{
    my @arr  = shuffle((map { int(rand(100)) } 1 .. 20), (map { int(rand(1e6)) } 1 .. 10), 0, 5, 9, 999_999, 1_000_000, 1_000_001, 42, 1);
    my @copy = @arr;

    is_deeply(abc_decode(abc_encode(\@arr)),                      \@arr);
    is_deeply(ac_decode(ac_encode(\@arr)),                        \@arr);
    is_deeply(elias_gamma_decode(elias_gamma_encode(\@arr)),      \@arr);
    is_deeply(elias_omega_decode(elias_omega_encode(\@arr)),      \@arr);
    is_deeply(fibonacci_decode(fibonacci_encode(\@arr)),          \@arr);
    is_deeply(delta_decode(delta_encode(\@arr)),                  \@arr);
    is_deeply(delta_decode(delta_encode(\@arr, 1), 1),            \@arr);
    is_deeply(rle4_decode(rle4_decode(\@arr)),                    \@arr);
    is_deeply([map { ($_->[0]) x $_->[1] } @{run_length(\@arr)}], \@arr);

    is_deeply(\@arr, \@copy);    # make sure the array has not been modified in-place
}

##################################

{
    my @symbols = unpack('C*', join('', 'a' x 13, 'b' x 14, 'c' x 10, 'd' x 3, 'e' x 1, 'f' x 1, 'g' x 4));

    my $rl  = run_length(\@symbols);
    my $rl2 = run_length(\@symbols, 10);

    is(scalar(@$rl),  7);
    is(scalar(@$rl2), 9);

    is_deeply([map { ($_->[0]) x $_->[1] } @$rl],  \@symbols);
    is_deeply([map { ($_->[0]) x $_->[1] } @$rl2], \@symbols);

    is_deeply(rle4_decode(rle4_encode(\@symbols)), \@symbols);
}

##################################

{
    my $bitstring = "101000010000000010000000100000000001001100010000000000000010010100000000000000001";

    my $encoded = binary_vrl_encode($bitstring);
    my $decoded = binary_vrl_decode($encoded);

    is($decoded, $bitstring);
    is($encoded, "1000110101110110111010011110001010101100011110101010000111101110");
}
