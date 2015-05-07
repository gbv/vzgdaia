use Test::More;
use GBV::App::GVKDAIA;

my $app = GBV::App::GVKDAIA->new( 
    unapi => 'http://unapi.gbv.de/'
);

my $pica = $app->get_pica('gvk','786718889');
isa_ok $pica, 'PICA::Data';

my $daia = $app->get_daia_response('opac-de-18:ppn:62486362X');
ok delete $daia->{timestamp}, 'timestamp';
note explain $daia;

done_testing;
