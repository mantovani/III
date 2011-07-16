package III::Store;

use Moose::Role;
use MongoDB;
use III::Glue;
use utf8;

with 'III::Store::MetaText';

has 'db' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub {
        MongoDB::Connection->new( host => '127.0.0.1', port => 27017 );
    },
    lazy => 1
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

	
=head2 store

Save the information in the database. Just if was not stored before.

=cut

sub store {
    my ( $self, $infs ) = @_;

    # if the news don't exists save
    if ( $self->iiiglue->check( $infs->{source_link} ) ) {
        my $meta_infs = $self->add_fields($infs);
        $self->index_category( $meta_infs->{category} );
        $self->db->iii->news->insert($meta_infs);
    }
}

sub index_category {
    my ( $self, $category ) = @_;
    my $check = $self->db->iii->category->find_one( { category => $category } );
    unless ($check) {
        $self->db->iii->category->insert( { category => $category } );
    }
}

return 1;
