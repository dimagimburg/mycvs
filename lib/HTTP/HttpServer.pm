#!/usr/bin/env perl
package HTTP::HttpServer;
use strict "vars"; use warnings;

#use experimental qw(smartmatch);
# ix for dima's perl
no if $] >= 5.018, warnings => "experimental::smartmatch";

# Global PERL libs & vars
use IO::Socket;
use MIME::Base64;
use feature qw(switch);
use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(main);

# Local imports
use lib qw(../);
use HTTP::HttpServerImpl;
use RepoManagement::Init;
use RepoManagement::Configuration qw($MYCVS_HTTP_PORT);
use UserManagement::Impl;

sub start_server {
    my $server = shift;
    die "$server->type MyCVS Server initialization failed" unless $server;
    die "Can't open socket. Do you have permissions to open port: ".($server->port)."\n" unless $server->socket;
    print "MyCVS WebServer listening on ".($server->port)."...\n";
    while (my $client=($server->socket)->accept()){
        print "Got Request from '".$client->peerhost."'.\n";
        my ($user, $pass, $header, $request, $data);
    
        ($request, $data) = HTTP::HttpServerImpl::get_request_params($server->type, $client);
        if (!defined($request) && !defined($data)) {
            $header = HTTP::HttpServerImpl::bad_request_message();
            HTTP::HttpServerImpl::send_response($server->type, $header, "", $client);
        }
        
        if ($request =~ /Authorization:\sBasic\s.+/) {
            my @auth_string = split (/\s/, $&);
            my $user_pass = decode_base64($auth_string[2]);
            ($user, $pass) = split (/:/, $user_pass);
        } else {
            print "Sending Auth request\n";
            $header = HTTP::HttpServerImpl::get_auth_message();
            HTTP::HttpServerImpl::send_response($server->type, $header, "", $client);
            next;
        }
        
        my ($request_type, $request_path, $request_version) = split (' ', $request);
        
        given($request_type) {
            when("POST") {
                print "Processing POST Request\n";
                ($header, $data) = HTTP::HttpServerImpl::process_post($request_path, $user, $pass, $data);
            }
            when("GET") {
                print "Processing GET Request\n";
                ($header, $data) = HTTP::HttpServerImpl::process_get($request_path, $user, $pass);
            }
            when("DELETE") {
                print "Processing DELETE Request\n";
                ($header, $data) = HTTP::HttpServerImpl::process_delete($request_path, $user, $pass);
            }
            default{
                # unsupported request
                $header = HTTP::HttpServerImpl::not_supported_message($request_type);
                $data = "";
            }
        }
        HTTP::HttpServerImpl::send_response($server->type, $header, $data, $client);
        print "==============Done processing================\n";
        close $client;
        next;
    }
}

sub main {
    my ($action) = @_;
    
    given($action) {
        when("start") {
            check_config();
            start_server(HTTP::HttpServerImpl::new('http', $MYCVS_HTTP_PORT));
        }
        default {
             die "Supported commans: [start]\n"
        }
    }
}

sub check_config {
    init_global();
    my $admin;
    my $password;
    if(UserManagement::Impl::check_if_admin_file_exists()){
        if(!UserManagement::Impl::check_if_admin_exists()){
            my $answer = 0;
            while($answer != 1){
                print "Please enter admin user name:\n";
                $admin = <STDIN>; chomp $admin;
                print "Please enter admin password:\n";
                $password = <STDIN>; chomp $password;
                $answer = UserManagement::Impl::create_user_record($admin,$password);
                if($answer == 0){
                    print "ERROR";
                } elsif($answer == 2) {
                    print "user already exists\n";
                }
            }
            UserManagement::Impl::create_admin_user($admin);
        }
    } else {
        print "error -> initialized incorrectly, admins.db no found.\n";
    }
}

1;
