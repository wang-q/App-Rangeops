use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Rangeops;

my $result = test_app( 'App::Rangeops' => [qw(help sort)] );
like( $result->stdout, qr{sort}, 'descriptions' );

$result = test_app( 'App::Rangeops' => [qw(sort t/I.links.tsv -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 19, 'line count' );
unlike( $result->stdout, qr{^[VX]\w+\(}m, 'chromosome I first' );

done_testing();
