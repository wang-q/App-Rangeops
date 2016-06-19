use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Rangeops;

my $result = test_app( 'App::Rangeops' => [qw(help clean)] );
like( $result->stdout, qr{clean}, 'descriptions' );

$result = test_app( 'App::Rangeops' => [qw(clean t/II.sort.tsv -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 12, 'line count' );
like( $result->stdout, qr{892-4684}, 'runlist exists' );

$result = test_app( 'App::Rangeops' => [qw(clean t/II.sort.tsv -r t/II.merge.tsv -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 8, 'line count' );
unlike( $result->stdout, qr{892-4684}, 'runlist merged' );

done_testing();
