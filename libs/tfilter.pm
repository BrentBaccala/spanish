#
# Perl package tfilter - "translator filter"
#
# Brent Baccala   baccala@freesoft.org
#
# This implements a subclass of HTML::Filter, that filters an HTML file and
# marks up every word with a hypertext link to translate it from Spanish
# to English.
#

use strict;

package tfilter;

use translators;

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

# Class local variables.  $translator actually does the translation.
# %TAGS is a hash that keeps an integer count of tags; incremented for
# a start tag, decremented for an end.  It should be zero (or
# non-existant) for any tag not currently "open".

my $translator;
my $linkprefix;

my %TAGS;

my $url;
my $baseURL;

#
# METHODS
#

# Constructor - invoke this class as tfilter->new($url, $translator, $linkprefix)
# where $url is the URL of the page being parsed, which we need to
# know to add a BASE tag, and for expanding relative URLs into absolutes,
# $translator is a key into hashes that tell how to translate words
# and $linkprefix is the prefix to be put before http hypertext links.

sub new {
    (my $class, $url, $translator, $linkprefix) = @_;
    my $self = $class->SUPER::new;

    $self->marked_sections(1);

    # We assume that the document's BASE is itself, until we find out otherwise.
    # Note that we send a BASE tag in the header, then look for another BASE
    # tag in the original document, which takes precendence.  Thus we might
    # end up with two BASE tags - Netscape, at least, seems to be able to
    # handle this.  The reason we have to put a BASE tag in right away is
    # in case there are relative links in the HEAD (like style sheets).

    $baseURL = $url;

    print qq'<HTML><HEAD><BASE href="$url"><SCRIPT LANGUAGE="javaScript">

function XzdY(word)
{
    myWin= window.open("$translator_url{$translator}" + word + "$translator_suffix{$translator}", "_translation", "scrollbars=yes,resizable=yes,toolbar=no,width=650,height=460");
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

    if ($TAGS{"head"} == 0 and $TAGS{"a"} == 0 and $TAGS{"script"} == 0) {

	# Perl... the APL of the 21st century.

	$_[0] =~ s|([\w&#;\x80-\xff]+)|&markuptext($1)|ego;

    }

    $self->SUPER::text(@_);
}

1;
