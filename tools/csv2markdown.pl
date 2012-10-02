#!/usr/bin/perl
# 20120927/JT
# Author: oslopolitimoro <konakt@oslopolitimoro.org>
# Takes a csv as input file and puts out every tupel as markdown file
#   ready for octopress to deploy
#
# Requires Text::CSV, Getopt::Long, Text::Iconv,
#
# Syntax:
#	perl csv2markdown.pl -i <csvinputfile>
# Example:
#	perl csv2markdown.pl -i tweetsources.csv
# Output:
#	STDOUT: None, creates markdown files in the current folder though.
#
# ------------------------------------------------------------------------
use strict;
use warnings;
use Getopt::Long;    # Handling parameters.
use Text::CSV;       # CSV file handling.
use Text::Iconv;     # Converting Strings for special characters.
use File::Slurp;
use utf8;

use v5.10.1;


Getopt::Long::Configure('bundling');

die usage("Error: not enough parameters specified. Aborting.")
  unless @ARGV;

# Get parameters
GetOptions( 'i|inputfile=s' => \my $pathinputfile, );

# Read CSV File
my $csv_content = read_file($pathinputfile, { binmode => ':utf8' })
  || die usage("Error: Can't read csv file: '$!'. Aborting.");

my $csv = Text::CSV->new( { sep_char => ',', quote_char => '"' } );
my @content = split /\n/, $csv_content;
while ( my $line = shift @content ) {
    next if $line =~ m/^#/;
    if ( ! $csv->parse($line) ) {
       warn "Failed to parse line: " . $csv->error_input;
       next;
    }
    my @fields_in_tweet = $csv->fields();
    output_file(@fields_in_tweet);
}


sub usage {          # Routine prints the Syntax
    my $error_msg = shift // "";
    my $usage = "Syntax:
	$0: -i|inputfile <input.csv>\n";

    $error_msg = "\nError: $error_msg\n\n" if $error_msg;

    return $usage . $error_msg;
}


sub output_file {
    my( $date, $link, $title, $text ) = @_;

    my $content = read_file(\*DATA);  # Get template from __DATA__
    $content =~ s/\<tweettitle\>/$title/ig;
    $content =~ s/\<timestamp\>/$date/ig;
    $content =~ s/\<tweettext\>/$text/ig;
    $content =~ s/\<tweetlink\>/$link/ig;

    # Make markdownlinks of the text if available
    $text =~ s/\s(http\:\/\/[^\s]+)/ \[$1\]\($1\)/;

    # Build up filename and remove everything that doesn't belong there.
    my $filename = $date . "-" . lc( $title );
    $filename =~ s/\s\d{1,2}:\d{2}//;
    $filename =~ s/å/aa/gi;
    $filename =~ s/ø/oe/gi;
    $filename =~ s/æ/ae/gi;
    $filename =~ s/\s+/_/g;
    $filename =~ s/[\;\:\,\.]+//g;
    $filename =~ s/\_+$//ig;
    $filename .= ".mkd";

    write_file( $filename, { binmode => ':utf8'}, $content );
}


__DATA__
---
layout: post
title: "<tweettitle>"
date: <timestamp>
comments: true
categories: 
---
> <tweettext>
- [Operasjonssentralen](<tweetlink>)
