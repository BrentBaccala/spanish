#!/usr/bin/perl -- -*-perl-*-

# Programa por buscando en una diccionario Español/Ingles
# escrito por Brent Baccala  <baccala@freesoft.org>  20 mar 2002

use lib "../libs";
use translators;

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
<INPUT SIZE=50 TYPE=TEXT NAME=URL VALUE="http://www.freesoft.org/biblia/">
<SELECT NAME=Direction>
<OPTION SELECTED VALUE="SE">ES->EN</OPTION>
<OPTION VALUE="ES">EN->ES</OPTION>
</SELECT>
<SELECT NAME=Translator>
|;

    for my $name (@translators) {
	print "<OPTION VALUE=\"$name\">$name</OPTION>\n";
    }

    print qq|
</SELECT>
<INPUT TYPE=SUBMIT>
</FORM></CENTER>

<SCRIPT TYPE="text/javascript">
function setURL(url)
{
    document.forms[0].URL.value = url;
    return false;
}
</SCRIPT>

<P>
Here are some documents I recommend for native English readers learning
Spanish.

<P><UL>
<LI><A HREF="javascript:void(0);" onclick="setURL('http://www.freesoft.org/biblia/')">La Biblia Reina Valera</A>
  - The Queen Valera Bible (with audio)
<P>I suggest reading one chapter each day.  Read the chapter first in English, then in Spanish, looking
up any words that you don't know.  Then listen to the audio recording of the chapter, and finally
play the recording again, this time reading aloud from the text as you go.

<LI><A HREF="javascript:void(0);" onclick="setURL('http://www.elmundo.es/')">El Mundo</A> - Madrid Newspaper
<LI><A HREF="javascript:void(0);" onclick="setURL('http://aix1.uottawa.ca/~jmruano/sombrerodetrespicos.html')">El Sombrero de Tres Picos</A>
<LI><A HREF="javascript:void(0);" onclick="setURL('http://www.donquixote.com/')">Don Quixote</A>
</UL>

<P>
The script's source code is available in a <A HREF="https://github.com/BrentBaccala/spanish">GitHub repository</A>.

<P>
It can be used offline (without an Internet connection), so long as you have Perl and a web server.
Set the web server to execute <tt>.pl</tt> files as CGI scripts.
A local Spanish-English dictionary is also required.
If you have the Larousse Gran Diccionario, you can copy (or link) its <TT>data</TT> directory into the script's
<TT>perl</TT> directory, and it will become available as "local Larousse".

<P STYLE="padding-left: 60%;">
Brent Baccala
<br><a href="http://www.freesoft.org/"><tt>freesoft.org</tt></a>
</P>

</BODY>
</HTML>
|;
