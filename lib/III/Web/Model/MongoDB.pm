package III::Web::Model::MongoDB;

use Moose;
use DateTime;
use Encode;
use utf8;
BEGIN { extends 'Catalyst::Model::MongoDB' }

use Cache::Memcached::Fast;

has 'cache' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub {
        new Cache::Memcached::Fast(
            {
                servers         => [ { address => 'localhost:11211', }, ],
                namespace       => 'iii:',
                connect_timeout => 0.2,
                io_timeout      => 0.5,
                close_on_error  => 1,
                compress_threshold => 100_000,
                compress_ratio     => 0.9,
                compress_methods   => [
                    \&IO::Compress::Gzip::gzip,
                    \&IO::Uncompress::Gunzip::gunzip
                ],
                max_failures      => 3,
                failure_timeout   => 2,
                ketama_points     => 150,
                nowait            => 1,
                hash_namespace    => 1,
                serialize_methods => [ \&Storable::freeze, \&Storable::thaw ],
                utf8              => ( $^V ge v5.8.1 ? 1 : 0 ),
                max_size          => 512 * 1024,
            }
        );
    }
);

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
    my $cache_key = "last_by_category:$category";
    if ( my $buff = $self->cache->get($cache_key) ) {
        return $buff;
    }
    else {
        my $result = [
            $self->c('news')->query( { category => $category },
                { limit => 10, sort_by => { timestamp => -1 } } )->all
        ];
        $self->cache->set( $cache_key, $result, 1800 );
        return $result;
    }
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
    return $self->_encode_entris( $c, $itens, $find );
}

sub _encode_entris {
    my ( $self, $c, $itens, $find ) = @_;
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
                { 'meta_text.title' => qr/$busca/ },
                { 'meta_text.text'  => qr/$busca/ },
            ]
        }
    );
    return ( $find->limit($limit)->skip($skip)->sort( { timestamp => -1 } ),
        $find );
}

sub feed_search {
    my ( $self, $busca, $c ) = @_;
    my ( $skip, $limit ) = ( 0, 20 );

    my ( $itens, $find ) = $self->by_search( $busca, $limit, $skip );
    return $self->_encode_entris( $c, $itens, $find );
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
