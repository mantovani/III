package III::Spider::Sol;

use III::Spider;
use Moose::Role;
use HTML::TreeBuilder::XPath;
use Data::Dumper;

has 'link' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://sol.sapo.pt/inicio/Tecnologia/Default.aspx'
);

has 'spider' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { III::Spider->new }
);

has 'source' => ( is => 'ro', isa => 'Str', default => 'Sol' );

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
    my @itens = $tree->findnodes('//div[@class="tit_noticia"]/a');
    foreach my $item (@itens) {
        my $content = $self->spider->agent->get( $item->attr('href') );
        $self->parser_news(
            $content,
            {
                title       => $item->as_text,
                source_link => 'http://sol.sapo.pt' . $item->attr('href'),
            }
        );
    }
    $tree->delete;
}

sub parser_news {
    my ( $self, $news, $infs ) = @_;
    my $tree = HTML::TreeBuilder::XPath->new_from_content($news);

    $infs->{category} = 'Tecnologia';
    $infs->{source}   = $self->source;

    my @get_text = $tree->findnodes('//div[@id="NewsSummary"]')->[0]->content_list;
    foreach my $text (@get_text) {
        if ( !ref $text ) {
            $infs->{text} .= $text;
        }
        else {
            if ( $text->as_HTML !~ /div/ ) {
                $infs->{text} .= $text->as_text;
            }
        }
    }
    my $keywords = $tree->findnodes('//meta[@name="keywords"]')->[0];
    if ($keywords) {
        $infs->{keywords} = [ split /,/, $keywords->attr('content') ];
    }
    $self->spider->store($infs);
    $tree->delete;
}

42;
