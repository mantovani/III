package III::Spider::Oriongames;

use III::Spider;
use Moose::Role;
use HTML::TreeBuilder::XPath;
use Data::Dumper;

with 'III::Spider::Role';

has 'link' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://www.oriongames.com.br/noticias/'
);

has 'spider' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { III::Spider->new }
);

has 'source'   => ( is => 'ro', isa => 'Str', default => 'Oriongames' );
has 'category' => ( is => 'ro', isa => 'Str', default => 'Games' );

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
    my @itens = $tree->findnodes('//dl[@id="listaNoticias"]/dt//a');
    foreach my $item (@itens) {
        my $content = $self->spider->agent->get( $item->attr('href') );
        $self->parser_news(
            $content,
            {
                title       => $item->as_text,
                source_link => 'http://www.oriongames.com.br'
                  . $item->attr('href'),
            }
        );
    }
    $tree->delete;
}

sub parser_news {
    my ( $self, $news, $infs ) = @_;

    $news =~ s|src="(.+?)"|src="http://www.oriongames.com.br/$1"|g;
    $news =~ s/Fonte:\s.+//;

    my $tree = HTML::TreeBuilder::XPath->new_from_content($news);

    $infs->{author}    = $tree->findvalue('//h5/a[@class="highslide"]');
    $infs->{category}  = $self->category;
    $infs->{source}    = $self->source;
    $infs->{sub_title} = $tree->findvalue('//h2');
    my $text = $tree->findnodes('//div[@id="conteudoTexto"]')->[0];

    $infs->{text}    = $text->as_text;
    $infs->{content} = $self->html_clean( $text->as_HTML );

    my $keywords = $tree->findnodes('//meta[@name="keywords"]')->[0];
    if ($keywords) {
        $infs->{keywords} = [ split /,/, $keywords->attr('content') ];
    }

    $self->spider->store($infs);
    $tree->delete;
}

42;
