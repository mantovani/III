package III::Store::MetaText;

use Moose::Role;
use Text::Unaccent;
use utf8;

has 'infs_attrs' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        [qw/category title source text sub_title author/];
    }
);

sub add_fields {
    my ( $self, $infs ) = @_;
    $infs = $self->_add_time($infs);
    $infs = $self->_add_meta_text($infs);
    $infs = $self->_check_author($infs);
    return $infs;
}

sub _add_time {
    my ( $self, $infs ) = @_;
    $infs->{timestamp} = time;
    return $infs;
}

sub _add_meta_text {
    my ( $self, $infs ) = @_;
    foreach my $attr ( @{ $self->infs_attrs } ) {
        if ( $infs->{$attr} ) {
            $infs->{meta_text}->{$attr} =
              lc( $self->_no_accent( $infs->{$attr} ) );
        }
    }
    return $infs;
}

sub _check_author {
    my ( $self, $infs ) = @_;
    if ( !$infs->{author} ) {
        $infs->{author} = 0;
    }
    return $infs;
}

sub _no_accent {
    my ( $self, $text ) = @_;
    $text =~ s/[^\w\s]//g;
    return unac_string( 'utf8', $text );
}
42;
