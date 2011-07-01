package III::Glue;

use Moose;
use Redis;
use Digest::MD5 qw/md5_hex/;

has 'redis' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { Redis->new() },
    lazy    => 1
);

=head1 SYNOPSIS

III::Glue is the responsable to guarantuse the news is not get 2x


	my $glue = III::Glue->new;
	if ( $glue->check($news_url) ) {
		
			...

	} else {

		# news does not exists
	}

=cut

=head2 _write

Save the key in the Redis DB

=cut

sub _write_key {
    my ( $self, $key ) = @_;
    $self->redis->set( $key => 1 );
    return 1;
}

=head2 check

Return 1 if the url exists else returns empy;

=cut

sub check {
    my ( $self, $url ) = @_;
    my $key = $self->_url_encode($url);
    if ( $self->redis->get($key) ) {
        return;
    }
    else {
        $self->_write_key($key);
        return 1;
    }
}

=head2 _url_encode

Encode the url to md5_hex, returns the "$key";

=cut

sub _url_encode {
    my ( $self, $url ) = @_;
    return md5_hex $url;
}

42;
