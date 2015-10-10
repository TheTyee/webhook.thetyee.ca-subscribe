Micro app to proxy AJAX e-mail subscription forms
---------------------------------------------------

v1.0.0

## Description

A simple proxy between Web forms and WhatCounts that doesn't leak API keys, exposed as a very simple Web service.

## Endpoints

* `/subscribe/`
  * Accepts:
    * email [required]
    * frequency [optional]
    * custom_campaign [optional]
  * Returns:
    * 200 OK
    * 500 Failure

## Install requirements

* A relatively "modern" version of Perl (5.20+ recommended)

### Installation

#### 0. Install Perl

These days, I recommend using [plenv](https://github.com/tokuhirom/plenv) to install a local version of Perl that doesn't muck with your system perl binary.

To do that, just:

`git clone git://github.com/tokuhirom/plenv.git ~/.plenv`

`echo 'export PATH="$HOME/.plenv/bin:$PATH"' >> ~/.bash_profile`

`echo 'eval "$(plenv init -)"' >> ~/.bash_profile`

`exec $SHELL -l`

`git clone git://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/`

`plenv install 5.20.0`

#### 1. Get the source / sub-modules

First, fork the repository so that you have your own copy. Then:

`git clone git@github.com:TheTyee/webhook.thetyee.ca-subscribe.git`

`git checkout develop` (Always work on the `develop` branch while developing!)

#### 3. Install the Perl dependencies

From here, if you don't have a global install of [cpanm](https://github.com/miyagawa/cpanminus), you'll want to install that with the command `plenv install-cpanm` (this assumes that you installed Perl with `plenv` as described above).

Next, to localize the libraries that the project requires, you'll want to install [Carton](https://github.com/perl-carton/carton):

`cpanm install Carton`

Then install the project requirements into a local directory so that you know you're using the right ones:

`cd webhook.thetyee.ca-subscribe.git`

`carton install`

When that finishes, you should have a `local` directory full of libraries.

#### 4. Get and edit the configuration files

Get them from the secret repository!

You'll need:
 
* app.development.json

#### 5. Start the development server

At this point you should have everything needed to start developing. Run the app in development mode with:

`carton exec morbo app.pl`

And, if everything worked, you should see:

`Server available at http://127.0.0.1:3000.`

### 6. Bask in the glory of local development!

Do NOT pass go. Do NOT collect $200. Just enjoy the moment. 

The development server will reload the app when any of the files are edited. So you can just edit the template files and the single-file application to your needs and refresh your browser to see the results. 

Errors will be written to your terminal.

## Updating the preview site

### 1. Updating the app

First, you need to update the files on the server. 

Using terminal, log in to the server (make sure you're on the right server, with the right user!).

`cd preview.webhooks.thetyee.ca/www/subscribe/`

Make sure you're on the develop branch: 

`git checkout develop`

Then sync up!

`git pull`

Then, redeploy the application:

`MOJO_MODE='preview' MOJO_LOG_LEVEL='debug' hypnotoad app.pl`

MOJE_MODE tells the app which config file to use. I.e. `MOJO_MODE='preview'` will look for the app.preview.json file. 

