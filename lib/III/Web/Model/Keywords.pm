package III::Web::Model::Keywords;
use Moose;
use namespace::autoclean;
use Lingua::PT::UnConjugate;

extends 'Catalyst::Model';

has 'preposicoes' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        [
            qw/a antes até após com contra de desde em entre para per perante por sem sob sobre trás/
        ];
    }
);

sub keywords {
    my ( $self, $words ) = @_;
    my $keywords;

    $words =~ s/[\,\.]/ /g;
	$words =~ s/["']|//g;
    my @all_words = split /\s/, $words;
  ADD: foreach my $word (@all_words) {
        $word = lc($word);
        my $verb_forms = unconj($word);

        foreach my $prepo ( @{ $self->preposicoes } ) {
            next ADD if $prepo =~ $word;
        }

        $keywords .= " $word" if scalar keys %{$verb_forms} == 0;
    }
    return $keywords;
}

=head1 NAME

III::Web::Model::Keywords - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Daniel Mantovani,,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
