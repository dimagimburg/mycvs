#!/bin/env perl
#
# repos.db file structure:
# root_dir1:admin_group1:users_group1
# root_dir2:admin_group2:users_group2
# location: $RepoManagement::Configuration::MYCVS_REPOS_DB
#
package RepoManagement::Commands;
use strict; use warnings;

# Perl libs & vars
use Exporter qw(import);
use Cwd;
our @ISA = qw(Exporter);
our @EXPORT = qw(
                create_repo delete_repo get_repositories get_repo_root_of_file
                create_admin_repo_group create_users_repo_group print_repositories
                );
# Internal libs
use lib qw(../);
use UserManagement::Commands;
use RepoManagement::Configuration;
use RepoManagement::Init;

# Create repository entry in DB
sub create_repo {
    my ($root_dir_path) = @_;
    # add entry to $RepoManagement::Configuration::MYCVS_REPOS_DB
    # if entry exists print error
    
}

# Removes repository entry from DB
sub delete_repo {
    my ($root_dir_path) = @_;
    # remove entry from $RepoManagement::Configuration::MYCVS_REPOS_DB
    # if not exists print error
}

# Returns list of all repositories root_dirs
sub get_repositories {
    
}

# print content of $RepoManagement::Configuration::MYCVS_REPOS_DB
# in pretty way. Example:
# RepoRoot: <path>, AdminGroup: <>, UsersGroup: <>
sub print_repositories {
    
}

# Returns repository root_dir of given file path
sub get_repo_root_of_file {
    my ($file_path) = @_;
    # Return root_dir of repository that given file belongs (hould be full file path)
    my $reporoot = get_repo_root($file_path);
    if (! defined($reporoot)) {
        return;
    } else {
        return $reporoot;
    }
}

# Creates repository's admin group
sub create_admin_repo_group {
    my ($repo_root_dir) = @_;
}

# Creates repository's user's group
sub create_users_repo_group {
    my ($repo_root_dir) = @_;
}

sub create_user_config {
    my $current_dir = getcwd();
    my ($host, $port, $reponame, $user, $pass);
    my $menu_flag = 1;
    my $answer;
    while ($menu_flag) {
        print "Please enter Repository server: "; $host = <STDIN>; chomp $host;
        print "Please enter Port number: (default 8080)"; $port = <STDIN>; chomp $port;
        print "Please enter Repository name: "; $reponame = <STDIN>; chomp $reponame;
        print "Please enter your username: "; $user = <STDIN>; chomp $user;
        print "Please enter your repo password: "; $pass = <STDIN>; chomp $pass;
        
        if (!defined($port) || $port eq "" ) {
        $port = 8080;
        }
        
        print "\n\nYou entered:\n\n";
        print "======================\n";
        print "Server:   $host:$port\n";
        print "RepoName: $reponame\n";
        print "UserName: $user\n";
        print "Password: $pass\n";
        print "Is it correct?[y/n] (y - default): ";
        
        $answer = <STDIN>; chomp $answer;
        if ($answer !~ '[Nn]') {
            $menu_flag = 0;
        }
    }

    save_client_config($host, $port, $reponame, $user, $pass, $current_dir);
}


1;