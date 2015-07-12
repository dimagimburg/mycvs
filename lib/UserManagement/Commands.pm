#!/bin/env perl
#
# Here will go all the Interactive commands of user submenu
# as well as login and logout
# make use of UserManagement::Impl
package UserManagement::Commands;
use strict; use warnings;

# Perl libs & vars
use Digest::MD5 qw(md5_hex);
use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(
                login_impl logout_impl add_user list_users
                add_user_to_group rem_user_from_group list_user_groups
                list_group_members list_groups group_add group_rem
                );
                
# Internal libs
use lib qw(../);
use UserManagement::Impl;

# Interactive login implementation.
sub login_impl {
    my ($user) = @_;
}

# Interactive logout implementation.
# If !defined($user) logout current user. $ENV{USER}
# else print that there no logged in users
sub logout_impl {
    my ($user) = @_;
}
# Interactive user add
sub add_user {
    my ($user_name,$password) = @_;
    UserManagement::Impl::create_user_record($user_name,$password);
}
# Simply prints global user list
sub list_users {
    UserManagement::Impl::list_users();
}
# Interactively add user to group
sub add_user_to_group {
    my ($user, $group) = @_;
    UserManagement::Impl::add_user_to_group_impl($user, $group);
}
# Interactively removes user from group
sub rem_user_from_group {
    my ($user, $group) = @_;
}
# Simply prints groups that user belons to.
sub list_user_groups {
    my ($user) = @_;
}
# Simply prints group members.
sub list_group_members {
    my ($group) = @_;
}
# Simply prints all existing groups.
sub list_groups {
    
}
# Interactively adds group.
sub group_add {
    my ($group) = @_;
    create_group_record($group);
}
# Interactively removes group.
sub group_rem {
    my ($group) = @_;
}

1;