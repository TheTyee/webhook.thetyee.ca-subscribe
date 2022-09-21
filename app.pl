#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::Util qw( url_escape );
use Try::Tiny;
use Data::Dumper;
use JSON qw(encode_json decode_json);
sub true () { JSON::true }
sub false () { JSON::false }
use Digest::MD5  qw(md5 md5_hex md5_base64);

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
   # unless ( $c->req->content->headers->host =~ $host ) {
    #    $c->render( text => "Forbidden", status => 403 );
     #   return;
   # }
   
   
   $c->res->headers->header('Access-Control-Allow-Origin' => '*'); 
    $c->res->headers->access_control_allow_origin('*');
    $c->res->headers->header('Access-Control-Allow-Methods' => 'GET, OPTIONS, POST, DELETE, PUT');
    $c->res->headers->header('Access-Control-Allow-Headers' => 'Content-Type' => 'application/x-www-form-urlencoded');
   
   #$c->res->headers->header('Access-Control-Allow-Origin' => 'https://preview.thetyee.ca');
   

    # Grab the post data
    my $email       = $c->param( 'email' )                      || '';
    my $md5email    = lc $email;
    $md5email = md5_hex ($email); 
    my $campaign    = url_escape $c->param( 'custom_campaign' ) || '';
    my $frequency   = $c->param( 'frequency' ) || '';
    my $national    = $c->param( 'custom_pref_enews_national' ) || '';
    my $weekly      = $c->param( 'custom_pref_enews_weekly' ) || '';
    my $daily       = $c->param( 'custom_pref_enews_daily' ) || '';
    my $events       = $c->param( 'custom_pref_enews_events' ) || '';
    my $whitegaze   =  $c->param( 'custom_pref_enews_white_gaze' ) || '';

my $ub = Mojo::UserAgent->new;

my $merge_fields = {
    P_S_CASL => 1,
    CAMPAIGN => $campaign,
    P_T_CASL => 1,
    P_E_NAT => $national,
    P_E_WEEKLY => $weekly,
    P_E_DAILY => $daily,
    P_E_EVENTS => $events,
    P_E_W_GAZE => $whitegaze
};
    
my $interests = {};

if ($national) { $interests -> {'34d456542c'} = \1 };
if ($daily) { $interests -> {'e96d6919a3'} = \1 };
if ($weekly) {$interests -> {'7056e4ff8d'} = \1 };

    # Post it to Mailchimp
    my $args = {
        email_address   => $email,,
        status =>       => 'subscribed',
        merge_fields => $merge_fields,
        interests => $interests
    };
        
        
       
     #   data =>"email,custom_pref_sponsor_enews,custom_pref_sponsor_casl,custom_campaign,custom_pref_tyeenews_casl,custom_pref_enews_$frequency,custom_pref_enews_national,custom_pref_enews_weekly,custom_pref_enews_daily,custom_pref_enews_events,custom_pref_enews_white_gaze^$email,1,1,$campaign,1,1,$national,$weekly,$daily,$events,$whitegaze"};
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
    my $URL = Mojo::URL->new('https://Bryan:' . $config->{"mc_key"} . '@us14.api.mailchimp.com/3.0/lists/' . $config->{"mc_listid"} . '/members/' . $md5email);
    my $tx = $ua->put( $URL => json => $args );
    my $js = $tx->result->json;
     app->log->debug( "code" . $tx->res->code);
      app->log->debug( Dumper( $js));
     app->log->debug( "unique email id" .  $js->{'unique_email_id'});
  
# check params at https://docs.mojolicious.org/Mojo/Transaction/HTTP
  
    if ($tx->res->code == 200 ) {
        $result = $tx->result->body;
        # Output response when debugging
      #          app->log->debug( Dumper( $tx  ) );
      #  app->log->debug( Dumper( $result ) );
        if ( $result =~ 'subscribed' ) {
            my $subscriberId = $js->{'unique_email_id'};
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
            app->log->debug("error: "  . $errorText);

    }
};

app->start;
