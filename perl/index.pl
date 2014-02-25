#!/usr/bin/perl -- -*-perl-*-

# Programa por buscando en una diccionario Español/Ingles
# escrito por Brent Baccala  <baccala@freesoft.org>  20 mar 2002

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

<P>

Tambien, es posible a usar el diccionario vía a una programa que
ponga hipervínculos a todas de las palabras de una página de red.
El hacer clic a una de las palabras causa el aparición de una
ventana con la traducción de la palabra.  Para usar esta capacidad
introduce abajo la dirreción de red que quieras leer, selecciona
la dirreción de traducción, y clic al botón.

<P>

It is also possible to use the diccionary via a script that puts
hyperlinks on all the words on a web page.  Clicking on one of the
words causes a popup window to appear with the translation of the
word.  To use this feature, enter below the URL of the web page
you want to read, select the dirrection of translation, and click
the button.

<P><CENTER><FORM ACTION=spanish.pl>
<INPUT TYPE=HIDDEN NAME=URL VALUE=user>
<INPUT SIZE=50 TYPE=TEXT NAME=userURL VALUE="http://www.freesoft.org/">
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

<P>
Here are some documents I recommend for native English readers learning
Spanish.

<P><UL>
<LI><A HREF="spanish.pl?URL=user&userURL=http://www.sgci.mec.es/uk/Pub/tecla.html&Translator=newworld-se">Tecla</A> - Texts for Teachers and Learners of Spanish
<LI><A HREF="spanish.pl?URL=user&userURL=http://www.elmundo.es/&Translator=newworld-se">El Mundo</A> - Madrid Newspaper
<LI><A HREF="spanish.pl?URL=user&userURL=http://www.freesoft.org/biblia/&Translator=newworld-se">La Biblia</A> (The Bible)
<LI><A HREF="spanish.pl?URL=user&userURL=http://aix1.uottawa.ca/~jmruano/sombrerodetrespicos.html&Translator=newworld-se">El Sombrero de Tres Picos</A>
<LI><A HREF="spanish.pl?URL=user&userURL=http://www.donquixote.com/&Translator=newworld-se">Don Quixote</A>
</UL>

</BODY>
</HTML>
|;
