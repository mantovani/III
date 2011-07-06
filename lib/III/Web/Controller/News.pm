package III::Web::Controller::News;
use Moose;
use namespace::autoclean;
use Text::Iconv;
use MongoDB::OID;
use Encode;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

III::Web::Controller::News - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base : Chained('/base') : PathPart('news') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{last_news} = sub {
        return $c->model('MongoDB')->c('news')->query( {}, { limit => 10 } );
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
            if ( $count % 6 == 0 ) {
                $result .= '<br /><br />';
            }
        }
        return $result;
    };

    $c->stash->{no_accents} = sub {
        return Text::Iconv->new( 'UTF-8', 'ASCII//TRANSLIT' )->convert(shift);
    };

    $c->stash->{url_friendly} = sub {
        my $title = uc( $c->stash->{no_accents}->(shift) );
        $title =~ s/\s/\+/g;
        return $title;
    };

}

sub index : Chained('base') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
}

sub news : Chained('base') : PathPart('new') : Args(1) {
    my ( $self, $c, $id ) = @_;
    $c->stash->{news} =
      $c->model('MongoDB')->c('news')
      ->find_one( { _id => MongoDB::OID->new( value => $id ) } );
}

sub category : Chained('base') : PathPart('category') : Args(1) {
    my ( $self, $c, $category ) = @_;
    $c->stash->{category} = decode( "utf8", $category );

    my ( $limit, $skip ) = ( 15, 0 );

    # - skip untill next page :)
    if ( $c->req->params->{page} ) {
        $skip = $limit * $c->req->params->{page};
    }
    $c->stash->{category_news} = $c->model('MongoDB')->c('news')->query(
        { category => $category },
        {
            limit   => $limit,
            skip    => $skip,
            sort_by => { timestamp => 1 },
        }
    );
}

=head1 AUTHOR

Daniel Mantovani,,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;