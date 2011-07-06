use strict;
use warnings;
use Test::More;


use Catalyst::Test 'III::Web';
use III::Web::Controller::News;

ok( request('/news')->is_success, 'Request should succeed' );
done_testing();
