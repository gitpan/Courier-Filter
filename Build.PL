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
        Error               => 0,
    },
    recommends      => {
        # Filter module requirements:
        Net::RBLClient      => 0,
        Digest::MD5         => 0,
        MIME::Tools         => '5.4',
        Mail::SPF::Query    => '1.991'
    },
    script_files    => [
        'pureperlfilter',
        'test-filter-module'
    ],
    sign            => 1
);

$build->create_build_script();

# $Id: Build.PL,v 1.1 2004/02/16 22:11:45 julian Exp $
# vim:tw=79
