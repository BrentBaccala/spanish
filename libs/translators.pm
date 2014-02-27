#
# translators - maintain a table of on-line language translators
#
# exports lists of translator names - @translators
#         translator URL - %translator_url (keyed by name and direction)
#         some translators need a suffix appended at the end of the URL - %translator_suffix

package translators;
use strict;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    @ISA         = qw(Exporter);
    @EXPORT      = qw(%translator_url %translator_suffix @translators);
}

our @translators;
our %translator_url;
our %translator_suffix;

sub se {
    my ($name, $url, $suffix) = @_;

    # Add $name to @translators unless it's already there
    if (not scalar grep {$_ eq $name} @translators) {
	push @translators, $name;
    }

    $translator_url{$name . 'SE'} = $url;
    $translator_suffix{$name . 'SE'} = $suffix;
}

sub es {
    my ($name, $url, $suffix) = @_;

    # Add $name to @translators unless it's already there
    if (not scalar grep {$_ eq $name} @translators) {
	push @translators, $name;
    }

    $translator_url{$name . 'ES'} = $url;
    $translator_suffix{$name . 'ES'} = $suffix;
}

# Problems with accents
&se("Wordreference", "http://www.wordreference.com/es/en/translation.asp?spen=");
&se("Larousse", "http://www.larousse.com/en/dictionaries/spanish-english/");
&se("Diccionarios", "http://www.diccionarios.com/detalle.php?palabra=", "&dicc_55=on");
&se("Reverso", "http://dictionary.reverso.net/spanish-english/", "/forced");
&se("Collins", "http://www.collinsdictionary.com/dictionary/spanish-english/");
&se("WordMagic", "http://www.wordmagicsoft.com/dictionary/es-en/", ".php");
&se("BabLa", "http://en.bab.la/dictionary/spanish-english/");
&se("Ultralingua", "http://www.ultralingua.com/fr/onlinedictionary/dictionary#src_lang=Spanish&dest_lang=English&query=");
&se("Sensagent", "http://dictionnaire.sensagent.com/", "/es-en/");
&se("Linguee", "http://www.linguee.com/english-spanish/search?sourceoverride=none&source=spanish&query=");
&se("Eurocosm", "http://www.eurocosm.com/Eurocosm/AppEC/Pdcd/Phrasesearch2.asp?kw=", "&sl=E&styp=AND");

&es("Wordreference", "http://www.wordreference.com/es/translation.asp?tranword=");
&es("Larousse", "http://www.larousse.com/en/dictionaries/english-spanish/");
&es("Diccionarios", "http://www.diccionarios.com/detalle.php?palabra=", "&dicc_54=on");
&es("Reverso", "http://dictionary.reverso.net/english-spanish/", "/forced");
&es("Collins", "http://www.collinsdictionary.com/dictionary/english-spanish/");
&es("WordMagic", "http://www.wordmagicsoft.com/dictionary/en-es/", ".php");
&es("BabLa", "http://en.bab.la/dictionary/english-spanish/");
&es("Ultralingua", "http://www.ultralingua.com/fr/onlinedictionary/dictionary#src_lang=English&dest_lang=Spanish&query=");
&es("Sensagent", "http://dictionnaire.sensagent.com/", "/en-es/");
&es("Linguee", "http://www.linguee.com/english-spanish/search?sourceoverride=none&source=english&query=");
&es("Eurocosm", "http://www.eurocosm.com/Eurocosm/AppEC/Pdcd/Phrasesearch2.asp?kw=", "&sl=E&styp=AND");

if (-r "data") {
    my $myurl = "http://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}";
    $myurl =~ s:/[^/]*$::;  # Strip off final slash and script name after it

    &se("local Larousse", "$myurl/larousse.pl?DIRECTION=spaneng&word=");
    &es("local Larousse", "$myurl/larousse.pl?DIRECTION=engspan&word=");
}

1;
