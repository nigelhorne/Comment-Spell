# NAME

Comment::Spell  - Spell Checking for your comments

# VERSION

0.001003

# SYNOPSIS

`Comment::Spell` is a work-a-like for Perl Comments similar to `Pod::Spell`.

It offers no _in-built_ spell checking services, merely streamlines extracting tokens
to pass to a spell checker of your choice, while removing some basic useful items (stop-words).

It also, by default, ignores comments with two or more leading hashes so to avoid directive comments
like those found in `Perl::Critic`

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

## `new`

    ->new(
      stopwords         => A Pod::Wordlist instance
      output_filehandle => A IO Handle ( default is STDOUT )
    )

## `output_filehandle`

The file handle to write to.

See ["set\_output\_filehandle"](#set_output_filehandle), ["set\_output\_string"](#set_output_string) and ["set\_output\_file"](#set_output_file)

## `set_output_filehandle`

    ->set_output_filehandle( $fh );
    ->set_output_filehandle( \*STDOUT );

## `set_output_string`

    my $str;
    ->set_output_string( $str ); # will write to $str

## `set_output_file`

    ->set_output_file('./out.txt');

## `parse_from_file`

    ->parse_from_file('./in.pm'); # Read in.pm and stream tokens to current FH

## `parse_from_filehandle`

    ->parse_from_filehandle( $fh ); # Slurps FH and streams its tokens to current FH

## `parse_from_string`

    ->parse_from_string( $string ); # decode $string as a PPI document and stream its comments tokens to FH

## `parse_from_document`

Lower level interface if you want to make `PPI` Objects yourself.

    ->parse_from_document( $ppi_document );

# SUBROUTINES/METHODS

## parse\_from\_file

Load a PPI::Document from a file and process it for comments

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Comment::Spell

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/Comment-Spell](https://metacpan.org/release/Comment-Spell)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Comment-Spell](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Comment-Spell)

- CPANTS

    [http://cpants.cpanauthors.org/dist/Comment-Spell](http://cpants.cpanauthors.org/dist/Comment-Spell)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Comment-Spell](http://matrix.cpantesters.org/?dist=Comment-Spell)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Comment-Spell](http://cpanratings.perl.org/d/Comment-Spell)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Comment::Spell](http://deps.cpantesters.org/?module=Comment::Spell)

# AUTHOR

Kent Fredric `<kentnl@cpan.org>`

Maintained by Nigel Horne, `<njh at bandsman.co.uk>`

# LICENSE AND COPYRIGHT

This software is copyright (c) 2017-2021 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
