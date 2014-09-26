use 5.008;    # open scalar
use strict;
use warnings;

package Comment::Spell;

our $VERSION = '0.001000';

# ABSTRACT: Spell Checking for your comments

# AUTHORITY

use Carp qw( croak );
use Moo qw( has );
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
  my ($self) = @_;
  return Pod::Wordlist->new( _is_debug => $self->_is_debug, );
}

sub _build_output_filehandle {
  return \*STDOUT;
}

sub set_output_file {
  my ( $self, $filename ) = @_;
  $self->set_output_filehandle( path($filename)->openw_raw );
  return;
}

sub set_output_string {    ## no critic (Subroutines::RequireArgUnpacking)
  open my $fh, '>', \$_[1] or croak 'Cant construct a scalar filehandle';    ## no critic ( InputOutput::RequireBriefOpen )
  $_[0]->set_output_filehandle($fh);
  return;
}

sub _ppi_fh {
  my ( undef, $fh ) = @_;
  my $content = do {
    local $/ = undef;
    scalar <$fh>;
  };
  return PPI::Document->new( \$content, readonly => 1 );
}

sub _ppi_file {
  my ( undef, $file ) = @_;
  return PPI::Document->new( $file, readonly => 1 );
}

sub _ppi_string {    ## no critic (Subroutines::RequireArgUnpacking)
  return PPI::Document->new( \$_[1], readonly => 1 );
}

sub _skip_comment {
  my ( undef, $comment ) = @_;
  if ( $comment->content =~ /\A[#]{2}/msx ) {
    return 1;
  }
  return;
}

sub _comment_text {
  my ( undef, $comment ) = @_;
  my $content = $comment->content;
  $content =~ s/\A[#]//msx;
  $content =~ s/\r?\n\z//msx;
  return $content;
}

sub _print_words {
  my ( $self, $text ) = @_;
  my $out = $self->stopwords->strip_stopwords($text);
  if ( length $out ) {
    local $Text::Wrap::huge = 'overflow';    ## no critic (Variables::ProhibitPackageVars)
    $self->_print_output( wrap( q[], q[], $out ) . "\n\n" );
  }
  return;
}

sub parse_from_document {
  my ( $self, $document ) = @_;
  my (@comments) = @{ $document->find('PPI::Token::Comment') || [] };
  for my $comment (@comments) {
    next if $self->_skip_comment($comment);
    $self->_print_words( $self->_comment_text($comment) );
  }
  $self->_flush_output;
  return;
}

sub parse_from_filehandle {
  my ( $self, $infh ) = @_;
  return $self->parse_from_document( $self->_ppi_fh($infh) );
}

sub parse_from_file {
  my ( $self, $infile ) = @_;
  return $self->parse_from_document( $self->_ppi_file($infile) );
}

sub parse_from_string {    ## no critic (Subroutines::RequireArgUnpacking)
  return $_[0]->parse_from_document( $_[0]->_ppi_string( $_[1] ) );
}

no Moo;

1;

=head1 SYNOPSIS

C<Comment::Spell> is a work-a-like for Perl Comments similar to C<Pod::Spell>.

It offers no I<in-built> spell checking services, merely streamlines extracting tokens
to pass to a spell checker of your choice, while removing some basic useful items (stop-words).

It also, by default, ignores comments with two or more leading hashes so to avoid directive comments
like those found in C<Perl::Critic>

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

=method C<new>

  ->new(
    stopwords         => A Pod::Wordlist instance
    output_filehandle => A IO Handle ( default is STDOUT )
  )

=method C<output_filehandle>

The file handle to write to.

See L</set_output_filehandle>, L</set_output_string> and L</set_output_file>

=method C<set_output_filehandle>

  ->set_output_filehandle( $fh );
  ->set_output_filehandle( \*STDOUT );

=method C<set_output_string>

  my $str;
  ->set_output_string( $str ); # will write to $str

=method C<set_output_file>

  ->set_output_file('./out.txt');

=method C<parse_from_file>

  ->parse_from_file('./in.pm'); # Read in.pm and stream tokens to current FH

=method C<parse_from_filehandle>

  ->parse_from_filehandle( $fh ); # Slurps FH and streams its tokens to current FH

=method C<parse_from_string>

  ->parse_from_string( $string ); # decode $string as a PPI document and stream its comments tokens to FH

=method C<parse_from_document>

Lower level interface if you want to make C<PPI> Objects yourself.

  ->parse_from_document( $ppi_document );

