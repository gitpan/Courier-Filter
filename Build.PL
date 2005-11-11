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
        Net::Address::IPv4::Local
                            => 0,
        MIME::Tools         => '5.4',
        IO::InnerFile       => '2.110',
        Digest::MD5         => 0,
        ClamAV::Client      => 0,
        File::Spec          => 0,
        Mail::SpamAssassin  => 0,
        Archive::Zip        => 0,
        Net::DNS            => 0
    },
    build_requires  => {
        # Build requirements:
        Test::Simple        => 0
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

# $Id: Build.PL 200 2005-11-11 02:46:35Z julian $
# vim:tw=79
