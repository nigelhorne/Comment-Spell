use 5.006;
use strict;
use warnings;

package Comment::Spell;

our $VERSION = '0.001000';

# ABSTRACT: Spell Checking for your comments

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo;
use Pod::Wordlist;
use PPI;
use Path::Tiny qw( path );
use IO::Handle;
use Text::Wrap qw( wrap );

# this comment is for self testing
## this comment is hidden for self testing

has _is_debug => ( init_arg => 'debug', is => ro =>, lazy => 1, builder => '_build__is_debug' );

has stopwords => (
  is      => 'rw',
  lazy    => 1,
  builder => '_build_stopwords',
  handles => {
    '_learn_stopwords' => 'learn_stopwords',
  },
);

has output_filehandle => (
  is      => 'ro' =>,
  writer  => 'set_output_filehandle',
  builder => '_build_output_filehandle',
  handles => {
    '_print_output'  => 'print',
    '_printf_output' => 'printf',
    '_flush_output'  => 'flush',
  },
);

sub _build__is_debug {
  return 1 if $ENV{PERL_COMMENT_SPELL_DEBUG};
  return;
}

sub _build_stopwords {
  return Pod::Wordlist->new( _is_debug => $_[0]->_is_debug, );
}

sub _build_output_filehandle {
  return \*STDOUT;
}

sub set_output_file {
  my ( $self, $filename ) = @_;
  $self->set_output_filehandle( path($filename)->openw_raw );
  return;
}

sub set_output_string {
  open my $fh, '>', \$_[1];
  $_[0]->set_output_filehandle($fh);
}

sub _ppi_fh {
  my ( $self, $fh ) = @_;
  my $content = do {
    local $/ = undef;
    scalar <$fh>;
  };
  return PPI::Document->new( \$content, readonly => 1 );
}

sub _ppi_file {
  my ( $self, $file ) = @_;
  return PPI::Document->new( $file, readonly => 1 );
}

sub _ppi_string {
  return PPI::Document->new( \$_[1], readonly => 1 );
}

sub _skip_comment {
  my ( $self, $comment ) = @_;
  if ( $comment->content =~ /^##/ ) {
    return 1;
  }
  return;
}

sub _comment_text {
  my ( $self, $comment ) = @_;
  my $content = $comment->content;
  $content =~ s/\A[#]//msx;
  $content =~ s/\r?\n\z//msx;
  return $content;
}

sub _print_words {
  my ( $self, $text ) = @_;
  my $out = $self->stopwords->strip_stopwords($text);
  if ( length $out ) {
    local $Text::Wrap::huge = 'overflow';
    $self->_print_output( wrap( '', '', $out ) . "\n\n" );
  }
}

sub parse_from_document {
  my ( $self, $document ) = @_;
  my (@comments) = @{ $document->find('PPI::Token::Comment') || [] };
  for my $comment (@comments) {
    next if $self->_skip_comment($comment);
    $self->_print_words( $self->_comment_text($comment) );
  }
  $self->_flush_output;
}

sub parse_from_filehandle {
  my ( $self, $infh ) = @_;
  return $self->parse_from_document( $self->_ppi_fh($infh) );
}

sub parse_from_file {
  my ( $self, $infile ) = @_;
  return $self->parse_from_document( $self->_ppi_file($infile) );
}

sub parse_from_string {
  return $_[0]->parse_from_document( $_[0]->_ppi_string( $_[1] ) );
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Comment::Spell - Spell Checking for your comments

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

C<Comment::Spell> is a workalike for Perl Comments similar to C<Pod::Spell>.

It offers no I<Inbuilt> spell checking services, merely streamlines extracting tokens
to pass to a spell checker of your choice, while removing some basic useful items (stopwords).

  # Shorthand for CLI
  perl -MComment::Spell -e 'Comment::Spell->new->parse_from_file(q[Foo.pm])' | spell -a

  # Advanced Usage:

  my $speller = Comment::Spell->new();

  $speller->parse_from_file(q[Foo.pm]); # streams words to spell to STDOUT by default

  $speller->parse_from_filehandle( $myfh ); # again to STDOUT

  $speller->set_output_file('out.txt');

  $speller->parse_from_file(q[Foo.pm]); # Now writes to out.txt

  my $str;

  $speller->set_output_string($str);

  $speller->parse_from_file(q[Foo.pm]); # Now writes to $str

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
