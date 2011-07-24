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

        # check identical title news
		# As vezes os sites de noticias postam a noticia com o titulo identico em seguida
		# so que com a url diferente, ai se acontece isso o Store busca esse titulo e da
		# um update com "conteudo" mais novo.
        if ( $self->iiiglue->check( 'title:' . $infs->{meta_text}->{title} ) ) {
            $self->db->iii->news->insert($meta_infs);
        }
        else {
            my $meta_title = $infs->{meta_text}->{title};
            $self->db->iii->news->update(
                { 'meta_text.title' => qr/$meta_title/ },
                { '$set'            => $infs },
            );
        }
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
