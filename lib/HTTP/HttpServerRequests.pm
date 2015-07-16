#!/usr/bin/env perl
package HTTP::HttpServerRequests;
use strict "vars"; use warnings;

#use experimental qw(smartmatch);
# ix for dima's perl
no if $] >= 5.018, warnings => "experimental::smartmatch";

use File::Basename;
use Cwd;
use Data::Dumper;
use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(
                get_remote_revisions
                );

# Internal libs
use lib qw(../);
use HTTP::Tiny;
use RepoManagement::Init;


our %http_options = (
                    timeout => 10
                    );
our %get_commands = (
                get_revision     => '/repo/revision',
                checkout         => '/repo/checkout',
                get_all_revisions=> '/repo/revisions',
                get_timestamp    => '/repo/timestamp',
                get_filelist     => '/repo/filelist',
                );
our %post_commands = (
                checkin          => '/repo/checkin',
                add_repo         => '/repo/add',
                add_user_to_repo => '/repo/user/add',
                unlock_file      => '/repo/unlock',
                create_user      => '/user/add'
                );
our %delete_commands = (
                delete_repo      => '/repo/del',
                delete_user      => '/user/del',
                remove_repo_perm => '/repo/user/del'
                );

#parse_config_line

sub send_http_request {
    my ($method, $command, $vars) = @_;
    my $http = HTTP::Tiny->new(%http_options);
    my %options = parse_config_line(getcwd());
    my $uri = "http://$options{user}:$options{pass}@";
    
    $uri .= "$options{host}:$options{port}";
    $uri .= "$command?";
    $uri .= "$vars";
    my $response = $http->request($method, $uri);
    #print Dumper $response;
    return $response->{content} if $response->{status} eq 200;
}

sub check_http_prerequisites {
    my ($file_path) = @_;
    if (!defined($file_path)) {
        return 0;
    }
    
    my %options = parse_config_line($file_path);
    
    if (!defined($options{reponame})) {
        return 0;
    }
    return 1;
}

sub convert_response_to_array {
    my ($response) = @_;
    return split('\n', $response);
}

sub get_remote_revisions {
    my ($file_path) = @_;
    my ($vars, $response, @revisions);
    
    if (! check_http_prerequisites($file_path)) {
        return;
    }
    
    my %options = parse_config_line($file_path);
    my $reporoot = get_repo_root($file_path);
    
    $file_path =~ s/${reporoot}//;
    $vars = "reponame=".$options{reponame}."&filename=".$file_path;
    
    $response = send_http_request('GET',$get_commands{get_all_revisions}, $vars);
    @revisions = convert_response_to_array($response);
    
    return @revisions;
}







