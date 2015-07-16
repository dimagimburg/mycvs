#!/bin/env perl
package RepoManagement::Init;

# Perl libs & vars
use strict; use warnings;
use File::Path qw(make_path);
use File::Basename;
use Cwd;
use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(
                init_global init_local parse_config_line save_client_config
                get_repo_root
                );

# Internal libs
use lib qw(../);
use RepoManagement::Configuration qw(
                    $MYCVS_GLOBAL_BASEDIR $MYCVS_GLOBAL_CONFIG_LOC
                    $MYCVS_USERS_DB $MYCVS_GROUPS_DB $MYCVS_DB_FOLDER
                    $MYCVS_HTTP_PORT $MYCVS_REPO_STORE $MYCVS_CONFIG_NAME
                    );
use UserManagement::Impl;
use VersionManagement::Impl;

# Initialize a new Server config with username and password for admin
sub init{
    my($username,$password) = @_;

    # HERE INITIALIZE ALL THE LOCAL AND GLOBAL IF NECCESSARTY

    if(exists_user($username)){
        # user exists
        if(get_pass_hash($username) eq generate_pass_hash($password)){
            print "user ok pass ok\n";
            print "create repository with admin and password and ask to login to open admin session";
        } else {
            print "password for user $username is incorrect\n";
        }
    } else {
        print "user: $username not exists in user.db\n";      
    }
}


# Create global dir tree
sub init_global {
    # Create global configuration dir that will hold all the db files and sessions
    check_and_create_dir($MYCVS_GLOBAL_BASEDIR);
    init_users_db();
    init_grops_db();
}

# Initialize .mycvs store in new directory.
# This folder will store diffs/revisions
sub init_local {
    my ($dir) = @_;
    check_and_create_dir($dir.'/.mycvs');
    
}


sub save_client_config {
    my ($host, $port, $reponame, $user, $pass, $dir) = @_;
    check_and_create_dir("$dir/.mycvs");
    save_string_to_new_file("$host:$port:$reponame:$user:$pass", "$dir/.mycvs/$MYCVS_CONFIG_NAME")
}

# Tries to find reporoot.
sub get_repo_root {
    my ($file_path) = @_;
    
    if (! -d dirname($file_path)) {
        return;
    }
    
    my $reporoot;
    
    while ($file_path ne "/") {
        if (-f "$file_path/.mycvs/$MYCVS_CONFIG_NAME") {
            $reporoot = $file_path;
        }
        $file_path = dirname($file_path);
    }
    
    return $reporoot;
}
# Receives file_path and tries to find reporootdir
# to read config from. If config file exists
# returns array of config "$host, $port, $reponame, $user, $pass"
sub parse_config_line {
    my ($file_path) = @_;
    
    my $reporoot = get_repo_root($file_path);
    
    my (@lines, @splitted, %options);
    if (! defined($reporoot)) {
        return;
    }
    @lines = read_lines_from_file("$reporoot/.mycvs/$MYCVS_CONFIG_NAME");
    if (@lines) {
        @splitted = split(':', $lines[0]);
        
        $options{host}     = $splitted[0];
        $options{port}     = $splitted[1];
        $options{reponame} = $splitted[2];
        $options{user}     = $splitted[3];
        $options{pass}     = $splitted[4];
        
        return %options;
    } else {
        return;
    }
}

 

sub check_and_create_dir {
    my ($dir) = @_;
    if (defined("$dir") && $dir ne "") {
        if (! -e "$dir") {
            make_path($dir) or die "Couldn't create dir '$dir'. Please verify that directory is writable.\n";
        }
    } else {
        die "Something went wrong. Received '$dir' as dirname.";
    }
}

# File structure is like /etc/passwd
# username:password_hash
sub init_users_db {
    if (! -f $MYCVS_USERS_DB) {
        create_file($MYCVS_USERS_DB);
    }
}

# File structure is like /etc/groups
# group1:user1,user2
# group2:user3,user4
sub init_groups_db {
    if (! -f $MYCVS_GROUPS_DB) {
        create_file($MYCVS_GROUPS_DB);
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