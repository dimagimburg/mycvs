#!/bin/env perl
# Perl libs
#use File::Path qw(make_path);
use Getopt::Long;
use File::Basename;
use Switch;


# Internal libs
use lib qw(lib);
use RepoManagement::Init;
use VersionManagement::Commands;
use UserManagement::Commands; 


my $type = shift(@ARGV);
switch($type) {
    case 'diff' {
        
    }
    case 'checkin' {
        
    }
    case 'checkout' {
        
    }
    case 'user' {
        
    }
    case 'group' {
        
    }
    case 'login' {
        
    }
    case 'logout' {
        
    }
    else {
        usage();
    }
}


sub usage {
    print "\n\tUSAGE:\n";
    print "\t$0 checkin <filename>                - add/checking file to repository. (Inits repository with root in following dir if folder not belongs to any repository)\n";
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
    print "\t$0 user group list                   - List user's groups.\n";
    print "\t$0 user group add <user> <group>     - Add user to group.\n";
    print "\t$0 user group rem <user> <group>     - Remove user from group.\n";
    print "\t$0 login                             - Login to system.\n";
    print "\t$0 logout                            - Logout from system.\n";
}
