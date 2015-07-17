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
                get_remote_revisions get_remote_plain_diff
                get_remote_checkout post_remote_checkin
                get_remote_repo_content post_create_remote_repo
                delete_remote_repo delete_remote_repo_perm
                post_remote_repo_perm post_remote_add_user
                );

# Internal libs
use lib qw(../);
use HTTP::Tiny;
use RepoManagement::Init;
use VersionManagement::Impl;
use RepoManagement::Configuration qw($MYCVS_REMOTE_SUFFIX);

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
    my ($method, $command, $vars, $data) = @_;
    my $response;
    my $http = HTTP::Tiny->new(%http_options);
    my %options = parse_config_line(getcwd());
    my $uri = "http://$options{user}:$options{pass}@";
    
    $uri .= "$options{host}:$options{port}";
    $uri .= "$command?";
    $uri .= "$vars";
    
    if (!defined($data)) {
        $response = $http->request($method, $uri);
    } else {
        $response = $http->request(
                                $method,
                                $uri => {
                                    content => $data,
                                    headers => {
                                        "Content-Type" => "text/plain"
                                    }
                                }
                            );
    }
    
    print Dumper $response;
    return ($response->{content}, %{$response->{headers}}) if $response->{status} eq 200;
    die "Requested resourse not Found.\n" if $response->{status} eq 404;
    die $response->{content}."\n" if $response->{status} eq 409;
    die "You not Authorized\n" if $response->{status} eq 401;
    die "Action Forbidden. ".$response->{content}."\n" if $response->{status} eq 403;
    die "Not Implemented. ".$response->{content}."\n" if $response->{status} eq 501;
    die $response->{content}."\n" if $response->{status};
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
    my ($vars, $response, @revisions, %headers);
    
    if (! check_http_prerequisites($file_path)) {
        return;
    }
    
    my %options = parse_config_line($file_path);
    my $reporoot = get_repo_root($file_path);
    
    $file_path =~ s/${reporoot}//;
    $vars = "reponame=".$options{reponame}."&filename=".$file_path;
    
    ($response, %headers) = send_http_request('GET',$get_commands{get_all_revisions}, $vars);
    @revisions = convert_response_to_array($response);
    
    return @revisions;
}

sub get_remote_plain_diff {
    my ($file_path, $revision) = @_;
    my ($vars, $response, $temp_file_path, $local_file_path);
    my (@diff, @file_lines, %headers);
    if (! check_http_prerequisites($file_path)) {
        return;
    }
    my %options = parse_config_line($file_path);
    my $reporoot = get_repo_root($file_path);
    
    $local_file_path = $file_path;
    $temp_file_path = $file_path.'.'.$MYCVS_REMOTE_SUFFIX;
    $file_path =~ s/${reporoot}//;
    $vars = "reponame=".$options{reponame}."&filename=".$file_path;
    
    if (defined($revision)) {
        $vars .= "&revision=$revision";
    }
    
    ($response, %headers) = send_http_request('GET',$get_commands{get_revision}, $vars);
    return if ! defined($response);
    
    save_string_to_new_file($response, $temp_file_path);
    @diff = get_diff_on_two_files($temp_file_path, $local_file_path);
    print Dumper \@diff;
    delete_file($temp_file_path);
    return @diff;
}

sub get_remote_checkout {
    my ($file_path, $revision) = @_;
    my ($vars, $response, $temp_file_path, $local_file_path, @file_lines, %headers);
    
    if (! check_http_prerequisites($file_path)) {
        return;
    }
    my %options = parse_config_line($file_path);
    my $reporoot = get_repo_root($file_path);
    my $timestamp;
    
    $local_file_path = $file_path;
    $temp_file_path = $file_path.'.'.$MYCVS_REMOTE_SUFFIX;
    $file_path =~ s/${reporoot}//;
    $vars = "reponame=".$options{reponame}."&filename=".$file_path;
    
    if (defined($revision)) {
        $vars .= "&revision=$revision";
    }
    ($response, %headers) = send_http_request('GET',$get_commands{checkout}, $vars);
    return if ! defined($response);
    
    save_string_to_new_file($response, $temp_file_path);
    set_file_time($temp_file_path, $headers{'time-stamp'});
}

sub post_remote_checkin {
    my ($file_path) = @_;
    my ($data, $vars, $response, $local_file_path, @file_lines, %headers);
    
    if (! check_http_prerequisites($file_path)) {
        return;
    }
    my %options = parse_config_line($file_path);
    my $reporoot = get_repo_root($file_path);
    my $timestamp;
    
    $local_file_path = $file_path;
    $file_path =~ s/${reporoot}//;
    $vars = "reponame=".$options{reponame}."&filename=".$file_path;
    
    @file_lines = read_lines_from_file($local_file_path);
    if (! @file_lines) {
        return;
    }
    $data = join('', @file_lines);
    
    
    ($response, %headers) = send_http_request('POST', $post_commands{checkin}, $vars, $data);
    return if ! defined($response);
    return 1;
}

sub get_remote_repo_content {
    my ($data, $vars, $response, @file_lines, %headers);
    my $file_path = getcwd().'/.';
    if (! check_http_prerequisites($file_path)) {
        return;
    }
    my %options = parse_config_line($file_path);
    my $reporoot = get_repo_root($file_path);
    
    $vars = "reponame=".$options{reponame};
    
    ($response, %headers) = send_http_request('GET',
                                              $get_commands{get_filelist},
                                              $vars, $data);
    if (!defined($response)) {
        return;
    }
    
    return convert_response_to_array($response);
}

sub post_create_remote_repo {
    my ($reponame) = @_;
    my ($vars, $response, %headers);
    my $file_path = getcwd().'/.';
    
    if (! check_http_prerequisites($file_path)) {
        return;
    }
    
    $vars = "reponame=".$reponame;
       
    
    ($response, %headers) = send_http_request('POST', $post_commands{add_repo}, $vars);
}

sub delete_remote_repo {
    my ($reponame) = @_;
    my ($vars, $response, %headers);
    my $file_path = getcwd().'/.';
    
    if (! check_http_prerequisites($file_path)) {
        return;
    }
    
    $vars = "reponame=".$reponame;
       
    
    ($response, %headers) = send_http_request('DELETE',
                                              $delete_commands{delete_repo},
                                              $vars);
    return $reponame;
}

sub delete_remote_repo_perm {
    my ($reponame, $user) = @_;
    my ($vars, $response, %headers);
    my $file_path = getcwd().'/.';
    
    if (! check_http_prerequisites($file_path)) {
        return;
    }
    if (!defined($reponame) || !defined($user)) {
        return;
    }
    
    $vars = "reponame=".$reponame."&username=".$user;
    
    ($response, %headers) = send_http_request('DELETE',
                                              $delete_commands{remove_repo_perm},
                                              $vars);
    return $response;
}

sub post_remote_repo_perm {
    my ($user, $reponame) = @_;
    my ($vars, $response, %headers);
    my $file_path = getcwd().'/.';
    
    if (! check_http_prerequisites($file_path)) {
        return;
    }
    if (!defined($user) || !defined($reponame)) {
        return;
    }
    
    $vars = "username=".$user."&reponame=".$reponame;
    
    ($response, %headers) = send_http_request('POST',
                                              $post_commands{add_user_to_repo},
                                              $vars);
    return $response;
}

sub post_remote_add_user {
    my ($user, $passhash, $isAdmin) = @_;
    my ($vars, $response, %headers);
    my $file_path = getcwd().'/.';
    
    if (! check_http_prerequisites($file_path)) {
        return;
    }
    if (!defined($user) || !defined($passhash)) {
        return;
    }
    if (!defined($isAdmin)) {
        $isAdmin = 'false';
    }
    
    $vars = "username=".$user."&pass=".$passhash."&admin=".$isAdmin;
    
    ($response, %headers) = send_http_request('POST',
                                              $post_commands{create_user},
                                              $vars);
    return $response;
}



1;
