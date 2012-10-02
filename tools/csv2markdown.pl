#!/usr/bin/perl
# 20120927/JT
# Author: oslopolitimoro <kontakt@oslopolitimoro.org>
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
use v5.10.1;

use strict;
use warnings;
use utf8;
use Getopt::Long;    # Handling parameters.
use Text::CSV;       # CSV file handling.
use File::Slurp;

# Fetch filename from command line
die usage() unless @ARGV;
Getopt::Long::Configure('bundling');
GetOptions( 'i|inputfile=s' => \my $inputfile );

# Read CSV File
my $csv = Text::CSV->new( { sep_char => ',', quote_char => '"' } );
my @content = read_file( $inputfile, { binmode => ':utf8' } );

foreach (@content) {
    next if m/^#/;
    if ( !$csv->parse($_) ) {
        warn "Failed to parse line: " . $csv->error_input;
        next;
    }
    generate_mkd_file_from( $csv->fields() );
}

sub usage {"Syntax:\n $0 -i|--inputfile <input.csv>\n"}

sub generate_mkd_file_from {
    my ( $date, $link, $title, $text ) = @_;

    my $content = read_file( \*DATA );    # Get template from __DATA__
    $content =~ s/\<title\>/$title/ig;
    $content =~ s/\<time\>/$date/ig;
    $content =~ s/\<text\>/$text/ig;
    $content =~ s/\<link\>/$link/ig;

    # Make markdownlinks of the text if available
    $text =~ s|\s(http://[^\s]+)| \[$1\]($1)|;

    # Build up filename and remove everything that doesn't belong there.
    my $filename = $date . "-" . lc($title);
    $filename =~ s/\s\d{1,2}:\d{2}//;
    $filename =~ s/å/aa/gi;
    $filename =~ s/ø/oe/gi;
    $filename =~ s/æ/ae/gi;
    $filename =~ s/\s+/_/g;
    $filename =~ s/[\;\:\,\.]+//g;
    $filename =~ s/\_+$//ig;
    $filename .= ".mkd";

    write_file( $filename, { binmode => ':utf8' }, $content );
}

__DATA__
---
layout: post
title: "<title>"
date: <time>
comments: true
categories: 
---
> <text>
- [Operasjonssentralen](<link>)
