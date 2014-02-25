#!/usr/bin/perl -- -*-perl-*-

# Programa por buscando en una diccionario Español/Ingles
# escrito por Brent Baccala  <baccala@freesoft.org>  20 mar 2002

use Encode;

use translators;

# Relative URLs are a pain in this script.  We set a BASE tag on the document
# to make relative URLs in the HTML point to the original documents.  That
# means we can't use relative URLs to ourselves, so we need to know our URL...

my $myurl = "http://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}";
$myurl =~ s:/[^/]*$::;  # Strip off final slash and script name after it

&se("local Larousse SE", "$myurl/larousse.pl?DIRECTION=spaneng&word=");

print qq|Content-type: text/html; charset=iso-8859-1

<HTML>
<HEAD>
<TITLE>Spanish Reading Aid</TITLE>
</HEAD>
<BODY>

<CENTER><H1>Spanish Reading Aid</H1></CENTER>

<P>

This script puts hyperlinks on all the words on a web page.  Clicking
on one of the words causes a popup window to appear with the
translation of the word.  To use this feature, enter below the URL of
the web page you want to read, select a translation dictionary, and
click the button.

<P><CENTER><FORM ACTION=spanish.pl>
<INPUT TYPE=HIDDEN NAME=URL VALUE=user>
<INPUT SIZE=50 TYPE=TEXT NAME=userURL VALUE="http://www.freesoft.org/biblia/">
<SELECT NAME=Translator>
|;

    print "<OPTION disabled>de ingles a español -- english to spanish</OPTION>\n";

    for my $name (@es_translators) {
	print "<OPTION VALUE=\"$name\">$name</OPTION>\n";
    }

    print "<OPTION disabled>de español a ingles -- spanish to english</OPTION>\n";

    for my $name (@se_translators) {
	print "<OPTION VALUE=\"$name\">$name</OPTION>\n";
    }

    print qq|
</SELECT>
<INPUT TYPE=SUBMIT>
</FORM></CENTER>

<SCRIPT TYPE="text/javascript">
function setURL(url)
{
    document.forms[0].userURL.value = url;
    return false;
}
</SCRIPT>

<P>
Here are some documents I recommend for native English readers learning
Spanish.

<P><UL>
<LI><A HREF="javascript:void(0);" onclick="setURL('http://www.freesoft.org/biblia/')">La Biblia</A> (The Bible)
<LI><A HREF="javascript:void(0);" onclick="setURL('http://www.elmundo.es/')">El Mundo</A> - Madrid Newspaper
<LI><A HREF="javascript:void(0);" onclick="setURL('http://aix1.uottawa.ca/~jmruano/sombrerodetrespicos.html')">El Sombrero de Tres Picos</A>
<LI><A HREF="javascript:void(0);" onclick="setURL('http://www.donquixote.com/')">Don Quixote</A>
</UL>

</BODY>
</HTML>
|;
