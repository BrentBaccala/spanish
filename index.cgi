#!/usr/bin/perl -- -*-perl-*-

# Programa por buscando en una diccionario Espa�ol/Ingles
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

my $limit = 20;				# El m�ximo numero de respuestas
my $count = 0;				# El numero de respuestas hasta ahora

my $engsel;				# Cadenas indicandas la dirreci�n
my $spansel;				#   de transducci�n

# Si el usuario proveido un pregunta, busque por ella y escribe una respuesta

if (exists($FORM{'word'})) {

    my $table = $FORM{'DIRECTION'};	# Use la dirreci�n de transducci�n
					#   por el nombre de archivo o tabla
					#   en cual buscar

    my $dbh;				# Asa de la base de datos
    my $sth;				# Asa de nuestro comando a la base

    print "<P><HR><CENTER><H3>$query</H3></CENTER>\n";
    print "<TABLE>\n";

    # Trate a usar paquete DBI y conecte a la base de datos "diccionario".
    # Quiero este andar en una cl�usula "eval" en caso de falla, cuando
    # retrocederemos a el uso de el archivo directamente.

    eval {
	use DBI;

	$dbh = DBI->connect("DBI:mysql:diccionario");
	$sth = $dbh->prepare("SELECT word, definition FROM $table WHERE word LIKE ?");
    };

    # Dependiendo de el exito o falla de nuestro esfuerzo, crear la
    # subrutina "trate_uno", cuyo intento es a buscar todos de los
    # anotaci�nes que comienza con $query.

	# Versi�n de "trate_uno" para uso si fue alguna problema con
	# la base de datos.  Abra el archivo llamada el mismo de la
	# direci�n de traducci�n, y lea todos de sus l�neas, escribiendo
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

        # Versi�n de "trate_uno" para uso con una base de datos.
        # Pregunte la base de datos por anotaci�nes correspondiendo
        # a $query, y escribelas.

	sub trate_uno_base {

	    $sth->execute($query . "%");

	    while ((@ary = $sth->fetchrow_array) > 0) {
		print "<TR><TD VALIGN=TOP>", $ary[0], "<TD>", $ary[1], "\n";
		$count ++;
		last if ($limit == $count);
	    }

	}

    # Usando uno de los versi�nes de "trate_uno", buscar por anotaci�nes
    # correspondidas en la diccionario.  Mientras que no tenemos anotaci�nes,
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

    # Asegure que la selecci�n de direcci�n en el formulario siguiente
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

print "Para buscar por una palabra, escribela en el cuadro blanco abajo,\n";
print "selecciona la dirreci�n de traducci�n, y clic al bot�n.\n";
print "El servidor de red replicar� con todas de las palabras que\n";
print "comienzen con las letras escritas, a un maximo de 20, por consiguiente\n";
print "es posible a buscar por las palabras por el escribir solo de las letras\n";
print "primeras.  Si ninguna palabra en el diccionario corresponde\n";
print "a la entrada, el servidor replicar� con las palabras mas semajante\n";

print "<P>\n";

print "To search for a word, type it in the white space below, select\n";
print "a direction for translation, and click on the button.  The web\n";
print "server will respond with all the words that begin with the letters\n";
print "entered, to a maximum of 20, so it is possible to search for words\n";
print "by entering only their initial letters.  If no word in the diccionary\n";
print "matches the input, the server responds with the closest matching words.\n";

print "<P><CENTER><FORM ACTION=index.cgi>\n";
print "<INPUT TYPE=TEXT NAME=word>\n";
print "<SELECT NAME=DIRECTION>\n";
print "<OPTION $engsel VALUE=engspan>de ingles a espa�ol\n";
print "<OPTION $spansel VALUE=spaneng>de espa�ol a ingles\n";
print "</SELECT>\n";
print "<INPUT TYPE=SUBMIT>\n";
print "</FORM></CENTER>\n";

print "<P><HR><P>\n";

print "Tambien, es posible a usar el diccionario v�a a una programa que\n";
print "ponga hiperv�nculos a todas de las palabras de una p�gina de red.\n";
print "El hacer clic a una de las palabras causa el aparici�n de una\n";
print "ventana con la traducci�n de la palabra.  Para usar esta capacidad\n";
print "introduce abajo la dirreci�n de red que quieras leer, selecciona\n";
print "la dirreci�n de traducci�n, y clic al bot�n.\n";

print "<P>\n";

print "It is also possible to use the diccionary via a script that puts\n";
print "hyperlinks on all the words on a web page.  Clicking on one of the\n";
print "words causes a popup window to appear with the translation of the\n";
print "word.  To use this feature, enter below the URL of the web page\n";
print "you want to read, select the dirrection of translation, and click\n";
print "the button.\n";

print "<P><CENTER><FORM ACTION=spanish.cgi>\n";
print "<INPUT TYPE=HIDDEN NAME=URL VALUE=user>\n";
print "<INPUT SIZE=50 TYPE=TEXT NAME=userURL VALUE=\"http://www.freesoft.org/\">\n";
print "<SELECT NAME=Translator>\n";
print "<OPTION $engsel VALUE=newworld-es>de ingles a espa�ol\n";
print "<OPTION $spansel VALUE=newworld-se>de espa�ol a ingles\n";
print "</SELECT>\n";
print "<INPUT TYPE=SUBMIT>\n";
print "</FORM></CENTER>\n";

print "</BODY>\n";
print "</HTML>\n";
