#!/usr/bin/env perl
# Perl libs
use strict; use warnings;
use Getopt::Long;
use File::Basename;
use feature qw(switch);

#use experimental qw(smartmatch);
# ix for dima's perl
no if $] >= 5.018, warnings => "experimental::smartmatch";

# Internal libs
my $rundir;
BEGIN { use File::Basename; $rundir = dirname($0); }
use lib "$rundir/lib";
use RepoManagement::Init;
use RepoManagement::Commands;
use VersionManagement::Commands;
use UserManagement::Commands;
use HTTP::HttpServer;

given(shift(@ARGV)) {
    when ('diff') {
        my $revision;
        GetOptions('-r=i' => \$revision) or die "$!\n";
        diff(shift(@ARGV), $revision);
    }
    when ('localdiff') {diff_local(shift(@ARGV),shift(@ARGV))}
    when ('checkin') { checkin(shift(@ARGV)); }
    when ('checkout') {
        my $revision;
        GetOptions('-r=i' => \$revision) or die "$!\n";
        checkout(shift(@ARGV), $revision);
    }
    when ('user') { user(shift(@ARGV),shift(@ARGV),shift(@ARGV),shift(@ARGV)); }
    when ('repo') { group(shift(@ARGV),shift(@ARGV)); }
    when ('revisions') { get_revisions(shift(@ARGV)); }
    when ('server') { http_server(shift(@ARGV)); }
    when ('clientconfig') {config();}
    when ('filelist') {filelist();}
    when ('backup') {backup(shift(@ARGV),shift(@ARGV));}
    when ('restore') {restore(shift(@ARGV),shift(@ARGV),shift(@ARGV));};
    default { usage(); } 
}

sub diff {
    VersionManagement::Commands::print_revision_diff(shift, shift);
}

sub diff_local {
    VersionManagement::Commands::print_local_files_diff(shift, shift);
}

sub checkin {
    VersionManagement::Commands::checkin_file(shift);
}

sub checkout {
    VersionManagement::Commands::checkout_file(shift,shift);
}

sub user {
    given(shift) {
        when ('add') {UserManagement::Commands::add_user(shift,shift);}
        when ('rem') {UserManagement::Commands::rem_user(shift);}
        default {user_usage();}
    }
}

sub group {
    given(shift) {
        when ('add') {UserManagement::Commands::group_add(shift);}
        when ('rem') {UserManagement::Commands::group_rem(shift);}
        when ('list') {UserManagement::Commands::list_remote_groups();}
        when ('members') {UserManagement::Commands::list_remote_group_members(shift);}
        when  ('user') {
            given(shift) {
                when ('add') {UserManagement::Commands::add_user_to_group(shift, shift);}
                when ('rem') {UserManagement::Commands::rem_user_from_group(shift, shift);}
                default {repo_usage();}
            }
        }
        default {repo_usage();}
    }
}

sub get_revisions {
    VersionManagement::Commands::print_revisions(shift);
}

sub http_server {
    HTTP::HttpServer::main(shift);
}

sub config {
    RepoManagement::Commands::create_user_config();
}

sub filelist {
    VersionManagement::Commands::print_file_list();
}

sub backup {
    given(shift) {
        when('repo') {RepoManagement::Commands::backup_repo(shift);}
        when('db') {RepoManagement::Commands::backup_db();}
        when('listdb') {RepoManagement::Commands::list_db_backups();}
        when('listrepo') {RepoManagement::Commands::list_repo_backups(shift);}
        default {backup_usage();}
    }
}

sub restore {
    given(shift) {
        when('repo') {RepoManagement::Commands::restore_repo(shift,shift);}
        when('db') {RepoManagement::Commands::restore_db(shift);}
        default {restore_usage();}
    }
}

sub usage {
    my $exe = basename($0);
    print "\nUSAGE:\n";
    print "$exe filelist                          - List repository content.\n";
    print "$exe checkin <filename>                - Checkin file to repository.\n";
    print "$exe checkout <filename>               - Checkout file from repository.\n";
    print "$exe checkout -r <revision> <filename> - Checkout file from at revision.\n";
    print "$exe revisions <filename>              - List file revisions.\n";
    print "$exe diff <filename>                   - Diff of latest revision.\n";
    print "$exe diff -r <revision> <filename>     - Diff at specific revision.\n";
    print "$exe localdiff <filename1> <filename2> - Diff of two local files.\n";
    print "$exe clientconfig                      - Init local repository.\n";
    print "$exe server                            - Server sub-menu.\n";
    print "$exe user                              - UserManagement sub-menu.\n";
    print "$exe repo                              - RepoManagement sub-menu.\n";
    print "$exe backup                            - Backup sub-menu.\n";
    print "$exe restore                           - Restore sub-menu.\n"
}

sub user_usage {
    my $exe = basename($0);
    print "\nUSAGE:\n";
    print "$exe user add <user>       - Add user.\n";
    print "$exe user rem <user>       - Remove user.\n";
}

sub repo_usage {
    my $exe = basename($0);
    print "\nUSAGE:\n";
    print "$exe repo add <reponame>             - Add remote repo.\n";
    print "$exe repo rem <reponame>             - Remove remote repo.\n";
    print "$exe repo list                       - List remote repos.\n";
    print "$exe repo members <reponame>         - List repo users.\n";
    print "$exe repo user rem <user> <reponame> - Add user to repo.\n";
    print "$exe repo user add <user> <reponame> - Remove user from repo.\n";
}

sub backup_usage {
    my $exe = basename($0);
    print "\nUSAGE:\n";
    print "$exe backup repo <reponame>     - Backup repository.\n";
    print "$exe backup db                  - Backup DataBase.\n";
    print "$exe backup listrepo <reponame> - List repository backups.\n";
    print "$exe backup listdb              - List DataBase backups.\n";
}

sub restore_usage {
    my $exe = basename($0);
    print "\nUSAGE:\n";
    print "$exe restore repo <reponame> <backupname> - Backup repository.\n";
    print "$exe restore db                           - Backup DataBase.\n";
}
