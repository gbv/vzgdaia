package GBV::App::GVKDAIA;
use v5.14;

use parent 'Plack::Component';
use Plack::Util::Accessor qw(unapi config);
use PICA::Data qw(pica_parser);
use Plack::Builder;
use Plack::Request;
use HTTP::Tiny;
use Try::Tiny;
use YAML::XS;
use POSIX qw(strftime);

# PSGI application
sub call {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);

    my $format = $req->param('format');
    $format and $format eq 'json'
        or return [400,[],['request format must be json']];

    my $daia = $self->get_daia_response( $req->param('id') );
    my $json = JSON->new->pretty->encode($daia);
    #$json = encode('utf8', $json);
    [ 200, ['Content-Type' => 'application/javascript'], [$json] ];
}

sub get_daia_response {
    my ($self, $id) = @_;

    my $daia = try {
        defined $id or $id ne ''  
            or die "missing identifier\n";
        # TODO: multiple ids
        $id =~ /^([a-z0-9-]+):ppn:([0-9Xx]+)$/
            or die "unknown identifier format\n";
        $self->get_daia($1,$2);
    } catch {
        chomp $_;
        { error => [{ message => $_ }] }
    };

    $daia->{version} = '1.0';
    $daia->{timestamp} = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime);

    return $daia;
}

sub get_daia {
    my ($self, $dbkey, $ppn) = @_;
    my $daia = {};

    # TODO: institution and picabase
    #institution => { content => 'GBV' }
    #if ($dbkey =~ /opac-(.+)/) {
    my $picabase;

    my $pica = $self->get_pica($dbkey, $ppn)
        or die "document not found\n";

    $pica->value('002@$0') !~ /^Oa/
        or die "online documents not supported\n";

    my $items = $self->daia_items($pica->holdings,"http://uri.gbv.de/document/$dbkey:epn:");
    @$items or die "no holdings found\n";

    $daia->{doc} = [{
        id => "http://uri.gbv.de/document/$dbkey:ppn:$ppn",
        item => $items,
        $picabase ? (href => $picabase."PPNSET?PPN=$ppn") : (),
    }];

    return $daia;
}

sub daia_items {
    my ($self, $holdings, $epnbase) = @_;
    my $items = [];
    foreach my $hold (@$holdings) {
        bless $hold, 'PICA::Data'; # FIXME
        my $iln = $hold->value('101@$a');
        my $it = $hold->items;
        foreach my $item (@{ $hold->items }) {
            bless $item, 'PICA::Data'; # FIXME
            my $ind = $item->value('209A$d'); # 209A $d : Ausleihindikator
            my $sst = $item->value('209A$f'); # Sonderstandort
            # TODO: Konvolutindikator (209A $c) und der Hinweis auf Mehrfachexemplare (209A $e)
            # TODO: Exemplarbezogener Kommentar
            push @$items, {
                label => $item->value('209A$a'), # Signatur
                $epnbase ? (id => $epnbase.$item->{_id}) : (),
                _iln => $iln,
                _sst => $sst,
                _ind => $ind,
            };
        }
    }
    return $items;
}

# get PICA::Data record via unAPI with dbkey and PPN
sub get_pica {
    my ($self, $dbkey, $ppn) = @_;
    my $url = $self->unapi . "?id=$dbkey:ppn:$ppn&format=pp"; 
    my $res = HTTP::Tiny->new->get($url);
    
    return $res->{success} ? do {
        my $pica = $res->{content};
        eval { pica_parser('plain', fh => \$pica, bless => 1 )->next }
    } : undef;
}

#
sub get_config {
    my ($self) = @_;
    # TODO: reload if modified
}

1;
