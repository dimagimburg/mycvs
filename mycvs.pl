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
        GetOptions('-r=i' => \$revision) or die usage();
        diff(shift(@ARGV), $revision);
    }
    when ('localdiff') {diff_local(shift(@ARGV),shift(@ARGV))}
    when ('checkin') { checkin(shift(@ARGV)); }
    when ('checkout') {
        my $revision;
        GetOptions('-r=i' => \$revision) or die usage();
        checkout(shift(@ARGV), $revision);
    }
    when ('user') { user(shift(@ARGV),shift(@ARGV),shift(@ARGV),shift(@ARGV)); }
    when ('repo') { group(shift(@ARGV),shift(@ARGV)); }
    when ('revisions') { get_revisions(shift(@ARGV)); }
    when ('server') { http_server(shift(@ARGV)); }
    when ('clientconfig') {config();}
    when ('filelist') {filelist();}
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
        when ('list') {UserManagement::Commands::list_users();}
        when ('repo') {
            given(shift) {
                when ('list') {UserManagement::Commands::list_user_groups(shift);}
                default {usage();}
            }
        }
        default {usage();}
    }
}

sub group {
    given(shift) {
        when ('add') {UserManagement::Commands::group_add(shift);}
        when ('rem') {UserManagement::Commands::group_rem(shift);}
        when ('list') {UserManagement::Commands::list_remote_groups();}
        when ('members') {UserManagement::Commands::list_remote_group_members(shift);}
        when ('backup') {UserManagement::Commands::backup(shift);};
        when  ('user') {
            given(shift) {
                when ('add') {UserManagement::Commands::add_user_to_group(shift, shift);}
                when ('rem') {UserManagement::Commands::rem_user_from_group(shift, shift);}
                default {usage();}
            }
        }
        default {usage();}
    }
}

sub get_revisions {
    VersionManagement::Commands::print_revisions(shift)
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

sub usage {
    my $exe = basename($0);
    print "\n    USAGE:\n";
    print "    $exe server                            - Server Configuration/Startup.\n";
    print "    $exe clientconfig                      - initializing local repository.\n";
    print "    $exe filelist                          - List repository content.\n";
    print "    $exe checkin <filename>                - add/checking file to repository.\n";
    print "    $exe checkout <filename>               - checkout file from repository.\n";
    print "    $exe checkout -r <revision> <filename> - checkout file from repository at specific revision.\n";
    print "    $exe revisions <filename>              - list file revisions.\n";
    print "    $exe diff <filename>                   - displays diff of local file and latest repo revision.\n";
    print "    $exe diff -r <revision> <filename>     - displays diff of local file and specific repo revision.\n";
    print "    $exe localdiff <filename1> <filename2> - displays diff of two local files.\n";
    print "    $exe repo add <reponame>               - Add remote repo.\n";
    print "    $exe repo rem <reponame>               - Remove remote repo.\n";
    print "    $exe repo backup <reponame>            - Creates tar file with repository backup.\n";
    print "    $exe repo list                         - List remote repos.\n";
    print "    $exe repo members <reponame>           - List repo users.\n";
    print "    $exe repo user rem <user> <reponame>   - Add user to repo.\n";
    print "    $exe repo user add <user> <reponame>   - Remove user from repo.\n";
    print "    $exe user add <user>                   - Add user.\n";
    print "    $exe user rem <user>                   - Remove user.\n";
    print "    $exe user repo list <user>             - List user's groups.\n";
}
