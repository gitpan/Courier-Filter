use Module::Build;

my $build = Module::Build->new(
    module_name     => 'Courier::Filter',
    dist_author     => 'Julian Mehnle <julian@mehnle.net>',
    license         => 'perl',
    requires        => {
        # Core requirements:
        perl                => '5.8',
        Encode              => 0,
        IO::Handle          => 0,
        IO::File            => 0,
        IO::Socket::UNIX    => 0,
        IO::Select          => 0,
        Error               => 0
    },
    recommends      => {
        # Filter module requirements:
        Net::RBLClient      => 0,
        Mail::SPF::Query    => '1.991',
        MIME::Tools         => '5.4',
        Digest::MD5         => 0,
        ClamAV::Client      => 0,
        File::Spec          => 0,
        Net::DNS            => 0,
        Net::Address::IPv4::Local
                            => 0
    },
    script_files    => [
        'bin/test-filter-module'
    ],
    install_path    => {
        lib                 => '/usr/share/courier-filter-perl/perl5'
    },
    create_makefile_pl
                    => 'passthrough',
    sign            => 1
);

$build->create_build_script();

# $Id: Build.PL,v 1.7 2005/01/17 19:33:59 julian Exp $
# vim:tw=79
