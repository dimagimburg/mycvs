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
                login_impl logout_impl add_user print_users
                add_user_to_group rem_user_from_group list_user_groups
                list_group_members list_groups group_add group_rem
                );
                
# Internal libs
use lib qw(../);
use UserManagement::Impl;

# Interactive user add
sub add_user {
    my ($user_name,$password) = @_;
    if (!defined($user_name)) {
        die "You should enter at least username to add.\n"
    }
    if (!defined($password)) {
        while (1) {
            print "Please enter password: ";
            $password = <STDIN>;
            chomp $password;
            last if $password ne "";
        }
    }
    print "Is this user admin?[y/n] (n - default) ";
    my $answer = <STDIN>;
    chomp $answer;
    UserManagement::Impl::create_user_record($user_name,$password);
    if ($answer eq "y") {
        if (create_admin_user($user_name)) {
            print "Successfully promoted user to be ADMIN.\n";
        } else {
            print "User already promoted to be admin.\n";
        }
    }
    
    
}
# Simply prints global user list
sub print_users {
    my @userlist = list_users();
    if (!@userlist) {
        die "User's DB is empty\n";
    }
    
    foreach my $line(@userlist) {
        print "$line\n";
    }
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