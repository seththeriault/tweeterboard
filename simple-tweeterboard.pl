#!/usr/bin/perl

use strict;
use warnings;

use Encode;
use LWP::Simple;
use JSON;
use POSIX qw(strftime);
use URI::Escape;

our $VERSION = 0.8;

# hashes for tweet data
my %twitter_tweets = ();
my %twitter_users = ();
my %twitter_sources = ();
my %twitter_tweet_dates = ();

my $hashtag = "#HASHTAG";

my $now_string = strftime "%a %b %e %Y %T UTC", gmtime;
my $filetime = strftime "%Y%m%d%H%M", gmtime;

my $html_dir = "tweeterboard-html";
my $html_output_file = "$html_dir/index.html";

my $qstring = uri_escape($hashtag);
my $twitter_search_uri = "http://search.twitter.com/search.json";

# use old_max_id to get new stuff
my $content = get($twitter_search_uri . "?q=$qstring&rpp=200");

# get new max_id
my $search_results_json = JSON->new->allow_nonref->decode($content);

my $tweet_max_id = scalar ($search_results_json->{"max_id"});

for my $result( @{$search_results_json->{"results"}} ){

    # munge the source of tweets
    my $tweet_source = $result->{"source"};
    $tweet_source =~ s/&gt;/>/gx;
    $tweet_source =~ s/&lt;/</gx;
    $tweet_source =~ s/&quot;/\"/gx;

    # remove rel="nofollow" links
    $tweet_source =~ s/ rel=\"nofollow\"//gx;

    # remove trailing slashes from URIs
    $tweet_source =~ s/\/\"\>/\"\>/gx;

    # pre-pend "http://twitter.com" to relative links
    $tweet_source =~ s/href=\"\//href=\"http:\/\/twitter.com\//gx;

    # increment counts for statistics
    $twitter_sources{$tweet_source}++;
    $twitter_tweets{"total"}++;
    $twitter_users{$result->{"from_user"}}++;

}

my $error = open HTMLFILE, ">:encoding(UTF-8)", $html_output_file;

print HTMLFILE "<HTML>\n<HEAD>\n<title>TweeterBoard ($hashtag)</title>\n</HEAD>\n<BODY>\n<H1>TweeterBoard ($hashtag)</H1>\n<b>Last update:</b><tt> $now_string</tt><br>\nData source: <a href=\"https://twitter.com/#!/search/realtime/$qstring\" target=\"_blank\">search.twitter.com public feed</a>\n<hr>\n";

print HTMLFILE "<H3>" . $twitter_tweets{"total"} . " tweets tagged with <tt>" . $hashtag . "</tt></H3>\n"; 

print HTMLFILE "<a name=\"tweeters\"><H3> Tweeters (by number of tweets)</H3><a>\n";

foreach my $key (reverse sort numerically_users (keys(%twitter_users))) {
   print HTMLFILE "<pre>";
   printf HTMLFILE '%-5s', $twitter_users{$key};
   print HTMLFILE "<a href=\"http://twitter.com/$key\" target=\"_blank\">";
   printf HTMLFILE '%s', "$key</a>";
   print HTMLFILE "</pre>\n";
}

print HTMLFILE "<a name=\"clients\"><H3>Twitter Clients (by # of tweets)</H3></a>\n";

foreach my $key2 (reverse sort numerically_sources (keys(%twitter_sources))) {
   print HTMLFILE "<pre>";
   printf HTMLFILE '%-5s', $twitter_sources{$key2};
   printf HTMLFILE '%30s', $key2;
   print HTMLFILE "</pre>\n";
}

print HTMLFILE "\n</BODY>\n</HTML>";
$error = close HTMLFILE;

exit 0;

# subroutines
sub numerically_users { return $twitter_users{$a} <=> $twitter_users{$b}; }
sub numerically_sources { return $twitter_sources{$a} <=> $twitter_sources{$b}; }
