#!/usr/bin/perl
# 20120927/JT
# Author: oslopolitimoro <konakt@oslopolitimoro.org>
# Greps the tweet content from Twitter tweet and outputs
# a csv line.
#
# Requires HTML::Treebuilder
# 
# Syntax:
#	perl greptweet.pl <url>
# Example:
#	perl greptweet.pl http://twitter.com/oslopolitiops/statuses/250036062792085504
# Output:
#	2012-09-23 17:56;http://twitter.com/oslopolitiops/statuses/250036062792085504;Nå er hestene igjen løse ...;Nå er hestene igjen løse ved Gaustad. Denne gangen forsøker vi å bruke politiets sperrebånd, vi tror nemlig hestene vil respektere det.
#
# This is used to create a CSV files of of tweets serving as source for another scripts creating the markdown files for Octopress.
# ------------------------------------------------------------------------
use strict;
use LWP::UserAgent;
use HTML::TreeBuilder;

sub usage {								# Routine prints the Syntax
	print "\n\nSyntax:
		script.pl: Tweet-URL
	Example: 
		perl script.pl https://api.twitter.com/1.1/statuses/show.json?id=250036062792085504
		\n";
}

usage() && die "\n => Error: no URL specified. Abort.\n\n"
	unless ( @ARGV == 1);

# Get HTML Tweet from TWitter
my $ua = new LWP::UserAgent;
$ua->timeout(120);
my $url = @ARGV[0];
my $request = new HTTP::Request('GET', $url);
my $response = $ua->request($request);
my $HTMLcontent = $response->content();

# Parse HTMLcontent
my $tree = HTML::TreeBuilder->new_from_content($HTMLcontent);
$tree->parse($HTMLcontent);
# Get Tweet Title
my ($title) = $tree->look_down('_tag','title');
# Get Tweet Text
my ($searchtext) = $tree->look_down('class','js-tweet-text');
# Get Tweet Timestamp line
my ($tweettimestamp) = $tree->look_down(
	'tag','a' and
	'class','tweet-timestamp js-permalink js-nav'	
);

# Get and format title (without the stupid "Twitter / <account>: "-stuff)
my $HTMLTitle = $title->as_text();
$HTMLTitle =~ s/^[^\:]+\:\s//i;
# Get and format the text without leading spaces
my $HTMLText = $searchtext->as_text();
$HTMLText =~ s/^\s+//i;
# Get and format the Tweet timestamp.
my $HTMLTime = $tweettimestamp->as_HTML();
$HTMLTime =~ m/title\=\"(\d{1,2}):(\d{1,2})\s(\w{2})\s\-\s(\d{1,2})\s(\w{3})\s(\d{2})\"/i;
my $hour = $1;
if ( lc($3) eq "pm" && $hour != 0 ){
	$hour += 12;
}
my $minute = $2;
my $day = $4;
my $year = "20".$6;
my %mon2num = qw(
    jan 1  feb 2  mar 3  apr 4  may 5  jun 6
    jul 7  aug 8  sep 9  oct 10 nov 11 dec 12
);
my $month = $mon2num{"$5"};
if ( length($month) eq 1) {$month = "0".$month};
if ( length($day) eq 1) {$day = "0".$day};
$HTMLTime = $year."-".$month."-".$day." ".$hour.":".$minute; 

# Final output line
print $HTMLTime.";".$url.";".$HTMLTitle.";".$HTMLText."\n";

# Cleanup
$tree->delete;



# Some Syntax Reference
## Test-tweet
## http://twitter.com/oslopolitiops/statuses/250036062792085504
##
## Tag with timestamp of the tweet in HTML
## <a class="tweet-timestamp js-permalink js-nav" href="/oslopolitiops/status/250036062792085504" title="5:56 PM - 23 sep 12"><span class="_timestamp js-short-timestamp js-relative-timestamp" data-long-form="true" data-time="1348448217">8t</span></a>
##
## Tag with text of the Test-Tweet in HTML
## <p class="js-tweet-text">
##                  Nå er hestene igjen løse ved Gaustad. Denne gangen forsøker vi å bruke politiets sperrebånd, vi tror nemlig hestene vil respektere det.
##</p>
