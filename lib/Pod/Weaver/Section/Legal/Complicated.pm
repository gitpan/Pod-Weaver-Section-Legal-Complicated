package Pod::Weaver::Section::Legal::Complicated;
BEGIN {
  $Pod::Weaver::Section::Legal::Complicated::AUTHORITY = 'cpan:CDRAUG';
}
{
  $Pod::Weaver::Section::Legal::Complicated::VERSION = '1.00';
}
## Copyright (C) 2013 Carnë Draug <carandraug+dev@gmail.com>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, see <http://www.gnu.org/licenses/>.

# ABSTRACT: add a pod section with multiple authors, copyright owners and licenses in a file basis
# AUTHOR:   Carnë Draug <cdraug@cpan.org>
# OWNER:    Carnë Draug
# LICENSE:  GPL_3

use strict;
use warnings;
use Moose;
use Moose::Autobox;
use MooseX::Types::Moose qw(Bool Int);
use List::MoreUtils qw(uniq);
with (
  'Pod::Weaver::Role::Section',
);
use namespace::autoclean;



has add_dist_license => (
  is      => 'ro',
  isa     => Bool,
  lazy    => 1,
  default => 0,
);


has head => (
  is      => 'ro',
  isa     => Int,
  lazy    => 1,
  default => 1,
);


sub _extract_comments {
  my (undef, $input, $tag) = @_;
  my $ppi_document = $input->{ppi_document};

  my @comments;
  $ppi_document->find( sub {
    my $ppi_node = $_[1];
    if ($ppi_node->isa('PPI::Token::Comment') &&
        $ppi_node->content =~ qr/^\s*#+\s*$tag:\s*(.+)$/m ) {
      push (@comments, $1);
    }
    return 0;
  });
  return @comments;
}


sub weave_section {
  my ($self, $document, $input) = @_;
  my $filename  = $input->{filename};

  my @authors   = $self->_extract_comments($input, "AUTHOR");
  my @owners    = $self->_extract_comments($input, "OWNER");
  my @licenses  = $self->_extract_comments($input, "LICENSE");

  @licenses  = map {
    my $license = "Software::License::$_";
    eval { $license = $license->new({holder => \@owners}) };
    Carp::croak "Possibly $_ license module not installed: $@" if $@;
    $license;
  } @licenses;

  if ($self->add_dist_license && $input->{license}) {
    push (@licenses, $input->{license});
  }

  Carp::croak "Unable to find an author for $filename" unless scalar (@authors);
  Carp::croak "Unable to find a copyright owner for $filename" unless scalar (@owners);
  Carp::croak "Unable to find a copyright license for $filename" unless scalar (@licenses);

  my $author_text  = join ("\n\n", @authors);

  ## One day, we might need a more complex legal text but in the mean
  ## time, this is fine to avoid repeated entries
  @licenses = uniq (map { $_->name } @licenses);

  my $license_text = "This software is Copyright (c) by ".
                      join (", and ", @owners) .
                     " and released under the license of " .
                      join (", and ", @licenses);

  my $text = Pod::Elemental::Element::Nested->new({
    command  => "head" . $self->head,
    content  => "LEGAL",
    children => [
      Pod::Elemental::Element::Nested->new({
        command  => "head" . ($self->head +1),
        content  => "Authors",
        children => [Pod::Elemental::Element::Pod5::Ordinary->new({ content => $author_text })],
      }),
      Pod::Elemental::Element::Nested->new({
        command  => "head" . ($self->head +1),
        content  => "Copyright and License",
        children => [Pod::Elemental::Element::Pod5::Ordinary->new({ content => $license_text })],
      }),
    ],
  });
  $document->children->push($text);
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Pod::Weaver::Section::Legal::Complicated - add a pod section with multiple authors, copyright owners and licenses in a file basis

=head1 VERSION

version 1.00

=head1 SYNOPSIS

In your F<weaver.ini>

  [Legal::Complicated]

=head1 DESCRIPTION

This plugin is aimed at distributions that have several files, each of them with
possibly different authors, copyright owners and licenses.

It will look for these values in comments of the source code (analyzed
through a C<ppi_document>) with the following form:

  # AUTHOR:  John Doe <john.doe@otherside.com>
  # AUTHOR:  Mary Jane <mary.jane@thisside.com>
  # OWNER:   University of Over Here
  # OWNER:   Mary Jane
  # LICENSE: GPL_3

This example would generate the following POD:

  =head1 Legal

  =head2 Authors

  John Doe <john.doe@otherside.com>
  Mary Jane <mary.jane@thisside.com>

  =head2 Copyright and License

  This software is copyright of University of Over Here, and Mary Jane, and
  released under the license of The GNU General Public License, Version 3,
  June 2007

Note that this plugin makes a distinction between the authors (whoever wrote the
code), and the actual copyright owners (possibly the person who paid them to
write it).

I am not a lawyer myself, any feedback on better ways to deal with this kind of
situations is most welcome.

=head1 ATTRIBUTES

=head2 add_dist_license

If true, it will also add the distribution license to each of the files.
Defaults to false.

=head2 head

Sets the heading level for the legal section. Defaults to 1.

=for Pod::Coverage _extract_comments

=for Pod::Coverage weave_section

=head1 AUTHOR

Carnë Draug <cdraug@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Carnë Draug.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

