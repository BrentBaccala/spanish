
package tfilter;

use POSIX qw(locale_h);

use locale;
setlocale(LC_CTYPE, "spanish");

require HTML::Filter;
use vars qw(@ISA);
@ISA = qw(HTML::Filter);

my %TAGS;

my $basesent=0;
my $scriptsent=0;

my $transurl = "http://vyger.freesoft.org/cgi-bin/translator.cgi";

my $script = qq! <SCRIPT LANGUAGE="javaScript">

function Tell(url) 
{
    myWin= window.open(url, "_", "scrollbars=yes,resizable=yes,toolbar=no,width=460,height=460");
}

</SCRIPT>
!;

sub start {
    my $self = shift;
    my ($tag, $attr, $attrseq, $origtext) = @_;

    if (not exists $TAGS{lc $tag}) {
	$TAGS{lc $tag} = 1;
    } else {
	$TAGS{lc $tag} ++;
    }

    if (tag eq "base") {
	# Add tag
    }

    $self->SUPER::start(@_);
}

sub end {
    my $self = shift;
    my ($tag, $origtext) = @_;

    if ((lc $tag) eq "head") {
	if (not $basesent) {
	    print "<base>\n";
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

sub text {
    my $self = shift;

    if ($TAGS{"head"} == 0 and $TAGS{"a"} == 0) {

	$_[0] =~ s|\b(?<![&#])(\w+)\b|<A HREF="javascript:Tell('$transurl?urltext=\1&lp=es_en')">\1</A>|go;

    }

    $self->SUPER::text(@_);
}
