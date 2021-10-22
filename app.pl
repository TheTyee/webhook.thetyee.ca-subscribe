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

helper get_subscriber_id => sub {
        my $self = shift;
        my $email = shift;
        my $search_args = {
            r                     => $wc_realm,
            p                     => $wc_pw,
            list_id               => $wc_list_id,
            cmd                   => 'findinlist',
            email                 => $email
        };
        my $result;
        my $r = $ua->post( $API => form => $search_args );
        if ( my $res = $r->success ) { $result = $res->body }
        else {
            my ( $err, $code ) = $r->error;
            $result
                = $code ? "$code response: $err" : "Connection error: $err";
        }
    # Just the subscriber ID please!
    $result =~ s/^(?<subscriber_id>\d+?)\s.*/$+{'subscriber_id'}/gi;
    chomp( $result );
    return $result;
};

post '/' => sub {
    my $c = shift;
    # Only accept POSTS from a specified host
    unless ( $c->req->content->headers->host =~ $host ) {
        $c->render( text => "Forbidden", status => 403 );
        return;
    }
    $c->res->headers->header('Access-Control-Allow-Origin' => '*');

    # Grab the post data
    my $email       = $c->param( 'email' )                      || '';
    my $campaign    = url_escape $c->param( 'custom_campaign' ) || '';
    my $frequency   = $c->param( 'frequency' ) || '';
    my $national    = $c->param( 'custom_pref_enews_national' );
    my $weekly      = $c->param( 'custom_pref_enews_weekly' );
    my $daily       = $c->param( 'custom_pref_enews_daily' );
    my $events       = $c->param( 'custom_pref_enews_events' );
    my $whitegaze   =  $c->param( 'custom_pref_enews_white_gaze' );

my $ub = Mojo::UserAgent->new;

    # Post it to WhatCounts
    my $args = {
        r                     => $wc_realm,
        p                     => $wc_pw,
        list_id               => $wc_list_id,
        cmd                   => 'sub',
        override_confirmation => '1',
        force_sub             => '1',
        format                => '2',
        data =>"email,custom_campaign,custom_pref_tyeenews_casl,custom_pref_enews_$frequency,custom_pref_enews_national,custom_pref_enews_weekly,custom_pref_enews_daily,custom_pref_enews_events,custom_pref_enews_white_gaze^$email,$campaign,1,1,$national,$weekly,$daily,$events,$whitegaze"
    };
    # Output $args when debugging
    app->log->debug( Dumper( $args ) );

    # Text and HTML response strings
    my $successText = 'Please check your inbox for an email from thetyee.ca containing a confirmation message';
    my $successHtml = '<h2><span class="glyphicon glyphicon-check" aria-hidden="true">';
    $successHtml   .= '</span>&nbsp;Almost done</h2>';
    $successHtml   .= '<p> ' . $successText . '</p>';
    my $errorText = 'There was a problem with your subscription. Please e-mail helpfulfish@thetyee.ca to be added to the list.';
    my $errorHtml = '<p>' . $errorText . '</p>';
    my $notification;
    my $result;
    my $tx = $ua->post( $API => form => $args );
    if ( my $res = $tx->success ) {
        $result = $res->body;
        # Output response when debugging
        app->log->debug( Dumper( $result ) );
        if ( $result =~ 'SUCCESS' ) {
            my $subscriberId = $c->get_subscriber_id( $email );
            # Send 200 back to the request
            $c->render( json => { 
                    text => $successText, 
                    html => $successHtml, 
                    subcriberId => $subscriberId, 
                    resultStr => $result }, 
                status => 200 );
$notification = $email . ", success. Campaign = $campaign";
            app->log->info($notification) unless $email eq 'api@thetyee.ca';
$ub->post($config->{'notify_url'} => json => {text => $notification }) unless $email eq 'api@thetyee.ca'; 
        } elsif ( $result =~ 'FAILURE' ) {
            $c->render( json => { 
                    text => $errorText, 
                    html => $errorHtml, 
                    resultStr => $result }, 
                status => 500 );
		$notification = $email . ", failure.  Campaign = $campaign, error: " .$errorText;
		app->log->info($email . ", failure \n") unless $email eq 'api@thetyee.ca';
        $ub->post($config->{'notify_url'} => json => {text => $notification }) unless $email eq 'api@thetyee.ca'; 
	}
    }
    else {
        my ( $err, $code ) = $tx->error;
        $result = $code ? "$code response: $err" : "Connection error: " . $err->{'message'};
        # TODO this needs to notify us of a problem
        app->log->debug( Dumper( $result ) );
        # Send a 500 back to the request, along with a helpful message
            $c->render( json => { 
                    text => $errorText, 
                    html => $errorHtml, 
                    resultStr => $result }, 
                status => 500 );
	app->log->info("error: "  . $errorText) unless $email eq 'api@thetyee.ca';
    }
};

app->start;
