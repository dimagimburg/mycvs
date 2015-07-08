#!/bin/env perl
# Perl libs
use strict; use warnings;
use Getopt::Long;
use File::Basename;
use feature qw(switch);
use experimental qw(smartmatch);

# Internal libs
my $rundir;
BEGIN { use File::Basename; $rundir = dirname($0); }
use lib "$rundir/lib";
use RepoManagement::Init;
use RepoManagement::Commands;
use VersionManagement::Commands;
use UserManagement::Commands; 

given(shift(@ARGV)) {
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
    when ('group') { group(shift(@ARGV),shift(@ARGV)); }
    when ('login') { login(shift(@ARGV)); }
    when ('logout') { logout(shift(@ARGV)); }
    default { usage(); } 
}

sub diff {
    VersionManagement::Commands::print_revision_diff(shift, shift);
}

sub checkin {
    VersionManagement::Commands::checkin_file(shift);
}

sub checkout {
    VersionManagement::Commands::checkout_file(shift,shift);
}

sub user {
    given(shift) {
        when ('add') {UserManagement::Commands::add_user(shift);}
        when ('rem') {UserManagement::Commands::rem_user_from_group(shift);}
        when ('list') {UserManagement::Commands::list_users();}
        when ('group') {
            given(shift) {
                when ('add') {UserManagement::Commands::add_user_to_group(shift, shift);}
                when ('rem') {UserManagement::Commands::rem_user_from_group(shift, shift);}
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
        default {usage();}
    }
}

sub login {
    UserManagement::Commands::login_impl(shift);
}

sub logout {
    UserManagement::Commands::logout_impl(shift);
}


sub usage {
    print "\n    USAGE:\n";
    print "    $0 checkin <filename>                - add/checking file to repository.\n";
    print "    $0 checkout <filename>               - checkout file from repository.(Overwrites)\n";
    print "    $0 checkout -r <revision> <filename> - checkout file from repository at specific revision.(Overwrites)\n";
    print "    $0 diff <filename>                   - displays diff of local file and latest repo revision.\n";
    print "    $0 diff -r <revision> <filename>     - displays diff of local file and specific repo revision.\n";
    print "    $0 group add <group>                 - Add group.\n";
    print "    $0 group rem <group>                 - Remove group.\n";
    print "    $0 group list                        - List groups.\n";
    print "    $0 group members <group>             - List group members.\n";
    print "    $0 user add <user>                   - Add user.\n";
    print "    $0 user rem <user>                   - Remove user.\n";
    print "    $0 user list                         - List users.\n";
    print "    $0 user group list <user>            - List user's groups.\n";
    print "    $0 user group add <user> <group>     - Add user to group.\n";
    print "    $0 user group rem <user> <group>     - Remove user from group.\n";
    print "    $0 login <user>                      - Login to system.\n";
    print "    $0 logout <user>                     - Logout from system.\n";
}
