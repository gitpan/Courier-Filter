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
        File::Spec          => 0
    },
    script_files    => [
        'bin/test-filter-module'
    ],
    create_makefile_pl
                    => 'passthrough',
    sign            => 1
);

$build->create_build_script();

# $Id: Build.PL,v 1.5 2004/10/04 22:48:58 julian Exp $
# vim:tw=79
