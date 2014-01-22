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

$i=0;
foreach $variable (%ENV) {
   if ($i == 0) {
      print "<TR><TH>$variable</TH>\n";
      $i=1;
   } else {
      print "<TD>$variable</TD></TR>\n";
      $i=0;
   }
}
print "</TABLE>\n";

print "</PRE>\n";
print "</BODY>\n";
print "</HTML>\n";
