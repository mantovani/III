package III::Spider::Role;

use Moose::Role;

use WWW::Mechanize;

has 'mechanize' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub {
        WWW::Mechanize->new( agent_alias => 'Linux Mozilla', stack_depth => 5 );
    }
);

42;
