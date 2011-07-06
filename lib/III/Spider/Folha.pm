package III::Spider::Folha;

use III::Spider;
use Moose::Role;
use HTML::TreeBuilder::XPath;
use Data::Dumper;

has 'link' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://www1.folha.uol.com.br/ciencia/'
);

has 'spider' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { III::Spider->new }
);

has 'source' => ( is => 'ro', isa => 'Str', default => 'Folha' );

sub init {
    my $self = shift;
    $self->all_news;
}

sub all_news {
    my $self    = shift;
    my $content = $self->spider->agent->get( $self->link );
    $self->itens($content);
}

sub itens {
    my ( $self, $html ) = @_;
    my $tree  = HTML::TreeBuilder::XPath->new_from_content($html);
    my @itens = $tree->findnodes('//div[@id="newslist"]//a');
    foreach my $item (@itens) {
        my $content = $self->spider->agent->get( $item->attr('href') );
        $self->parser_news(
            $content,
            {
                title       => $item->as_text,
                source_link => $item->attr('href'),
            }
        );
    }
    $tree->delete;
}

sub parser_news {
    my ( $self, $news, $infs ) = @_;
    my $tree = HTML::TreeBuilder::XPath->new_from_content($news);

    $infs->{author}   = $tree->findvalue('//div[@id="articleBy"]');
    $infs->{category} = 'Ciência';
    $infs->{source}   = $self->source;
    $infs->{text}     = $tree->findvalue('//div[@id="articleNew"]/p');

    return if length( $infs->{text} ) < 20;

    if ( $tree->exists('//p[@class="wideVideoPlayer"]') ) {
        my $video = $tree->findnodes('//p[@class="wideVideoPlayer"]')->[0];
        $infs->{text} .= $video->as_HTML;
    }

    my $keywords = $tree->findnodes('//meta[@name="keywords"]')->[0];
    if ($keywords) {
        $infs->{keywords} = [ split /,/, $keywords->attr('content') ];
    }
    $self->spider->store($infs);
    $tree->delete;
}

42;
