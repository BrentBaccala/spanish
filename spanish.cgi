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
# $Log$

require LWP;
require tfilter;

$query = "http://localhost/reading.html";

if (exists $ENV{"CONTENT_LENGTH"}) {

    # Get the input
    read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});

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

    $query = $FORM{"URL"} if (exists $FORM{"URL"});

} elsif (exists $ENV{"QUERY_STRING"}) {

    $query = $ENV{"QUERY_STRING"};

}

$ua = LWP::UserAgent->new;

$request = HTTP::Request->new("GET");
$request->uri($query);

$response = $ua->request($request);

if ($response->is_success) {
    my $content_type = $response->content_type;
    my $content = $response->content;

    print "Content-type: $content_type\n\n";

    if ($content_type eq "text/html") {

	$p = tfilter->new($query);

	$p->parse($content);
	$p->eof;

    } else {
	print $content;
    }

} else {

    print "Content-type: text/html\n\n";

    print "!", $query, "!";

    # print $response->error_as_HTML;
}
