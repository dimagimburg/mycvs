#!/bin/env perl
# Perl libs
use strict; use warnings;
use Getopt::Long;
use File::Basename;
use Switch;


# Internal libs
my $rundir;
BEGIN { use File::Basename; $rundir = dirname($0); }
use lib "$rundir/lib";
#use RepoManagement::Init;
#use RepoManagement::Commands;
#use VersionManagement::Commands;
#use UserManagement::Commands; 

switch(shift(@ARGV)) {
    case 'diff' {
        my $revision;
        GetOptions('-r=i' => \$revision) or die usage();
        diff(shift(@ARGV), $revision);
    }
    case 'checkin' { checkin(shift(@ARGV)); }
    case 'checkout' {
        my $revision;
        GetOptions('-r=i' => \$revision) or die usage();
        checkout(shift(@ARGV), $revision);
    }
    case 'user' { user(shift(@ARGV),shift(@ARGV),shift(@ARGV),shift(@ARGV)); }
    case 'group' { group(shift(@ARGV),shift(@ARGV)); }
    case 'login' { login(shift(@ARGV)); }
    case 'logout' { logout(shift(@ARGV)); }
    else { usage(); }
}

sub diff {
    VersionManagement::Commands::print_revision_diff(shift);
}

sub checkin {
    VersionManagement::Commands::checkin_file(shift);
}

sub checkout {
    VersionManagement::Commands::checkout_file(shift,shift);
}

sub user {
    switch(shift) {
        case 'add' {RepoManagement::Commands::add_user(shift);}
        case 'rem' {RepoManagement::Commands::rem_user_from_group(shift);}
        case 'list' {RepoManagement::Commands::list_users();}
        case 'group' {
            switch(shift) {
                case 'add' {RepoManagement::Commands::add_user_to_group(shift, shift);}
                case 'rem' {RepoManagement::Commands::rem_user_from_group(shift, shift);}
                case 'list' {RepoManagement::Commands::list_user_groups(shift);}
                else {usage();}
            }
        }
        else {usage();}
    }
}

sub group {
    switch(shift) {
        case 'add' {RepoManagement::Commands::group_add(shift);}
        case 'rem' {RepoManagement::Commands::group_rem(shift);}
        case 'list' {RepoManagement::Commands::list_groups();}
        case 'members' {RepoManagement::Commands::list_group_members(shift);}
        else {usage();}
    }
}

sub login {
    RepoManagement::Commands::login_impl(shift);
}

sub logout {
    RepoManagement::Commands::logout_impl(shift);
}


sub usage {
    print "\n\tUSAGE:\n";
    print "\t$0 checkin <filename>                - add/checking file to repository.\n";
    print "\t\t\t\t\t\t\t\t(Inits repository with root in following dir if folder not belongs to any repository)\n";
    print "\t$0 checkout <filename>               - checkout file from repository. (Overwrites existing file)\n";
    print "\t$0 checkout -r <revision> <filename> - checkout file from repository at specific revision. (Overwrites existing file)\n";
    print "\t$0 diff <filename>                   - displays diff of local file and latest repo revision.\n";
    print "\t$0 diff -r <revision> <filename>     - displays diff of local file and specific repo revision.\n";
    print "\t$0 group add <group>                 - Add group.\n";
    print "\t$0 group rem <group>                 - Remove group.\n";
    print "\t$0 group list                        - List groups.\n";
    print "\t$0 group members <group>             - List group members.\n";
    print "\t$0 user add <user>                   - Add user.\n";
    print "\t$0 user rem <user>                   - Remove user.\n";
    print "\t$0 user list                         - List users.\n";
    print "\t$0 user group list <user>            - List user's groups.\n";
    print "\t$0 user group add <user> <group>     - Add user to group.\n";
    print "\t$0 user group rem <user> <group>     - Remove user from group.\n";
    print "\t$0 login <user>                      - Login to system.\n";
    print "\t$0 logout <user>                     - Logout from system.\n";
}
