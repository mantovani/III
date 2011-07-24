package III::Spider::Role;

use Moose::Role;
use Scalar::Util;

sub erase_tag {
    my ( $self, $element, $path ) = @_;
    if ( $element =~ /HTML::TreeBuilder|HTML::Element/ ) {
        foreach my $godel ( @{ $element->findnodes($path) } ) {
            $godel->delete_content;
        }
    }
    else {
        die
"\$element does not look like a html treebuilder or html element attribute";
    }
}

42;
