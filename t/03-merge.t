use Test::More;
use App::Cmd::Tester;

use App::Rangeops;

my $result = test_app( 'App::Rangeops' => [qw(help merge)] );
like( $result->stdout, qr{merge}, 'descriptions' );

$result = test_app( 'App::Rangeops' => [qw(merge t/I.yml t/II.yml -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 5, 'line count' );
like( $result->stdout, qr{28547\-29194}, 'runlist exists' );

like( $result->stdout, qr{I:.+II:}s, 'chromosomes exist' );

done_testing(4);
