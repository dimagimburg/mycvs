#!/bin/env perl
package RepoManagement::Init;

# Perl libs & vars
use strict; use warnings;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Cwd;
use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(
                init_global init_local parse_config_line save_client_config
                get_repo_root create_local_repo remove_local_repo
                );

# Internal libs
use lib qw(../);
use RepoManagement::Configuration qw(
                    $MYCVS_GLOBAL_BASEDIR $MYCVS_GLOBAL_CONFIG_LOC
                    $MYCVS_USERS_DB $MYCVS_GROUPS_DB $MYCVS_DB_FOLDER
                    $MYCVS_HTTP_PORT $MYCVS_REPO_STORE $MYCVS_CONFIG_NAME
                    $MYCVS_ADMINS_DB $MYCVS_BACKUP_STORE
                    $MYCVS_DB_BACKUP_STORE $MYCVS_REPO_BACKUP_STORE
                    );
use UserManagement::Impl;
use VersionManagement::Impl;

# Create global dir tree
sub init_global {
    # Create global configuration dir that will hold all the db files
    check_and_create_dir($MYCVS_GLOBAL_BASEDIR);
    check_and_create_dir($MYCVS_DB_FOLDER);
    check_and_create_dir($MYCVS_REPO_STORE);
    init_users_db();
    init_groups_db();
    init_admins_db();
    init_backup_store();
}

# Initialize .mycvs store in new directory.
# This folder will store diffs/revisions
sub init_local {
    my ($dir) = @_;
    check_and_create_dir($dir.'/.mycvs');
}

# Creates config file and saves client config file in root ./mycvs client path
sub save_client_config {
    my ($host, $port, $reponame, $user, $pass, $dir) = @_;
    check_and_create_dir("$dir/.mycvs");
    save_string_to_new_file("$host:$port:$reponame:$user:$pass\n", "$dir/.mycvs/$MYCVS_CONFIG_NAME")
}

# writes the config string to the file
sub save_config{
    my ($cfg,$path) = @_;
    open(my $fh, '>>', $path) or die "\n\nerror opening config file\n\n";
    print $fh "$cfg\n";
    close($fh);
    print "Configuration successful.\n";
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
        die "Client not configured. Please use 'clientconfig'\n" if ! %options;
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
        die "Something went wrong. Received '$dir' as dirname.\n";
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

sub init_admins_db {
        if (! -f $MYCVS_ADMINS_DB) {
        create_file($MYCVS_ADMINS_DB);
    }
}

sub init_backup_store {
    check_and_create_dir($MYCVS_DB_BACKUP_STORE);
    check_and_create_dir($MYCVS_REPO_BACKUP_STORE);
}

sub create_file {
    my ($fname) = @_;
    if (defined($fname) && $fname ne "") {
        open(my $fh, '>', $fname) or die "Can not create $fname.";
        close($fh);
    }   
}

sub create_local_repo {
    my ($reponame) = @_;
    return if ! defined($reponame);
    my $dir_path = $MYCVS_REPO_STORE.'/'.$reponame;
    check_and_create_dir($dir_path);
    if (! exists_group($reponame)) {
        return create_group_record($reponame);
    } else {
        return 2;
    }
}

sub remove_local_repo {
    my ($reponame) = @_;
    return if ! defined($reponame);
    my $dir_path = $MYCVS_REPO_STORE.'/'.$reponame;
    
    if (exists_group($reponame)) {
        remove_tree($dir_path) if -d $MYCVS_REPO_STORE.'/'.$reponame;
        return remove_group($reponame);
    } else {
        return 0;
    }
    
}


1;