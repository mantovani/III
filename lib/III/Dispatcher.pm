package III::Dispatcher;

use Moose;
with 'MooseX::Traits';

sub init {
    my ( $self, $spider ) = @_;
    my $execute = III::Dispatcher->with_traits( 'III::Spider::' . $spider )->new;
    $execute->init;
}

42;
