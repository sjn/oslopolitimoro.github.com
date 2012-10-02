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

    # Date:  $_[0]
    # Link:  $_[1]
    # Title: $_[2]
    # Text:  $_[3]
    my $outputfilecontent = read_file(\*DATA);
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
