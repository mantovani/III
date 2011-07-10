package III::Social;

use Moose;
with 'MooseX::Traits';

sub search {
    my ( $self, $social, $search ) = @_;
    my $execute =
      III::Social->with_traits( 'III::Social::' . $social )->new;
    return $execute->search( $search );
}

42;
