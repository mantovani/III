package III::Spider::Role;

use Moose::Role;
use Scalar::Util;
use HTML::StripTags qw(strip_tags);

sub html_clean {
    my ( $self, $html ) = @_;
    strip_tags( $html,
'<H1><H2><H3><H4><H5><H6><I><B><U><BR><TABLE><TD><TR><LI><UL><A><P><IMG><STRONG>'
    );
}

sub erase_tag {
    my ( $self, $element, $path ) = @_;
    if ( $element =~ /HTML::TreeBuilder|HTML::Element/ ) {
        foreach my $godel ( @{ $element->findnodes($path) } ) {
            $godel->replace_with();
        }
    }
    else {
        die
"\$element does not look like a html treebuilder or html element attribute";
    }
}

42;
