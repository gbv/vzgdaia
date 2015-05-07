GVKDAIA is a minimal DAIA server for GBV union catalog.

## Development

Install Debian packages

    sudo apt-get install
        libplack-perl
        libxml-libxml-perl
        libhttp-tiny-perl
        libmodule-build-tiny-perl
        libtry-tiny-perl
        libyaml-libyaml-perl
        librdf-ns-perl
        librdf-trine-perl

Install additional Perl modules

    cpanm -l local --skip-satisfied PICA::Data RDF::aREF 
