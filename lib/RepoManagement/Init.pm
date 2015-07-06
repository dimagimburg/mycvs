#!/bin/env perl
package RepoManagement::Init;

# Perl libs & vars
use strict; use warnings;
use File::Path qw(make_path);
use Cwd;
use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(init_global init_local);

# Internal libs
use lib qw(../);
use RepoManagement::Configuration;


# Create global dir tree
sub init_global {
    # Create global configuration dir that will hold all the db files and sessions
    check_and_create_dir($RepoManagement::Configuration::MYCVS_GLOBAL_BASEDIR);
    # Create sessions directory that will hold user session files
    check_and_create_dir($RepoManagement::Configuration::MYCVS_SESSIONS_DB);
    init_users_db();
    init_grops_db();
    init_repos_db();
}

# Initialize .mycvs store in new directory.
# This folder will store diffs/revisions
sub init_local {
    my $dir = getcwd();
    check_and_create_dir($dir.'/.mycvs');
}

sub check_and_create_dir {
    my ($dir) = @_;
    if (defined($dir) && $dir ne "") {
        if (! -d $dir) {
            make_path($dir) or die "Couldn't create dir '$dir'. Please verify that directory is writable";
        }
        return 2;
    } else {
        printf("Something went wrong. Received '%s' as dirname.", $dir);
        return 1;
    }
    return 0;
}

# File structure is like /etc/passwd
# username:password_hash
sub init_users_db {
    if (! -f $RepoManagement::Configuration::MYCVS_USERS_DB) {
        create_file($RepoManagement::Configuration::MYCVS_REPOS_DB);
    }
}

# File structure is like /etc/groups
# root_dir:admin_group1:users_group1
# root_dir:admin_group2:users_group2
sub init_repos_db {
    if (! -f $RepoManagement::Configuration::MYCVS_REPOS_DB) {
        create_file($RepoManagement::Configuration::MYCVS_REPOS_DB);
    }
}

# File structure is like /etc/groups
# group1:user1,user2
# group2:user3,user4
sub init_groups_db {
    if (! -f $RepoManagement::Configuration::MYCVS_GROUPS_DB) {
        create_file($RepoManagement::Configuration::MYCVS_GROUPS_DB);
    }
}

sub create_file {
    my ($fname) = @_;
    if (defined($fname) && $fname ne "") {
        open(my $fh, '>', $fname) or die "Can not init $fname.";
        close($fh);
    }   
}


1;