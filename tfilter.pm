#
# Perl package tfilter - "translator filter"
#
# Brent Baccala   baccala@freesoft.org
#
# This implements a subclass of HTML::Filter, that filters an HTML file and
# marks up every word with a hypertext link to translate it from Spanish
# to English.
#
# $Log: tfilter.pm,v $
# Revision 1.6  2001/04/26 15:33:26  baccala
# Also added a $linkurl argument to the constructor.
#
# Revision 1.5  2001/04/26 15:11:04  baccala
# Moved setting of $transurl into class constructor, where it gets
# passed as an argument now.  Allows setting (from parent) of exact
# URL used for translation.
#
# Revision 1.4  2001/04/09 05:26:18  baccala
# Fixed relative references in the document head by putting our BASE tag
# in at the very start of the document.  The code's a lot cleaner, at the
# cost of introducing a big assumption - that the original document has
# a HEAD section
#
# Revision 1.3  2001/04/09 04:11:39  baccala
# Added explanatory comments; improved the link handling to rewrite
# relative URLs as absolutes
#
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

my $transurl;
my $linkprefix;

my %TAGS;

my $url;
my $basesent=0;
my $scriptsent=0;

#
# METHODS
#

# Constructor - invoke this class as tfilter->new($url, $transurl, $linkprefix),
# where $url is the URL of the page being parsed, which we need to
# know to add a BASE tag, and for expanding relative URLs into absolutes,
# $transurl is the prefix to be put before the word in a transation link,
# and $linkprefix is the prefix to be put before http hypertext links.

sub new {
    my ($class, $urlin, $transurlin, $linkprefixin) = @_;
    my $self = $class->SUPER::new;

    $url = $urlin;
    $transurl = $transurlin;
    $linkprefix = $linkprefixin;

    print qq'<HTML><HEAD><BASE href="$url"><SCRIPT LANGUAGE="javaScript">

function Tell(url) 
{
    myWin= window.open(url, "_translation", "scrollbars=yes,resizable=yes,toolbar=no,width=650,height=460");
}

</SCRIPT>';

    return $self;
}

# &start is called internally (by our superclass HTML::Filter) whenever
# a start tag is seen.  In addition to keeping track of the tags (in TAGS),
# we want to rewrite hypertext links so they'll go through our translator.

sub rewriteURL {
    my ($linkurl) = @_;
    my $absurl;

    $absurl = URI->new_abs($linkurl, $url);

    if ($absurl->scheme eq "http") {
	$absurl = $linkprefix . $absurl;
    }

    return "href=\"$absurl\"";
}

sub start {
    my $self = shift;
    my ($tag, $attr, $attrseq, $origtext) = @_;

    $tag = lc $tag;

    if (not exists $TAGS{$tag}) {
	$TAGS{$tag} = 1;
    } else {
	$TAGS{$tag} ++;
    }

    if ($tag eq "html" or $tag eq "head" or $tag eq "base") {
	# We already did these in our header...
	return;
    }

    if ($tag eq "a") {

	# The superclass's &start only prints $origtext, so that's the
	# only argument we modify.

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

	$_[0] =~ s|\b(?<![&#])(\w+)\b|<A HREF="javascript:Tell('$transurl$1')">\1</A>|go;

    }

    $self->SUPER::text(@_);
}

1;
