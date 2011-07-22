package III::Spider::Globo;

use III::Spider;
use Moose::Role;
use HTML::TreeBuilder::XPath;
use HTML::Strip;
use Data::Dumper;

has 'link' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://g1.globo.com/tecnologia/games/'
);

has 'spider' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { III::Spider->new }
);

has 'source' => ( is => 'ro', isa => 'Str', default => 'Globo' );

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
    my @itens = $tree->findnodes('//a[@class="titulo"]');
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

    $infs->{sub_title} = $tree->findvalue('//div[@class="materia-titulo"]//h2');
    $infs->{category}  = 'Games';
    $infs->{source}    = $self->source;

    my $hs = HTML::Strip->new(
        striptags   => ['strong'],
        emit_spaces => 0
    );

    $infs->{text} =
      $hs->parse(
        $tree->findnodes('//div[@id="materia-letra"]')->[0]->as_HTML );
    $hs->eof;

    return unless $infs->{text};

    my $keywords = $tree->findnodes('//meta[@name="keywords"]')->[0];
    if ($keywords) {
        $infs->{keywords} = [ split /,/, $keywords->attr('content') ];
    }
    $self->spider->store($infs);
    $tree->delete;
}

42;
