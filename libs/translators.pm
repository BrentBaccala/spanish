#
# translators - maintain a table of on-line language translators
#
# exports lists of translator names - @se_translators and @es_translators
#         translator URL - %translator_url (keyed by name)
#         some translators need a suffix appended at the end of the URL - %translator_suffix

package translators;
use strict;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    @ISA         = qw(Exporter);
    @EXPORT      = qw(%translator_url %translator_suffix @se_translators @es_translators &se);
}

our @es_translators;
our @se_translators;
our %translator_url;
our %translator_suffix;

sub se {
    my ($name, $url, $suffix) = @_;

    push @se_translators, $name;
    $translator_url{$name} = $url;
    $translator_suffix{$name} = $suffix;

    return $name;
}

# Problems with accents
&se("Wordreference SE", "http://www.wordreference.com/es/en/translation.asp?spen=");
&se("Larousse SE", "http://www.larousse.com/en/dictionaries/spanish-english/");
&se("Diccionarios SE", "http://www.diccionarios.com/detalle.php?palabra=", "&dicc_55=on");
&se("Reverso SE", "http://dictionary.reverso.net/spanish-english/", "/forced");
&se("Collins SE", "http://www.collinsdictionary.com/dictionary/spanish-english/");
&se("WordMagic SE", "http://www.wordmagicsoft.com/dictionary/es-en/", ".php");
&se("BabLa SE", "http://en.bab.la/dictionary/spanish-english/");
&se("Ultralingua SE", "http://www.ultralingua.com/fr/onlinedictionary/dictionary#src_lang=Spanish&dest_lang=English&query=");
&se("Sensagent SE", "http://dictionnaire.sensagent.com/", "/es-en/");
&se("Linguee", "http://www.linguee.com/english-spanish/search?sourceoverride=none&source=spanish&query=");
&se("Eurocosm", "http://www.eurocosm.com/Eurocosm/AppEC/Pdcd/Phrasesearch2.asp?kw=", "&sl=E&styp=AND");

my $myurl = "http://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}";
$myurl =~ s:/[^/]*$::;  # Strip off final slash and script name after it

&se("local Larousse SE", "$myurl/larousse.pl?DIRECTION=spaneng&word=");
