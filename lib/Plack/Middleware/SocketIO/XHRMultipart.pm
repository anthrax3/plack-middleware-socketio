package Plack::Middleware::SocketIO::XHRMultipart;

use strict;
use warnings;

use base 'Plack::Middleware::SocketIO::Base';

use Plack::Middleware::SocketIO::Handle;

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{boundary} ||= 'socketio';

    return $self;
}

sub name {'xhr-multipart'}

sub finalize {
    my $self = shift;
    my ($req, $cb) = @_;

    return $self->_finalize_stream($req, $cb) if $req->method eq 'GET';

    return unless $req->method eq 'POST' && $req->path =~ m{/(\d+)/send};

    return $self->_finalize_send($req, $1);
}

sub _finalize_stream {
    my $self = shift;
    my ($req, $cb) = @_;

    my $handle = $self->_build_handle($req->env->{'psgix.io'});
    return unless $handle;

    return sub {
        my $respond = shift;

        my $boundary = $self->{boundary};

        $handle->write(
            join "\x0d\x0a" => 'HTTP/1.1 200 OK',
            qq{Content-Type: multipart/x-mixed-replace;boundary="$boundary"},
            'Connection: keep-alive', '', ''
        );

        my $conn = $self->add_connection(on_connect => $cb);

        $handle->heartbeat_timeout(10);
        $handle->on_heartbeat(sub { $conn->send_heartbeat });

        $conn->on_write(
            sub {
                my $self = shift;
                my ($message) = @_;

                my $string = '';

                $string .= "Content-Type: text/plain\x0a\x0a";
                if ($message eq '') {
                    $string .= "-1--$boundary--\x0a";
                }
                else {
                    $string .= "$message\x0a--$boundary\x0a";
                }

                $handle->write($string);
            }
        );

        $conn->send_id_message($conn->id);

        $conn->connected unless $conn->is_connected;
    };
}

sub _finalize_send {
    my $self = shift;
    my ($req, $id) = @_;

    my $conn = $self->find_connection_by_id($id);
    return unless $conn;

    my $retval = [
        200,
        ['Content-Type' => 'text/plain', 'Transfer-Encoding' => 'chunked'],
        ["2\x0d\x0aok\x0d\x0a" . "0\x0d\x0a\x0d\x0a"]
    ];

    my $data = $req->body_parameters->get('data');

    $conn->read($data);

    return $retval;
}

sub _build_handle {
    my $self = shift;

    return Plack::Middleware::SocketIO::Handle->new(@_);
}

1;