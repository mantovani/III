package III::Store;

use Moose::Role;
use MongoDB;
use III::Glue;
use utf8;

has 'db' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub {
        MongoDB::Connection->new( host => '127.0.0.1', port => 27017 );
    },
    lazy => 1
);

has 'infs_attrs' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        [qw/category title source source_link author text/];
    }
);

has 'iiiglue' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { III::Glue->new }
);

=head1 SYNOPSIS

III::Store is the class to store the date.

    {
        category    => '',
        title       => '',
        sub_title   => '',
        source      => '',
        source_link => '',
        author      => '',
        keywords    => [],
		text		=> '',
    }

	
=cut

before 'store' => sub {
    my ( $self, $infs_traits ) = @_;
    my $infs = $self->_trait_infs($infs_traits);
    foreach my $check ( @{ $self->infs_attrs } ) {
        die qq{"$check" undefined in store} if !defined $infs->{$check};
    }
};

=head2 store

Save the information in the database. Just if was not stored before.

=cut

sub store {
    my ( $self, $infs ) = @_;

    # if the news don't exists save
    if ( $self->iiiglue->check( $infs->{source_link} ) ) {
        $infs->{timestamp} = localtime;
        print "Salvou\n";
        $self->db->iii->news->insert($infs);
    }
    else {
        print "Já existe\n";
    }
}

sub _trait_infs {
    my ( $self, $infs ) = @_;
    if ( !$infs->{author} ) {
        $infs->{author} = 'Desconhecido';
    }
    return $infs;
}

return 1;
