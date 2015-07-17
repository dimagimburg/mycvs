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
    when ('init'){ init(shift(@ARGV),shift(@ARGV)); }
    when ('diff') {
        my $revision;
        GetOptions('-r=i' => \$revision) or die usage();
        diff(shift(@ARGV), $revision);
    }
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

sub init {
    RepoManagement::Init::init(shift,shift);
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
        when ('rem') {UserManagement::Commands::rem_user_from_group(shift);}
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
        when ('list') {UserManagement::Commands::list_groups();}
        when ('members') {UserManagement::Commands::list_group_members(shift);}
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
    print "\n    USAGE:\n";
    print "    $0 server                            - Server Configuration.\n";
    print "    $0 clientconfig                      - initializing local repository.\n";
    print "    $0 filelist                          - List repository content. (R - only remote, L - remote and local)\n";
    print "    $0 checkin <filename>                - add/checking file to repository.\n";
    print "    $0 checkout <filename>               - checkout file from repository.(Overwrites)\n";
    print "    $0 checkout -r <revision> <filename> - checkout file from repository at specific revision.(Overwrites)\n";
    print "    $0 revisions <filename>              - list file revisions.\n";
    print "    $0 diff <filename>                   - displays diff of local file and latest repo revision.\n";
    print "    $0 diff -r <revision> <filename>     - displays diff of local file and specific repo revision.\n";
    print "    $0 repo add <reponame>               - Add remote repo.\n";
    print "    $0 repo rem <reponame>               - Remove remote repo.\n";
    print "    $0 repo list                         - List remote repos.\n";
    print "    $0 repo members <reponame>           - List repo users.\n";
    print "    $0 repo user rem <user> <reponame>   - Add user to repo.\n";
    print "    $0 repo user add <user> <reponame>   - Remove user from repo.\n";
    print "    $0 user add <user>                   - Add user.\n";
    print "    $0 user rem <user>                   - Remove user.\n";
    print "    $0 user repo list <user>             - List user's groups.\n";
}
