#!/usr/bin/perl
# 20120927/JT
# Author: oslopolitimoro <konakt@oslopolitimoro.org>
# Takes a csv as input file and puts out every tupel as markdown file
#   ready for octopress to deploy
#
# Requires Text::CSV, Getopt::Long, Text::Iconv,
#
# Syntax:
#	perl csv2markdown.pl -i <csvinputfile> [-o destination]
# Example:
#	perl csv2markdown.pl -i tweetsources.csv -o ./output
# Output:
#	STDI: None, creates markdown files in the current folder though.
#
# ------------------------------------------------------------------------
use strict;
use warnings;
use Getopt::Long;    # Handling parameters.
Getopt::Long::Configure('bundling');
use Text::CSV;       # CSV file handling.
use Text::Iconv;     # Converting Strings for special characters.

sub usage {          # Routine prints the Syntax
    print "Syntax:
	script: -i|inputfile <input.csv>\n";
}

# Tweet template layout as constant $tweettemplace
use constant TWEETTEMPLATE => "---
layout: post
title: \"<tweettitle>\"
date: <timestamp>
comments: true
categories: 
---
> <tweettext>
- [Operasjonssentralen](<tweetlink>)
";

sub output_file {

    # Date:  $_[0]
    # Link:  $_[1]
    # Title: $_[2]
    # Text:  $_[3]
    my $outputfilecontent = TWEETTEMPLATE;
    $outputfilecontent =~ s/\<tweettitle\>/$_[2]/ig;
    $outputfilecontent =~ s/\<timestamp\>/$_[0]/ig;

    $_[3] =~ s/\s(http\:\/\/[^\s]+)/ \[$1\]\($1\)/
      ;    # make markdownlinks of the text if available
    $outputfilecontent =~ s/\<tweettext\>/$_[3]/ig;
    $outputfilecontent =~ s/\<tweetlink\>/$_[1]/ig;

# We need to run this conversion, otherwise reg-ex will not match the special chars. God knows why.
    my $converter = Text::Iconv->new( "utf-8", "utf-8" );
    $_[2] = $converter->convert( $_[2] );

    # Build up filename and remove everything that doesn't belong there.
    my $outputfilename = ( $_[0] . "-" . lc( $_[2] ) );
    $outputfilename =~ s/\s\d{1,2}:\d{2}//;
    $outputfilename =~ s/\å/aa/gi;
    $outputfilename =~ s/\ø*/oe/gi;
    $outputfilename =~ s/\æ*/ae/gi;
    $outputfilename =~ s/\s+/_/g;
    $outputfilename =~ s/[\;\:\,\.]+//g;
    $outputfilename =~ s/\_$//ig;
    $outputfilename = $outputfilename . ".markdown";
    my $result = open MARKDOWNOUTPUT, '>:encoding(utf8)', $outputfilename;

    # Write file
    print MARKDOWNOUTPUT $outputfilecontent;
    close MARKDOWNOUTPUT;
}

usage() && die "\n => Error: not enough parameters specified. Abort.\n\n"
  unless ( @ARGV > 0 );

# Get parameters
my $result = GetOptions( 'i|inputfile=s' => \my $pathinputfile, );

# Read CSV File
$result = open CSVINPUT, '<:encoding(utf8)', "$pathinputfile";

usage() && die "=> Error: Can't find csv file: '$!'. Abort.\n\n"
  unless ($result);

my $csvfile = Text::CSV->new( { sep_char => ',', quote_char => '"' } );
while (<CSVINPUT>) {
    if ( $csvfile->parse($_) ) {
        my @columns = $csvfile->fields();
        if ( !$columns[0] eq '' && $columns[0] =~ /^[^#]+/ )
        {    # Ignore empty or commented rows.
            output_file(@columns);
        }
    }
    else {
        my $err = $csvfile->error_input;
        print "Failed to parse line: $err";
    }

}
close CSVINPUT;
