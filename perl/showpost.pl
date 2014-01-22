#!/usr/local/bin/perl -- -*-perl-*-

# ------------------------------------------------------------
# submit_job.pl, by Kyle Hourihan
#   most Perl Code thanks to Reuven M. Lerner (reuven@the-tech.mit.edu).
#   modified by Eli Rosenblatt
#
# Last updated: 8/30/95
#
# job_input.pl allows a recruiter to post new jobs listings in 
# a WWW html form and outputs the response to a the server.
# This script requires Perl and should run on any CGI-compatible 
# HTTP server.
# 
# ------------------------------------------------------------

# ------------------------------------------------------------

# job_post.pl is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any
# later version.


# You should have received a copy of the GNU General Public License
# along with Form-mail; see the file COPYING.  If not, write to the Free
# Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
# ------------------------------------------------------------

# NOTE:  Check the variables below the splits() for server specific paths 


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

# Print out a content-type for HTTP/1.0 compatibility
print "Content-type: text/html\n\n";

print "<HTML>\n";
print "<HEAD>\n";
print "<TITLE>CGI Script Post Vars</TITLE>\n";
print "</HEAD>\n";
print "<BODY>\n";
print "<CENTER><H3>CGI Script Post Vars</H3></CENTER>\n";

print "This is a list of post variables (and the values)\n";
print "that were passed to this CGI script.\n";
print "<P>\n";

print "<TABLE BORDER>\n";

$i=0;
foreach $variable (%FORM) {
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

