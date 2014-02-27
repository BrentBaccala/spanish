#! /usr/bin/perl
#
# Perl CGI script spanish.pl
#
# Brent Baccala    baccala@freesoft.org
#
# This CGI script takes FORM data either as a query string after a '?' (GET),
# or as content (POST).  The form variables specify a URL and a translator
# script.  We retreive the URL and (if it's HTML) run it through "tfilter"
# to mark every word in the text with a link to the translator script.  We
# also change the links in the HTML so they point back to this script,
# causing any linked-to page to be similarly marked up with translator links.
#

use strict;

require LWP;
require URI;

use lib "../libs";
require tfilter;
use translators;

# Relative URLs are a pain in this script.  We set a BASE tag on the document
# to make relative URLs in the HTML point to the original documents.  That
# means we can't use relative URLs to ourselves, so we need to know our URL...

my $myurl = "http://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}";
$myurl =~ s:/[^/]*$::;  # Strip off final slash and script name after it

my %FORM;
my $buffer;

if (exists $ENV{"CONTENT_LENGTH"}) {
    read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
} elsif (exists $ENV{"QUERY_STRING"}) {
    $buffer = $ENV{"QUERY_STRING"};
}

# Split the name-value pairs
my @pairs = split(/&/, $buffer);

foreach my $pair (@pairs)
{
    my ($name, $value) = split(/=/, $pair);

    # Un-Webify plus signs and %-encoding
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

    $FORM{$name} = $value;
}

# $query is the URL to markup.

my $queryURI = new URI($FORM{"URL"});
my $query = $queryURI->canonical;

if (not exists $translator_url{$FORM{"Translator"} . $FORM{"Direction"}}) {
    print q|Content-type: text/html

<html>
<head><title>An Error Occurred</title></head>
<body>
<h1>An Error Occurred</h1>
<p>Translator unknown or missing</p>
</body>
</html>
|;
    exit;
}

# $linkurl is the prefix to put before (escaped) URLs.

my $linkurl = "$myurl/spanish.pl?Translator=$FORM{Translator}&Direction=$FORM{Direction}&URL=";

my $ua = LWP::UserAgent->new;

my $request = HTTP::Request->new("GET");
$request->uri($query);

my $response = $ua->request($request);

if ($response->is_success) {
    my $content_type = $response->content_type;
    my $content = $response->content;

    # In the event of a redirect, we need to use the actual name of the 
    # document, not the alias originally requested.  So we make sure that
    # $query is the URI actually requested for the response.

    $query = $response->request->uri;

    print "Content-type: $content_type\n\n";

    if ($content_type eq "text/html" or $content_type eq "text/xml") {

	my $p = tfilter->new($query, $FORM{"Translator"} . $FORM{"Direction"}, $linkurl);

	$content =~ s/<![^>]*>//g;

	$p->parse($content);
	$p->eof;

    } else {
	print $content;
    }

} else {
    print "Content-type: text/html\n\n";
    print $response->error_as_HTML;
}
