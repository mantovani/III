package III::Web::Model::MongoDB;

use Moose;
use DateTime;
use Encode;
use utf8;
BEGIN { extends 'Catalyst::Model::MongoDB' }

__PACKAGE__->config(
    host           => 'localhost',
    port           => '27017',
    dbname         => 'iii',
    collectionname => '',
    gridfs         => '',
);

sub all_categorys {
    shift->c('category')->query( {}, { sort_by => { category => 1 } } );
}

sub last_by_category {
    my ( $self, $category ) = @_;
    $self->c('news')->query( { category => $category },
        { limit => 10, sort_by => { timestamp => -1 } } );
}

sub by_category {
    my ( $self, $limit, $skip, $category ) = @_;
    my $find = $self->c('news')->find( { category => $category } );
    return ( $find->limit($limit)->skip($skip)->sort( { timestamp => -1 } ),
        $find );

}

sub feed_category {
    my ( $self, $category, $c ) = @_;
    my ( $skip, $limit ) = ( 0, 20 );

    my ( $itens, $find ) = $self->by_category( $limit, $skip, $category );

    my @entries;

    foreach my $item ( $itens->all ) {
        my $url = $self->_url_news( $c, $item );
        my $entrie = {
            id       => $url,
            link     => $url,
            title    => encode( 'latin1', $item->{title} ),
            modified => DateTime->from_epoch( epoch => $item->{timestamp} ),
            content =>
              encode( 'latin1', $c->stash->{few_words}->( $item->{text} ) ),
        };
        push @entries, $entrie;
    }
    return \@entries;
}

sub _url_news {
    my ( $self, $c, $item ) = @_;
    my $date = $c->stash->{date}->( $item->{timestamp} );
    my $url  = $c->uri_for(
        $c->controller('News')->action_for('news'),
        $c->stash->{no_accents}->( $item->{category} ),
        $date->year,
        $c->stash->{url_friendly}->( $item->{title} ) . '-'
          . $c->stash->{id}->($item)
    );
    return $url;
}

sub by_search {
    my ( $self, $busca, $limit, $skip ) = @_;
    my $find = $self->c('news')->find(
        {
            '$or' => [
                { 'meta_text.title'   => qr/\s$busca\s|^$busca\s|\s$busca$/i },
                { 'meta_text.text' => qr/\s$busca\s|^$busca\s|\s$busca$/i },
            ]
        }
    );
    return ( $find->limit($limit)->skip($skip)->sort( { timestamp => -1 } ),
        $find );
}

=head1 NAME

III::Web::Model::MongoDB - MongoDB Catalyst model component

=head1 SYNOPSIS

See L<III::Web>.

=head1 DESCRIPTION

MongoDB Catalyst model component.

=head1 AUTHOR

Daniel Mantovani,,,,

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

1;
