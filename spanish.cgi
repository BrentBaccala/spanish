#! /usr/bin/perl
#
# Perl CGI script spanish.cgi
#
# Brent Baccala    baccala@freesoft.org
#
# This CGI script takes a URL either as a query string after a '?' (GET), or
# as a form variable (POST).  It retreives the URL and (if it's HTML) runs
# it through "tfilter" to mark all the text with links to a translator script.
#
# $Log: spanish.cgi,v $
# Revision 1.4  2001/05/12 20:38:01  baccala
# Added ability to choose which translator to use
#
# Revision 1.3  2001/04/26 15:11:54  baccala
# Moved $transurl here from tfilter.pm
#
# Revision 1.2  2001/04/09 16:01:42  baccala
# Added the ability to take POSTs as well as GETs
#

require LWP;
require tfilter;

my $transurl;

my $query = "http://localhost/reading.html";


if (exists $ENV{"CONTENT_LENGTH"}) {

    # Get the input
    read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});

} elsif (exists $ENV{"QUERY_STRING"}) {

    $buffer = $ENV{"QUERY_STRING"};

}

# Split the name-value pairs
@pairs = split(/&/, $buffer);

foreach $pair (@pairs)
{
    ($name, $value) = split(/=/, $pair);

    # Un-Webify plus signs and %-encoding
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

    # Stop people from using subshells to execute commands
    # Not a big deal when using sendmail, but very important
    # when using UCB mail (aka mailx).
    # $value =~ s/~!/ ~!/g; 
    # Uncomment for debugging purposes
    # print "Setting $name to $value<P>";

    $FORM{$name} = $value;
}

if ($FORM{"target"} ne "user") {
    $query = $FORM{"target"};
} else {
    $query = $FORM{"userURL"};
}


if ($FORM{"Translator"} eq "wordreference") {
    $transurl = "http://www.wordreference.com/es/en/translation.asp?spen=";
} elsif ($FORM{"Translator"} eq "diccionarios") {
    #$transurl = "http://www.diccionarios.com/cgi-bin/esp-engl.php?URL=query%3D";
    $transurl = "http://vyger.freesoft.org/cgi-bin/diccionarios.cgi?";
} elsif ($FORM{"Translator"} eq "vox") {
    $transurl = "http://vyger.freesoft.org/cgi-bin/vox.cgi?";
} else {
    $FORM{"Translator"} = "babelfish";
    $transurl = "http://vyger.freesoft.org/cgi-bin/translator.cgi?";
}

my $linkurl = "http://vyger.freesoft.org/cgi-bin/spanish.cgi?Translator=$FORM{Translator}&URL=";

$ua = LWP::UserAgent->new;

$request = HTTP::Request->new("GET");
$request->uri($query);

$response = $ua->request($request);

if ($response->is_success) {
    my $content_type = $response->content_type;
    my $content = $response->content;

    print "Content-type: $content_type\n\n";

    if ($content_type eq "text/html") {

	$p = tfilter->new($query, $transurl, $linkurl);

	$p->parse($content);
	$p->eof;

    } else {
	print $content;
    }

} else {
    print "Content-type: text/html\n\n";
    print $response->error_as_HTML;
}
