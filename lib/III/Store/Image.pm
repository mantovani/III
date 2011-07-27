package III::Store::Image;

use Moose;
use DateTime;
use III::Agent;
use File::Type;
use UUID::Random;
use HTML::TreeBuilder::XPath;
use File::Path qw(make_path);

has 'ft' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { File::Type->new() }
);

has 'agent' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { III::Agent->new }
);

has 'dir_prefix' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        return 'root/static/images/news/';
    },
    lazy => 1,
);

has 'dt' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { DateTime->now }
);

sub file {
    my ( $self, $type ) = @_;
    my $id  = UUID::Random::generate;
    my $dir = $self->dir_prefix . $self->dt->ymd('/');
    make_path($dir) if !-e $dir;
    return $dir . "/$id.$type";
}

sub save_images {
    my ( $self, $html ) = @_;
    my $tree = HTML::TreeBuilder::XPath->new_from_content($html);
    foreach my $img ( $tree->findnodes('//img') ) {
        my $image     = $self->agent->get( $img->attr('src') );
        my $file_type = $1
          if $self->ft->checktype_contents($image) =~ m/\/\-?(.+)/;

        my $file = $self->file($file_type);

        open my $fh, '>', $file or die $!;
        print $fh $image;
        close $fh;

        my $url = $1 if $file =~ /root(.+)/;
        $img->attr( 'src', $url );
    }
    $html = $tree->as_HTML;
    $tree->delete;
    return $html;
}

42;
