package Mobirc::HTTPD::Router;
use strict;
use warnings;
use Carp;
use HTTP::Response;
use URI::Escape;
use Mobirc::Util;

sub route {
    my ($class, $c, $uri) = @_;
    croak 'uri missing' unless $uri;

    my $root = $c->{config}->{httpd}->{root};
    $root =~ s!/$!!;
    $uri =~ s!^$root!!;

    if ( $uri eq '/' ) {
        return 'index';
    }
    elsif ( $uri eq '/topics' ) {
        return 'topics';
    }
    elsif ( $uri =~ m{^/recent(?:\?t=\d+)?$} ) {
        return 'recent';
    }
    elsif ( $uri =~ m{^/keyword(-recent)?$} ) {
        return 'keyword', $1 ? true : false;
    }
    elsif ($uri =~ m{^/channels(-recent)?/([^?]+)}) {
        my $recent_mode = $1 ? true : false;
        my $channel_name = $2;
        return 'show_channel', $recent_mode, uri_unescape($channel_name);
    } else {
        # hook by plugins
        for my $code (@{$c->{global_context}->get_hook_codes('httpd')}) {
            my $response = $code->($c, $uri);
            if ($response) {
                return $response;
            }
        }

        # doesn't match.
        warn "dan the 404 not found: $uri";
        my $response = HTTP::Response->new(404);
        $response->content("Dan the 404 not found: $uri");
        return $response;
    }
}

1;
