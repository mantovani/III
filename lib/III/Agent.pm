package III::Agent;

use Moose;
use WWW::Mechanize;
use TryCatch;

has 'mechanize' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub {
        WWW::Mechanize->new( agent_alias => 'Linux Mozilla', stack_depth => 5 );
    }
);

sub get {
    my ( $self, $url ) = @_;
    my $try = 3;
    while ( $try > 0 ) {
        try {
            $self->mechanize->get($url);
            $try = -1;
        }
        catch {
            $try--;
            sleep 1;
        };
    }
    return $self->mechanize->content;
}

42;
