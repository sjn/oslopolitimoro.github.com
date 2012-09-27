#!/usr/bin/perl
# 20120927/JT
# Author: oslopolitimoro <konakt@oslopolitimoro.org>
# Takes a csv as input file and puts out every tupel as markdown file
#   ready for octopress to deploy
#
# Requires Text::CSV, Getopt::Long
# 
# Syntax:
#	perl csv2markdown.pl -i <csvinputfile> [-o destination]
# Example:
#	perl csv2markdown.pl -i tweetsources.csv -o ./output
# Output:
#	
#
# ------------------------------------------------------------------------
use strict;
use warnings;
use Getopt::Long;						# Handling parameters
Getopt::Long::Configure ('bundling');
use Text::CSV;
#use URI::Escape;

# use POSIX;
# use File::Basename;						# Filename handling

sub usage {								# Routine prints the Syntax
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
	# binmode(STDOUT, ":utf8");
	my $outputfilecontent = TWEETTEMPLATE;
	$outputfilecontent =~ s/\<tweettitle\>/$_[2]/ig;
	$outputfilecontent =~ s/\<timestamp\>/$_[0]/ig;
	$outputfilecontent =~ s/\<tweettext\>/$_[3]/ig;
	$outputfilecontent =~ s/\<tweetlink\>/$_[1]/ig;	
	my $outputfilename = ($_[0]."-".lc($_[2]));
	$outputfilename =~ s/\s\d{1,2}:\d{2}//;
	$outputfilename =~ s/\å/aa/g;
	$outputfilename =~ s/\ø*/oe/g;
	$outputfilename =~ s/\æ*/ae/g;
	$outputfilename =~ s/\s+/_/g;
	$outputfilename =~ s/\.+//g;
	$outputfilename =~ s/\,//g;
	$outputfilename =~ s/\_$//g;
	$outputfilename = $outputfilename.".markdown";
	my $result = open MARKDOWNOUTPUT, '>:encoding(utf8)',$outputfilename;
	# Write file
	print MARKDOWNOUTPUT $outputfilecontent;
	close MARKDOWNOUTPUT;
}

usage() && die "\n => Error: not enough parameters specified. Abort.\n\n"
	unless ( @ARGV > 0 );
	
# Get parameters
my $result = GetOptions (
					 'i|inputfile=s' => \my $pathinputfile,				 	 
					 );

# Read CSV File
my $csvfile = Text::CSV->new({sep_char=> ';'});
$result = open CSVINPUT, '<:encoding(utf8)', "$pathinputfile";
if (! $result) {
	usage();
	print "=> Error: Can't find csv file. Abort.\n\n";
}

seek CSVINPUT,0,0;
while (<CSVINPUT>){
	if ($csvfile->parse($_)) {
		my @columns = $csvfile->fields();
		if ( ! $columns[0] eq '' ) {
			output_file (@columns);
		}
	} else {
            my $err = $csvfile->error_input;
            print "Failed to parse line: $err";
    }
	
}

# Remaining Tasks
# * kill annoying special characters in the filenames, e.g. å,ø,æ. The Regex doesn't get them somehow.
