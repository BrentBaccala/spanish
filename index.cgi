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


# Lea la entrada

if (exists $ENV{'CONTENT_LENGTH'}) {
    read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
} else {
    $buffer = $ENV{'QUERY_STRING'};
}

# Parte el nombre/valor pars
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

# Escribe el content-type
print "Content-type: text/html\n\n";

# Escribe el encabezado HTML
print "<HTML>\n";
print "<HEAD>\n";
print "<TITLE>New World Diccionario</TITLE>\n";
print "</HEAD>\n";
print "<BODY>\n";

print "<CENTER><IMG SRC=\"header.gif\" WIDTH=317 HEIGHT=84></CENTER><P>\n";

# Inicialize varios variables

my $query = lc $FORM{'word'};		# La palabra por que buscamos
my $querylen = length $query;		# La longitud de esta palabra

my $limit = 20;				# El máximo numero de respuestas
my $count = 0;				# El numero de respuestas hasta ahora

my $engsel;				# Cadenas indicandas la dirreción
my $spansel;				#   de transducción

my $quickresponse = 0;

# Si el usuario proveido un pregunta, busque por ella y escribe una respuesta

if (exists($FORM{'word'})) {

    my $table = $FORM{'DIRECTION'};	# Use la dirreción de transducción
					#   por el nombre de archivo o tabla
					#   en cual buscar

    my $dbh;				# Asa de la base de datos
    my $sth;				# Asa de nuestro comando a la base

    $quickresponse = 1;

    print "<P><HR><CENTER><H3>$query</H3></CENTER>\n";
    print "<TABLE>\n";

    # Trate a usar paquete DBI y conecte a la base de datos "diccionario".
    # Quiero este andar en una cláusula "eval" en caso de falla, cuando
    # retrocederemos a el uso de el archivo directamente.

    eval {
	require DBI;

	$dbh = DBI->connect("DBI:mysql:diccionario");
	$sth = $dbh->prepare("SELECT word, definition FROM $table WHERE word LIKE ?");
    };

    # Dependiendo de el exito o falla de nuestro esfuerzo, crear la
    # subrutina "trate_uno", cuyo intento es a buscar todos de los
    # anotaciónes que comienza con $query.

	# Versión de "trate_uno" para uso si fue alguna problema con
	# la base de datos.  Abra el archivo llamada el mismo de la
	# direción de traducción, y lea todos de sus líneas, escribiendo
	# ellos fue correspondido.

	sub trate_uno_archivo {
	    open(DICCIONARIO, $FORM{'DIRECTION'});
	    while (<DICCIONARIO>) {
		m|"([^"]*)","([^"]*)"|;
	        if (substr($1,0,$querylen) eq $query) {
	            print "<TR><TD VALIGN=TOP>", $1, "<TD>", $2, "\n";
	            $count ++;
		}
	        last if ($limit == $count);
	    }
            close DICCIONARIO;
	}

        # Versión de "trate_uno" para uso con una base de datos.
        # Pregunte la base de datos por anotaciónes correspondiendo
        # a $query, y escribelas.

	sub trate_uno_base {

	    $sth->execute($query . "%");

	    while ((@ary = $sth->fetchrow_array) > 0) {
		print "<TR><TD VALIGN=TOP>", $ary[0], "<TD>", $ary[1], "\n";
		$count ++;
		last if ($limit == $count);
	    }

	}

    # Usando uno de los versiónes de "trate_uno", buscar por anotaciónes
    # correspondidas en la diccionario.  Mientras que no tenemos anotaciónes,
    # borre uno letro de el fin de la palabra y trate una otra vez.

    LOOP: {
	do {
	    if (defined $sth) {
		&trate_uno_base;
	    } else {
		&trate_uno_archivo;
	    }
	    last LOOP if ($count > 0);
	    $querylen --;
	    $query = substr($query,0,$querylen);
	} while ($querylen > 0);
    }

    print "</TABLE>\n";
    #print "<P>Output truncated at $limit items\n" if ($limit == $count);
    print "<P>Salida truncado a $limit elementos\n" if ($limit == $count);

    # Asegure que la selección de dirección en el formulario siguiente
    # es el mismo como lo usado por la busca.

    if ($FORM{'DIRECTION'} eq "engspan") {
	$engsel = "SELECTED";
    } else {
	$spansel = "SELECTED";
    }

    print "<P><HR><P>\n";
}

# En todo caso, escribe un formulario HTML por el usuario usar a buscar
# por una otra palabra.

print qq|
Para buscar por una palabra, escribela en el cuadro blanco abajo,
selecciona la dirreción de traducción, y clic al botón.
El servidor de red replicará con todas de las palabras que
comienzen con las letras escritas, a un maximo de 20, por consiguiente
es posible a buscar por las palabras por el escribir solo de las letras
primeras.  Si ninguna palabra en el diccionario corresponde
a la entrada, el servidor replicará con las palabras mas semajante

<P>

To search for a word, type it in the white space below, select
a direction for translation, and click on the button.  The web
server will respond with all the words that begin with the letters
entered, to a maximum of 20, so it is possible to search for words
by entering only their initial letters.  If no word in the diccionary
matches the input, the server responds with the closest matching words.

| unless $quickresponse;

print qq|
<P><CENTER><FORM ACTION=index.cgi>
<INPUT TYPE=TEXT NAME=word>
<SELECT NAME=DIRECTION>
<OPTION $engsel VALUE=engspan>de ingles a español
<OPTION $spansel VALUE=spaneng>de español a ingles
</SELECT>
<INPUT TYPE=SUBMIT>
</FORM></CENTER>
|;

print qq|

<P><HR><P>

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

<P><CENTER><FORM ACTION=spanish.cgi>
<INPUT TYPE=HIDDEN NAME=URL VALUE=user>
<INPUT SIZE=50 TYPE=TEXT NAME=userURL VALUE="http://www.freesoft.org/">
<SELECT NAME=Translator>
<OPTION $engsel VALUE=newworld-es>de ingles a español
<OPTION $spansel VALUE=newworld-se>de español a ingles
</SELECT>
<INPUT TYPE=SUBMIT>
</FORM></CENTER>

<P>
Here are some documents I recommend for native English readers learning
Spanish.

<P><UL>
<LI><A HREF="spanish.cgi?URL=user&userURL=http://www.sgci.mec.es/uk/Pub/tecla.html&Translator=newworld-se">Tecla</A> - Texts for Teachers and Learners of Spanish
<LI><A HREF="spanish.cgi?URL=user&userURL=http://www.elmundo.es/&Translator=newworld-se">El Mundo</A> - Madrid Newspaper
<LI><A HREF="spanish.cgi?URL=user&userURL=http://www.freesoft.org/biblia/&Translator=newworld-se">La Biblia</A> (The Bible)
<LI><A HREF="spanish.cgi?URL=user&userURL=http://aix1.uottawa.ca/~jmruano/sombrerodetrespicos.html&Translator=newworld-se">El Sombrero de Tres Picos</A>
<LI><A HREF="spanish.cgi?URL=user&userURL=http://www.donquixote.com/&Translator=newworld-se">Don Quixote</A>
</UL>
| unless $quickresponse;

print qq|
</BODY>
</HTML>
|;
