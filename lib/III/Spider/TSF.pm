package III::Spider::TSF;

use III::Spider;
use Moose::Role;
use HTML::TreeBuilder::XPath;
use Data::Dumper;

has 'link' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://www.tsf.pt/PaginaInicial/Economia/'
);

has 'spider' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { III::Spider->new }
);

has 'source' => ( is => 'ro', isa => 'Str', default => 'TSF' );

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
    my @itens = $tree->findnodes('//div[@class="Destaque"]//h1/a');
    foreach my $item (@itens) {
        if ( $item->attr('href') ) {
            my $content = $self->spider->agent->get( $item->attr('href') );
            $self->parser_news(
                $content,
                {
                    title       => $item->as_text,
                    source_link => 'http://www.tsf.pt' . $item->attr('href'),
                }
            );
        }
    }
    $tree->delete;
}

sub parser_news {
    my ( $self, $news, $infs ) = @_;
    my $tree = HTML::TreeBuilder::XPath->new_from_content($news);

    $infs->{category} = 'Economia';
    $infs->{source}   = $self->source;

    if ( $tree->exists('//div[@id="NewsSummary"]') ) {
        $infs->{sub_title} = $tree->findvalue('//div[@id="NewsSummary"]');
    }

    if ( $tree->findvalue('//div[@id="Article"]') =~ /\w{10,}/ ) {
        $infs->{text} = $tree->findvalue('//div[@id="Article"]');
    }
    else {
        $infs->{text} = $tree->findvalue('//span[@id="SummaryContent"]');
    }
    my $keywords = $tree->findnodes('//meta[@name="keywords"]')->[0];
    if ($keywords) {
        $infs->{keywords} = [ split /,/, $keywords->attr('content') ];
    }
    $self->spider->store($infs);
    $tree->delete;
}

42;
