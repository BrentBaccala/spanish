#
# Perl package tfilter - "translator filter"
#
# Brent Baccala   baccala@freesoft.org
#
# This implements a subclass of HTML::Filter, that filters an HTML file and
# marks up every word with a hypertext link to translate it from Spanish
# to English.
#
# $Log$
#

use strict;

package tfilter;

require URI;

# This makes our package a subclass of HTML::Filter, via the @ISA array,
# which specifies superclasses.  Perl... the FORTH of the 21st century.

require HTML::Filter;
use vars qw(@ISA);
@ISA = qw(HTML::Filter);

# This sets the international locale to "spanish", which changes the
# regular expression "\w" (word-constituent character) to include
# ISO 8859 accented characters.

use POSIX qw(locale_h);
use locale;
setlocale(LC_CTYPE, "spanish");

# Class locale variables.  $transurl is the CGI script that actually does
# the translation.  %TAGS is a hash that keeps an integer count of tags;
# incremented for a start tag, decremented for an end.  It should be zero
# (or non-existant) for any tag not currently "open".

my $transurl = "http://vyger.freesoft.org/cgi-bin/translator.cgi";

my %TAGS;

my $url;
my $basesent=0;
my $scriptsent=0;

my $script = '<SCRIPT LANGUAGE="javaScript">

function Tell(url) 
{
    myWin= window.open(url, "_translation", "scrollbars=yes,resizable=yes,toolbar=no,width=460,height=460");
}

</SCRIPT>';

#
# METHODS
#

# Constructor - invoke this class as tfilter->new($url), where $url is
# the URL of the page being parsed, which we need to know to add a BASE
# tag, and for expanding relative URLs into absolutes.

sub new {
    my ($class, $urlin) = @_;
    my $self = $class->SUPER::new;

    $url = $urlin;

    $self;
}

# &start is called internally (by our superclass HTML::Filter) whenever
# a start tag is seen.  In addition to keeping track of the tags (in TAGS),
# we want to rewrite hypertext links so they'll go through our translator.
# The superclass's &start only prints $origtext, so that's the only argument
# we modify.

sub rewriteURL {
    my ($linkurl) = @_;
    my $absurl;

    $absurl = URI->new_abs($linkurl, $url);

    if ($absurl->scheme eq "http") {
	$absurl = "http://vyger.freesoft.org/cgi-bin/spanish.cgi?$absurl";
    }

    return "href=\"$absurl\"";
}

sub start {
    my $self = shift;
    my ($tag, $attr, $attrseq, $origtext) = @_;

    if (not exists $TAGS{lc $tag}) {
	$TAGS{lc $tag} = 1;
    } else {
	$TAGS{lc $tag} ++;
    }

    if ((lc $tag) eq "base") {
	# Add tag
    }

    if ((lc $tag) eq "a") {
	$origtext =~ s!href="([^"]*)"!&rewriteURL("$1")!eio;
    }

    $self->SUPER::start($tag, $attr, $attrseq, $origtext);
}

# &end is called internally at an end tag.  In addition to decrementing TAGS,
# we want to catch the end of the HTML head and insert some javascript,
# as well as a BASE tag if one didn't already appear.

sub end {
    my $self = shift;
    my ($tag, $origtext) = @_;

    if ((lc $tag) eq "head") {
	if (not $basesent) {
	    print "<base href=\"$url\">\n";
	    $basesent = 1;
	}
	if (not $scriptsent) {
	    print $script;
	    $scriptsent = 1;
	}
    }

    $TAGS{lc $tag} --;

    $self->SUPER::end(@_);
}

# &text is also called internally, for all non-tag text.  This includes text
# within an open tag i.e, the text of a hypertext link.  So we check to
# make sure we're not in the head of the document, or in an open hypertext
# link, then run that funny regex that matches each word in the text,
# excluding those preceeded by "&" or "#" and therefore probably HTML
# specials.  Each word that matches gets a hypertext link stuck on it.

sub text {
    my $self = shift;

    if ($TAGS{"head"} == 0 and $TAGS{"a"} == 0) {

	# Perl... the APL of the 21st century.

	$_[0] =~ s|\b(?<![&#])(\w+)\b|<A HREF="javascript:Tell('$transurl?urltext=\1&lp=es_en')">\1</A>|go;

    }

    $self->SUPER::text(@_);
}
