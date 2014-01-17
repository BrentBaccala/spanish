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
# Revision 1.18  2002/05/07 19:40:32  baccala
# Few changes to get the Queen Valera bible working
#
# Revision 1.17  2002/05/06 22:20:06  baccala
# Check version of URI modules we're using and modify
# arguments to uri_escape accordingly
#
# Revision 1.16  2001/07/10 17:45:38  baccala
# Add : / and . to the list characters we leave alone in URLs
#
# Revision 1.15  2001/06/03 05:22:51  baccala
# Nasty little bug - $1 and $2 got corrupted by the recursion
#
# Revision 1.14  2001/06/03 00:54:54  baccala
# Changed so that now we sent our own BASE tag at the beginning of the document,
# then another one if one is in the doc.  Netscape and Internet Explorer
# both seem able to handle two BASEs in the same doc, and it makes the script
# easier
#
# Revision 1.13  2001/05/13 05:04:47  baccala
# Escape link URLs.  spanish.cgi already has code in it to handle
# escape sequences in FORM data
#
# Revision 1.12  2001/05/13 04:08:34  baccala
# Fixed HREF rewrite to do any HREF attribute, not just A tags
#
# Revision 1.11  2001/05/13 03:22:25  baccala
# Fixed word matching code so that (hopefully) it's now correct
#
# Revision 1.10  2001/05/13 03:05:08  baccala
# Fix the A HREF rewrite so it handles unquoted HREF attributes correctly
#
# Improved word matching code, but it's still not quite perfect
#
# Revision 1.9  2001/05/13 01:56:06  baccala
# Leave the document's original BASE alone, just record it's value for
# rewriting URLs.  Since we also put in a BASE tag of our own, this means
# a document can end up with two BASE tags.  Yeow.  Netscape groks it, though.
#
# Revision 1.8  2001/05/12 20:48:45  baccala
# Make sure we get HREF's that don't use quotes, i.e. <A HREF=AB>
#
# Revision 1.7  2001/05/12 20:39:57  baccala
# Added $linkprefix - variable passed into constructor to select
# prefix to put before hypertext links
#
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
use URI::Escape;

# uri_escape handling changed in URI v1.13.  Figure out if we've got
# an older or newer version and act accordingly

my $old_uri_escape=0;
eval { URI->VERSION("1.13"); };
$old_uri_escape=1 if ($@);

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
my $baseURL;

#
# METHODS
#

# Constructor - invoke this class as tfilter->new($url, $transurl, $linkprefix)
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

    $self->marked_sections(1);

    # We assume that the document's BASE it itself, until we find out otherwise
    # Note that we send a BASE tag in the header, then look for another BASE
    # tag in the original document, which takes precendence.  Thus we might
    # end up with two BASE tags - Netscape, at least, seems to be able to
    # handle this.  The reason we have to put a BASE tag in right away is
    # in case there are relative links in the HEAD (like style sheets).

    $baseURL = $url;

    print qq'<HTML><HEAD><BASE href="$url"><SCRIPT LANGUAGE="javaScript">

function XzdY(word)
{
    myWin= window.open("$transurl" + word, "_translation", "scrollbars=yes,resizable=yes,toolbar=no,width=650,height=460");
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

    $absurl = URI->new_abs($linkurl, $baseURL);

    # We need to escape characters like "?" and "&" to prevent them
    # from being interpreted as part of the first URL.  The slash and
    # the period need to be escaped because the string ends up inside
    # a regular expression delineated by slashes

    if ($absurl->scheme eq "http") {
	if ($old_uri_escape) {
	    $absurl = $linkprefix . uri_escape($absurl, "^A-Za-z0-9:\\/\\.");
	} else {
	    $absurl = $linkprefix . uri_escape($absurl, "^A-Za-z0-9:/.");
	}
    }

    return $absurl;
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

    if ($tag eq "html" or $tag eq "head") {
	# We already did these in our header...
	return;
    }

    if ($tag eq "base") {

	$baseURL = $$attr{"href"};

    } elsif (grep { $_ eq "href" } @$attrseq) {

	$$attr{"href"} = &rewriteURL($$attr{"href"});

	# $origtext is what actually gets output, so reconstruct it from
	# the attribute list and hash

	$origtext = "<$tag ";
	$origtext .= join ' ', map { $_ . '="' . $$attr{$_} . '"'} @$attrseq;
	$origtext .= ">";

    } elsif ($tag eq "a") {

	# Special case here - an A tag without an HREF doesn't count as an A

	$TAGS{$tag} --;

    }

    if ($tag eq "body") {

	# I've got at least one set of documents (the Queen Valera bible)
	# that starts its BODY without ending its HEAD.  Sigh.

	$TAGS{"head"} = 0;

    }

    $self->SUPER::start($tag, $attr, $attrseq, $origtext);
}

# &end is called internally at an end tag.  In addition to decrementing
# TAGS, we want to catch the end of the HTML head and insert a BASE tag
# if one didn't already appear.

sub end {
    my $self = shift;
    my ($tag, $origtext) = @_;

    $TAGS{lc $tag} --    if ($TAGS{lc $tag} > 0);

    $self->SUPER::end(@_);
}

# &text is also called internally, for all non-tag text.  This includes text
# within an open tag i.e, the text of a hypertext link.  So we check to
# make sure we're not in the head of the document, or in an open hypertext
# link, then run a regex that matches each word in the text and calls
# &markuptext on it.  This function deals with special cases the
# regex couldn't figure out, mainly "&nbsp;".  Each word gets a
# hypertext link stuck on it.

sub markuptext {
    my ($text) = @_;

    return "" if ($text eq "");

    if ($text =~ m:^(.*)&nbsp;(.*)$:) {
	my $initial = $1;
	my $final = $2;
	return &markuptext($initial) . "&nbsp;" . &markuptext($final);
    }

    return $text if ($text =~ m:^[0-9]*$:);

    return "<A HREF=\"javascript:XzdY('$text')\">$text</A>";
}

sub text {
    my $self = shift;

    if ($TAGS{"head"} == 0 and $TAGS{"a"} == 0) {

	# Perl... the APL of the 21st century.

	$_[0] =~ s|([\w&#;]+)|&markuptext($1)|ego;

    }

    $self->SUPER::text(@_);
}

1;
