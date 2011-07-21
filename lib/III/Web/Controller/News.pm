package III::Web::Controller::News;
use Moose;
use namespace::autoclean;
use Text::Unaccent;
use MongoDB::OID;
use Encode;
use DateTime;
use Data::Page;
use utf8;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

III::Web::Controller::News - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base : Chained('/base') : PathPart('noticias') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{last_news} = sub {
        return $c->model('MongoDB')->c('news')
          ->query( {}, { limit => 40, sort_by => { timestamp => -1 } } );
    };

    # - Text tratament
    $c->stash->{few_words} = sub {
        my $text = shift;
        if ( length $text < 500 ) {
            return ( substr( $text, 0, 150 ) . ' ...' );

        }
        else {
            return ( substr( $text, 0, 300 ) . ' ...' );
        }
    };

    # - Text tratament
    $c->stash->{better_view} = sub {
        my $text = shift;

        my $result;
        my @dots = split /\./, $text;
        my $count = 0;
        foreach my $dot (@dots) {
            $count++;
            $result .= $dot . '.' if $dot =~ /\w/;
            if ( $count % 4 == 0 ) {
                $result .= '<br /><br />';
            }
        }
        return $result;
    };

    $c->stash->{no_accents} = sub {
        my $text = shift;
        $text =~ s/[^\w\s]//g;
        return unac_string( 'utf8', $text );
    };

    $c->stash->{url_friendly} = sub {
        my $title = uc( $c->stash->{no_accents}->(shift) );
        $title =~ s/\s/\+/g;
        return $title;
    };

    $c->stash->{date} = sub {
        my $time = shift;
        my $dt = DateTime->from_epoch( epoch => $time );
        return $dt;
    };

    $c->stash->{news_url} = sub {
        my ( $c, $item ) = @_;
        my $date = $c->stash->{date}->( $item->{timestamp} );
        my $url  = $c->uri_for(
            $c->controller('News')->action_for('news'),
            $c->stash->{no_accents}->( $item->{category} ),
            $date->year,
            $c->stash->{url_friendly}->( $item->{title} ) . '-'
              . $c->stash->{id}->($item)
        );
        return $url;
    };
}

sub index : Chained('base') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
}

sub news : Chained('base') : PathPart('') : Args(3) {
    my ( $self, $c, $category, $ano, $url_amigavel ) = @_;
    if ( $url_amigavel =~ /\-(.+)/ ) {
        my $id = $1;
        my $noticia =
          $c->model('MongoDB')->c('news')
          ->find_one( { _id => MongoDB::OID->new( value => $id ) } );
        if ($noticia) {
            $c->stash->{news}  = $noticia;
            $c->stash->{title} = $c->stash->{news}->{title};
            $c->stash->{my_keywords} =
              $c->model('Keywords')->keywords( $c->stash->{news}->{title} );
        }
        else {
            $c->stash->{error} = 'Not&iacute;cia n&atilde;o encontrada :(';
            $c->response->status(404);
        }
    }
    else {
        $c->stash->{error} = 'Not&iacute;cia n&atilde;o encontrada :(';
        $c->response->status(404);
    }
}

sub category : Chained('base') : PathPart('') : Args(1) {
    my ( $self, $c, $category ) = @_;
    $c->stash->{title}    = decode( "utf8", $category );
    $c->stash->{category} = decode( "utf8", $category );

    my ( $limit, $skip ) = ( 20, 0 );

    # - skip untill next page :)
    if ( $c->req->params->{page} ) {
        $skip = $limit * ( $c->req->params->{page} - 1 );
    }

    my ( $result, $find ) =
      $c->model('MongoDB')->by_category( $limit, $skip, $category );
    my $page = Data::Page->new();
    $page->total_entries( $find->count );
    $page->entries_per_page($limit);
    $page->current_page( $c->req->params->{page} // 1 );

    $c->stash->{pager}         = $page;
    $c->stash->{category_news} = $result;
}

sub feed : Chained('base') : PathPart('feed') : Args(1) {
    my ( $self, $c, $category ) = @_;
    $c->stash->{feed} = {
        format      => 'RSS 1.0',
        id          => $c->req->base,
        title       => decode( 'utf8', $category ),
        description => "Últimas notícias sobre: "
          . decode( 'utf8', $category ),
        link => $c->uri_for(
            $c->controller('News')->action_for('category'), $category
        ),
        modified => DateTime->now,
        entries  => $c->model('MongoDB')->feed_category( $category, $c ),
    };
    $c->forward('XML::Feed');
}

sub search : Chained('base') : PathPart('busca') : Args(1) {
    my ( $self, $c, $busca ) = @_;

    $c->stash->{title}    = decode( "utf8", $busca );
    $c->stash->{busca} = decode( "utf8", $busca );

    $busca = $c->stash->{no_accents}->($busca);

    my ( $limit, $skip ) = ( 20, 0 );

    # - skip untill next page :)
    if ( $c->req->params->{page} ) {
        $skip = $limit * ( $c->req->params->{page} - 1 );
    }

    my ( $result, $find ) =
      $c->model('MongoDB')->by_search( $busca, $limit, $skip );
    my $page = Data::Page->new();
    $page->total_entries( $find->count );
    $page->entries_per_page($limit);
    $page->current_page( $c->req->params->{page} // 1 );

    $c->stash->{pager}         = $page;
    $c->stash->{search_news} = $result;
}

=head1 AUTHOR

Daniel Mantovani,,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
