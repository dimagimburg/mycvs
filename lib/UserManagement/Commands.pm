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
package UserManagement::Commands;
use strict; use warnings;

# Perl libs & vars
use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(
                    create_user create_user_record create_group create_group_record
                    get_user_groups add_user_to_group remove_user_from_group
                    remove_group change_pass get_pass_hash
                );
                
# Internal libs
use lib qw(../);
use RepoManagement::Configuration;

# Creates user. Interactive function
sub create_user {
    # Function make use of create_user_record and add_user_to_group
}

# Creates use record in DB
sub create_user_record {
    my ($user_name, $pass_hash) = @_;
    
}

# Creates group. Interactive function
sub create_group {
    # Function make use of create_group_record
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
sub add_user_to_group {
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

# Get password hash for user password validation
sub get_pass_hash {
    
}

# Retuns hash of given password. probably will be MD5 hash
sub generate_pass_hash {
    my ($pass) = @_;
}
1;