#!/usr/bin/env perl
package HTTP::HttpServerRequests;
use strict "vars"; use warnings;

#use experimental qw(smartmatch);
# ix for dima's perl
no if $] >= 5.018, warnings => "experimental::smartmatch";

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(main);

# Internal libs
use lib qw(../);
use Cwd;
use RepoManagement::Init;

our %get_commands = {
                get_revision     => '/repo/revision',
                checkout         => '/repo/checkout',
                get_revisions    => '/repo/revisions',
                get_timestamp    => '/repo/timestamp',
                get_filelist     => '/repo/filelist',
                };
our %post_commands = {
                checkin          => '/repo/checkin',
                add_repo         => '/repo/add',
                add_user_to_repo => '/repo/user/add',
                unlock_file      => '/repo/unlock',
                create_user      => '/user/add'
                };
our %delete_commands = {
                delete_repo      => '/repo/del',
                delete_user      => '/user/del',
                remove_repo_perm => '/repo/user/del'
                };

#parse_config_line

sub send_http_request {
    my ($method, $command, $vars) = @_;
    my $http = HTTP::Tiny->new->(timeout => '10');
    my %options = parse_config_line(getcwd());
    my $uri = "http://$options{user}:$options{pass}@";
    $uri .= "$options{host}:$options{port}";
    $uri .= "$command?";
    $uri .= "$vars";
    my $response = $http->request($method,
                                  "http://$options{host}:$options{port}$command?$vars");
    
    return $response->{content} unless $response->{success};
}