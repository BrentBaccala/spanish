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
# $Log: spanish.cgi,v $
# Revision 1.9  2001/07/10 17:46:00  baccala
# Filter out XML <!if...> statements until HTML::Parser is fixed
#
# Revision 1.8  2001/05/14 02:31:43  baccala
# Added ability to figure out URL we're called as ($myurl) instead of this
# being hardwired.  Assumes all dependent scripts are in the same directory.
#
# Cleaned up code for "use strict" and updated comment at top of file
#
# Revision 1.7  2001/05/13 12:42:58  baccala
# Canonicalize URL passed to us, for the sake of the BASE tags
#
# Revision 1.6  2001/05/13 02:09:58  baccala
# Fix inconsistency between script and index.htm page - use "URL"
# throughout FORM data as name of target URL
#
# Revision 1.5  2001/05/12 22:30:57  baccala
# Changed FORM variables so that the URL to link to is passed directly
# in as a FORM variable.
#
# Revision 1.4  2001/05/12 20:38:01  baccala
# Added ability to choose which translator to use
#
# Revision 1.3  2001/04/26 15:11:54  baccala
# Moved $transurl here from tfilter.pm
#
# Revision 1.2  2001/04/09 16:01:42  baccala
# Added the ability to take POSTs as well as GETs
#

use strict;

require LWP;
require URI;
require tfilter;

use translators;

# $query is the URL to markup.  $transurl is the prefix to put before the
# word to be translated.  $linkurl is the prefix to put before (escaped)
# URLs.

my $query;
my $transurl;
my $linkurl;

# Relative URLs are a pain in this script.  We set a BASE tag on the document
# to make relative URLs in the HTML point to the original documents.  That
# means we can't use relative URLs to ourselves, so we need to know our URL...

my $myurl = "http://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}";
$myurl =~ s:/[^/]*$::;  # Strip off final slash and script name after it

&se("local Larousse SE", "$myurl/larousse.pl?DIRECTION=spaneng&word=");

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

my $queryURI;
if ($FORM{"URL"} ne "user") {
    $queryURI = new URI($FORM{"URL"});
} else {
    $queryURI = new URI($FORM{"userURL"});
}
$query = $queryURI->canonical;

if (exists $translator_url{$FORM{"Translator"}}) {
    $transurl = $translator_url{$FORM{"Translator"}};
} else {
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

$linkurl = "$myurl/spanish.pl?Translator=$FORM{Translator}&URL=";

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

	my $p = tfilter->new($query, $FORM{"Translator"}, $linkurl);

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
