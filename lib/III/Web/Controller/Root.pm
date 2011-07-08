package III::Web::Controller::Root;
use Moose;
use namespace::autoclean;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => '' );

=head1 NAME

III::Web::Controller::Root - Root Controller for III::Web

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub base : Chained('/') : PathPart('') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{menu} = sub {
        return $c->model('MongoDB')->c('category')
          ->query( {}, { sort_by => { category => 1 } } );
    };

    $c->stash->{id} = sub {
        shift->{_id};
    };
    $c->stash->{dump} = sub { Dumper @_ };

}

sub index : Chained('base') : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->res->redirect(
        $c->uri_for( $c->controller('News')->action_for('index') ) );
}

sub robots : Chained('base') : PathPart('robots.txt') : Args(0) {
    my ( $self, $c ) = @_;
    $c->response->content_type('text/plain; charset=utf-8');
    $c->response->body("User-agent: *\nAllow: /");
}

=head2 default

Standard 404 error page

=cut

sub default : Path {
    my ( $self, $c ) = @_;
    $c->response->body('Page not found');
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
}

=head1 AUTHOR

Daniel Mantovani,,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
