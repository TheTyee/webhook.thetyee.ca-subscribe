#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::Util qw( url_escape );
use Try::Tiny;
use Data::Dumper;


# Get the configuration
my $config = plugin 'JSONConfig';
app->secrets( [ $config->{'app_secret'} ] );

# Get a UserAgent
my $ua = Mojo::UserAgent->new;

# WhatCounts setup
my $API        = $config->{'wc_api_url'};
my $wc_list_id = $config->{'wc_listid'};
my $wc_realm   = $config->{'wc_realm'};
my $wc_pw      = $config->{'wc_password'};
my $secret     = $config->{'post_secret'};
my $host       = $config->{'host'};

post '/' => sub {
    my $c = shift;
    # Only accept POSTS from a specified host
    unless ( $c->req->content->headers->host =~ $host ) {
        $c->render( text => "Forbidden", status => 403 );
        return;
    }
    $c->res->headers->header('Access-Control-Allow-Origin' => '*');

    # Grab the post data
    my $email       = $c->param( 'email' ) || '';
    my $campaign    = url_escape $c->param( 'custom_campaign' ) || '';
    my $frequency   = $c->param( 'frequency' ) || '';
    my $national    = $c->param( 'custom_pref_enews_national' );
    my $weekly      = $c->param( 'custom_pref_enews_weekly' );
    my $daily       = $c->param( 'custom_pref_enews_daily' );

    # Post it to WhatCounts
    my $args = {
        r                     => $wc_realm,
        p                     => $wc_pw,
        list_id               => $wc_list_id,
        cmd                   => 'sub',
        #override_confirmation => '1',
        #force_sub             => '1',
        format                => '2',
        data =>
            "email,custom_campaign,custom_pref_tyeenews_casl,custom_pref_sponsor_casl,custom_pref_enews_$frequency,custom_pref_enews_national,custom_pref_enews_weekly,custom_pref_enews_daily^$email,$campaign,1,1,1,$national,$weekly,$daily"
    };
    # Output $args when debugging
    app->log->debug( Dumper( $args ) );
    my $result;
    my $tx = $ua->post( $API => form => $args );
    if ( my $res = $tx->success ) {
        $result = $res->body;
        # Output response when debugging
        app->log->debug( Dumper( $result ) );
        if ( $result =~ 'SUCCESS' ) {
            # Send 200 back to the request
            my $statusText = "<h2><span class='glyphicon glyphicon-check' aria-hidden='true'></span>&nbsp;Almost done</h2>";
            $statusText   .= "<p>Please check your inbox for an email from thetyee.ca containing a link to complete your subscription.</p>";
            $c->render( text => $statusText, status => 200 );
        } elsif ( $result =~ 'FAILURE' ) {
            $c->render( text => "$result", status => 500 );
        }
    }
    else {
        my ( $err, $code ) = $tx->error;
        $result = $code ? "$code response: $err" : "Connection error: " . $err->{'message'};
        # TODO this needs to notify us of a problem
        app->log->debug( Dumper( $result ) );
        # Send a 500 back to the request, along with a helpful message
        my $responseText = 'There was a problem with your subscription. Please e-mail helpfulfish@thetyee.ca to be added to the list.';
        $c->render( text => $responseText, status => 500 );
    }
};

app->start;
