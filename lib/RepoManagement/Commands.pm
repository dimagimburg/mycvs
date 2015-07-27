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
                create_user_config backup_repo restore_repo
                backup_db restore_db list_repo_backups list_db_backups
                );
# Internal libs
use lib qw(../);
use RepoManagement::Configuration qw($MYCVS_REPO_STORE);
use RepoManagement::Init;
use VersionManagement::Impl;
use HTTP::HttpServerRequests;

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

sub backup_repo {
    my ($reponame) = @_;
    die "You need to provide repository name.\n" if ! defined($reponame);
    
    my $reply = post_remote_backup_repo($reponame);
    print "Backup Completed successfully.\n" if defined($reply);
}

sub restore_repo {
    my ($reponame, $backupname) = @_;
    if (!defined($reponame) || !defined($backupname)) {
        die "You need to specify reponame and backup name.\n";
    }
    
    print "You are going to overwrite all the repository files.\n";
    print "Are you sure to restore repository?[y/n] (n - default) ";
    my $answer = <STDIN>; chomp $answer;
    if ($answer eq "y") {
        my $reply = post_remote_restore_repo($reponame, $backupname);
        print "Restore Completed successfully.\n" if defined($reply);
    } else {
        print "You decided to quit.\n";
    }
}

sub backup_db {
    my $reply = post_remote_backup_db();
    print "Backup Completed successfully.\n" if defined($reply);
}

sub restore_db {
    my ($backupname) = @_;
    if (!defined($backupname)) {
        die "You need to specify backup name.\n";
    }
    
    print "You are going to overwrite all the repository files.\n";
    print "Are you sure to restore repository?[y/n] (n - default) ";
    my $answer = <STDIN>; chomp $answer;
    if ($answer eq "y") {
        my $reply = post_remote_restore_db($backupname);
        print "Restore Completed successfully.\n" if defined($reply);
    } else {
        print "You decided to quit.\n";
    }
}

sub list_repo_backups {
    my ($reponame) = @_;
    die "You need to provide repository name.\n" if ! defined($reponame);
    
    my $reply = get_remote_repo_backup_list($reponame);
    print "Listing remote backups for repository: '$reponame'.\n";
    print "========================================================\n";
    print $reply;
}

sub list_db_backups {
    my $reply = get_remote_db_backup_list();
    print "Listing remote DataBase backups.\n";
    print "========================================================\n";
    print $reply;
}

1;
