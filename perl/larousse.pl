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

require DBI;

use Encode;

use lib "../libs";
use translators;

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
print "Content-type: text/html; charset=iso-8859-1\n\n";

# Escribe el encabezado HTML
print "<HTML>\n";
print "<HEAD>\n";
print "<TITLE>Larousse Gran Diccionario</TITLE>\n";
print "</HEAD>\n";
print "<BODY>\n";

#print "<CENTER><IMG SRC=\"header.gif\" WIDTH=317 HEIGHT=84></CENTER><P>\n";

# Inicialize varios variables

#my $query = lc decode("utf8", $FORM{'word'});		# La palabra por que buscamos
my $query = lc decode("iso-8859-1", $FORM{'word'});		# La palabra por que buscamos
my $querylen = length $query;		# La longitud de esta palabra

my $limit = 20;				# El máximo numero de respuestas
my $count = 0;				# El numero de respuestas hasta ahora

my $engsel;				# Cadenas indicandas la dirreción
my $spansel;				#   de transducción

@subs = (['&complab;', '<font face="Wingdings">q</font> '],
	 ['&idmlab;', '<font color="#238E1E">IDIOM</font> '],
	 ['&idmslab;', '<font color="#238E1E">IDIOMS</font> '],
	 ['&provlab;', '<font color="#238E1E">PROV</font> '],
	 ['&sime;', '~'],
	 ['&explab;', '<font color="#238E1E">EXPR</font> '],
	 ['&diamo;', '<br>&nbsp;&nbsp;<font face="Wingdings">t</font> '],
	 ['</RECORD>', ''],
	 ['</?LV[0-4]>', ''],
	 ['<CNJ>\\[(.+?)\\](.*?)</CNJ>', '<a href="larousse.pl?cnj=$1">Conjugaci\xf3n</a>$2'],
	 ['</?(CPB|EXB|ENT|PUN|PRP|TSL)>', ''],
	 ['<(BIT|CPA)>', '<B><I>'],
	 ['</(BIT|CPA)>', '</I></B>'],
	 ['<(/?)(EXA|FFA|IFA)>', '<$1B>'],
	 ['<(GEN|GEO|GRA|PSA|RTY|SEA|SFA|SVA)>', '<I><font color="#AC0508">'],
	 ['</(GEN|GEO|GRA|PSA|RTY|SEA|SFA|SVA)>', '</font></I>'],
	 ['<(/?)SEB>', '<$1I>'],
	 ['<(/?)HOM>', '<$1SUP>'],
	 ['<(HWD|VAR|PHV|VPR)>', '<br><font color="#473D76" size=+2><b>'],
	 ['<(HWD|VAR) CAT="PRD">', '<br><font color="#473D76" size=+2><b>'],
	 ['</(HWD|PHV|SHD|VPR|VAR)>', '</b></font>'],
	 ['<SHD>', '<font color="#473D76"><b>'],
	 ['<IPA>', '<font size="+2" face="Chambers Harrap IPA">'],
	 ['</IPA>', '</font>'],
# REF points to an ID tag in the dictionary
	 ['<REF NO="(.*?)">(.*?)</REF>', '<a href="$1">$2</a>'],
#	 ['<SC>(.+?)</SC>', lambda x: x.group(1).upper()],
	 ['<BOX TYP="USE">', '<br><br><br><table border="0" cellpadding="5" cellspacing="0" bgcolor="#EEEEEE" width="100%"><tr><td>'],
	 ['<BOX TYP="CLT">(<B>.+?</B>)', '<br><br><br><table border="0" cellpadding="5" cellspacing="0" bgcolor="#EEEEEE" width="100%"><tr><td>$1<br><br>'],
	 ['</BOX>', '</td></tr></table>'],
	 ['<N>(.+?)</N>', '<br>&nbsp;&nbsp;<b>$1</b>']);


# Si el usuario proveido un pregunta, busque por ella y escribe una respuesta

if (exists($FORM{'cnj'})) {
    my $dbh = DBI->connect("DBI:SQLite:conjug.db");
    $sth = $dbh->prepare("SELECT item FROM conjug WHERE num LIKE ?");
    $sth->execute($FORM{'cnj'});
    while ((@ary = $sth->fetchrow_array) > 0) {
	my $entry = $ary[0];
	print $entry;
    }
    exit;
}

if (not exists($FORM{'word'})) {
    print q|
<h1>An Error Occurred</h1>
<p>Word not specified</p>
</body>
</html>
|;
    exit;
}


my $table = $FORM{'DIRECTION'};	# Use la dirreción de transducción
				#   por el nombre de archivo o tabla
				#   en cual buscar

my $dbh_larousse;
my $sth_larousse;

print "<P><HR><CENTER><H3>$query</H3></CENTER>\n";

my $dbfile;
$dbfile = "esspan.db" if ($table eq "engspan");
$dbfile = "sespan.db" if ($table eq "spaneng");

$dbh_larousse = DBI->connect("DBI:SQLite:$dbfile");
#$sth_larousse = $dbh_larousse->prepare("SELECT DISTINCT entry FROM combined WHERE word LIKE ?");
$sth_larousse = $dbh_larousse->prepare("SELECT DISTINCT entry FROM entry JOIN iword USING (id) WHERE word LIKE ?");

# Dependiendo de el exito o falla de nuestro esfuerzo, crear la
# subrutina "trate_uno", cuyo intento es a buscar todos de los
# anotaciónes que comienza con $query.

sub trate_uno_larousse {

    $sth_larousse->execute(encode("iso-8859-1", $query) . "%");

    # the @subs array contains $-expressions, so we convert it to a string and eval it

    while ((@ary = $sth_larousse->fetchrow_array) > 0) {
	my $entry = $ary[0];
	foreach $sub (@subs) {
	    $r = $$sub[1];
	    $r =~ s/"/\\"/g;
	    $entry =~ s/$$sub[0]/'"'.$r.'"'/gee;
	}
	print $entry, "\n";
	$count ++;
	last if ($limit == $count);
    }

}

print "<CENTER><IMG SRC=\"larousse.jpg\" WIDTH=377 HEIGHT=126></CENTER><P>\n";

while ($querylen > 0 && $count == 0) {
    &trate_uno_larousse;

    $querylen --;
    $query = substr($query,0,$querylen);
} 

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

# En todo caso, escribe un formulario HTML por el usuario usar a buscar
# por una otra palabra.

print qq|
<P><CENTER><FORM ACTION=larousse.pl>
<INPUT TYPE=TEXT NAME=word>
<INPUT TYPE=HIDDEN NAME=DIRECTION VALUE=$FORM{'DIRECTION'}>
<INPUT TYPE=SUBMIT>
</FORM></CENTER>
|;

print qq|
</BODY>
</HTML>
|;
