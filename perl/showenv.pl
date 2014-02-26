#! /usr/bin/perl
#
# Show all the environment variables passed to a CGI script

print "Content-type: text/html\n\n";

print "<HTML>\n";
print "<HEAD>\n";
print "<TITLE>CGI Script Environment Vars</TITLE>\n";
print "</HEAD>\n";
print "<BODY>\n";
print "<CENTER><H3>CGI Script Environment Vars</H3></CENTER>\n";

print "This is a list of environment variables (and the values)\n";
print "that were passed to this CGI script.\n";
print "<P>\n";

print "<TABLE BORDER>\n";

foreach $key (sort keys %ENV) {
    print "<TR><TH>$key</TH><TD>$ENV{$key}</TD></TR>\n";
}

print "</TABLE>\n";

print "</PRE>\n";
print "</BODY>\n";
print "</HTML>\n";
