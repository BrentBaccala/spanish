#! /usr/bin/perl

require LWP;
require tfilter;

if (exists $ENV{"QUERY_STRING"}) {
    $query = $ENV{"QUERY_STRING"};
} else {
    $query = "http://localhost/reading.html";
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

	$p = tfilter->new();

	$p->parse($content);
	$p->eof;

    } else {
	print $content;
    }

} else {

    print "Content-type: text/html\n\n";

    print $response->error_as_HTML;
}

