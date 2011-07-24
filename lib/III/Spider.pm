package III::Spider;

use Moose;
with 'III::Store';

use III::Agent;
has 'agent' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { III::Agent->new }
);

1;
