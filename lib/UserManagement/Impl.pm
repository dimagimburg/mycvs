#!/bin/env perl
#
# users.db file structure:
# username:password_hash
# location: $RepoManagement::Configuration::MYCVS_USERS_DB
#=============================
# groups.db file structure
# group_name:user1,user2
# location: $RepoManagement::Configuration::MYCVS_GROUPS_DB
#
package UserManagement::Impl;
use strict; use warnings;

# Perl libs & vars
use Digest::MD5 qw(md5_hex);
use Exporter qw(import);
use File::Path qw(make_path);
use RepoManagement::Configuration qw<$MYCVS_GLOBAL_BASEDIR $MYCVS_USERS_DB>;
our @ISA = qw(Exporter);
our @EXPORT = qw(
                create_user_record create_group_record
                get_user_groups add_user_to_group_impl remove_user_from_group
                remove_group change_pass get_pass_hash login_user
                logout_user get_session
                );
                
# Internal libs
use lib qw(../);
use RepoManagement::Configuration;

# Creates use record in DB
sub create_user_record {
    my ($user_name, $pass_hash) = @_;
    $pass_hash = generate_pass_hash($pass_hash);
    print "username: ".$user_name.", password: ".$pass_hash."\n";
    print $MYCVS_USERS_DB."\n";

    if(exists_user_db_file($MYCVS_USERS_DB)){
        print "file exists  \n";
        print "need to check if user exists\n";
    } else {
        if(exists_base_dir($MYCVS_GLOBAL_BASEDIR)){
            print "base dir exists create user db";
            print "file not exists $MYCVS_GLOBAL_BASEDIR\n";
            print "creating file\n";
            open(my $fh, '>', $MYCVS_USERS_DB) or die "\n\nerror creating user db\n\n";
            print $fh "$user_name:$pass_hash";
            close($fh);
            print "created!\n\n";
        } else {
            # CANT ADD USER WHEN THERE IS NO .MYCVS INITIALIZED IN OPT
            # SEE WHAT IS THE SOLUTION
            print "repository is not initialized";
        }
    }
}

# Check if users db exist
sub exists_user_db_file {
    my ($path_user_db_file) = @_;
    if (-e $path_user_db_file) { return 1 }
    return 0;
}

sub exists_base_dir {
    my ($base_dir) = @_;
    if(-d $base_dir) { return 1 }
    return 0;
}

# Creates user db
sub create_user_db {

}


# Creates group record in DB
sub create_group_record {
    my ($group_name) = @_;
    
}
# Returns list of groups that user belongs to
sub get_user_groups {
    my ($user_name) = @_;
    
}

# Adds user to group. If group not exists prints error
sub add_user_to_group_impl {
    my ($user_name, $group_name) = @_;
}

# Removes user from group
sub remove_user_from_group {
    my ($user_name, $group_name) = @_;
}

# Removes group from DB.
sub remove_group {
    my ($group) = @_;
}

# Changes user password. If chnage_pass(new_user) create new hash.
sub change_pass {
    # Function uses generate_pass_hash function
    # Stores hash at the ent of the user's line in DB
}

# Returns password hash for user.
sub get_pass_hash {
    my ($user) = @_;
}

# Retuns hash of given password. probably will be MD5 hash
sub generate_pass_hash {
    my ($pass) = @_;
    if (defined($pass) && $pass ne "") {
        return md5_hex($pass);
    } else {
        return;
    }
}

# Make user login to the system. Gets user and password.
# Creates session file under $RepoManagement::Configuration::MYCVS_SESSIONS_DB
# Session filename: username
# Contents: pc_name:session_id
# if file not exists. If file exists adds session line if new session.
sub login_user {
    my ($user_name, $pass) = @_;
}

# Removes entry in session file or if last session removes file.
sub logout_user {
    my ($user) = @_;
}

# Returns session id of the user specified if found from session file.
sub get_session {
    my ($user) = @_;
    
}

1;