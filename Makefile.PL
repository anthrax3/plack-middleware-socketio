#!/usr/bin/env perl

use 5.008007;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my ($mm) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME         => 'Plack::Middleware::SocketIO',
    VERSION_FROM => 'lib/Plack/Middleware/SocketIO.pm',
    ABSTRACT     => 'Socket.IO Plack middleware',
    AUTHOR       => 'Viacheslav Tykhanovskyi <vti@cpan.org>',

    ($mm < 6.3002 ? () : ('LICENSE' => 'artistic_2')),

    (   $mm < 6.46
        ? ()
        : ( META_MERGE => {
                x_deprecated => 1,
                requires  => {perl => '5.008007'},
                resources => {
                    license => 'http://dev.perl.org/licenses/',
                    repository =>
                      'http://github.com/vti/plack-middleware-socketio',
                    bugtracker =>
                      'http://github.com/vti/plack-middleware-socketio/issues'
                },
                no_index => {directory => [qw/t/]}
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {}
            },
        )
    ),

    PREREQ_PM => {
        'AnyEvent'            => 0,
        'JSON'                => 0,
        'Plack'               => 0,
        'Protocol::WebSocket' => 0.009001,
        'Scalar::Util'        => 0,
        'Try::Tiny'           => 0
    },
    test => {TESTS => 't/*.t t/*/*.t'}
);
