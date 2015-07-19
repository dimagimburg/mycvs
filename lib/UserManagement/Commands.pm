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
use HTTP::HttpServerRequests;

# Interactive user add
sub add_user {
    my ($user_name, $password) = @_;
    my $isadmin = 'false';
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
    if ($answer eq "y") {
        $isadmin = 'true';
    }
    my $reply = post_remote_add_user($user_name,
                                     generate_pass_hash($password),
                                     $isadmin);
    print $reply;
    
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
    my ($user, $group) = @ARGV;
    if (!defined($user) || !defined($group)) {
        die "You need to enter reponame and username.\n";
    }
    my $reply = post_remote_repo_perm($user, $group);
    print $reply;
}
# Interactively removes user from group
sub rem_user_from_group {
    my ($user, $group) = @ARGV;
    if (! defined($user) || !defined($group)) {
        die "You need to specify reponame and username.\n";
    }
    
    my $reply = delete_remote_repo_perm($group, $user);
    print $reply;
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
    my ($reponame) = @_;
    die "Please enter reponame" if ! defined($reponame);
    
    my $reply = post_create_remote_repo($reponame);
    if (!defined($reply)) {
        print "Can't Connect to server. Please verify you configured client.\n";
    } else {
        print "Repo: '$reponame' created!.\n";
    }
}
# Interactively removes group.
sub group_rem {
    my ($reponame) = @_;
    die "Please enter reponame\n" if ! defined($reponame);
    print "Are you sure to remove remote repo '$reponame'?\n";
    print "All the repo contents will be removed!!![y/n] (n - default) ";
    my $answer = <STDIN>; chomp $answer;
    return if ($answer ne "y");
    
    my $reply = delete_remote_repo($reponame);
    if (!defined($reply)) {
        die "Can't Connect to server. Please verify you configured client.\n";
    }
    print "Repo: '$reponame' deleted.\n"
}

sub rem_user {
    my ($username) = @_;
    die "You not specified username.\n" if ! defined($username);
    print "Are you sure to remove user: '$username'[y/n] (n - default) ";
    my $answer = <STDIN>;chomp $answer;
    return if ($answer ne "y");
    
    my $reply = post_remote_user_del($username);
    if (!defined($reply)) {
        die "Can't Connect to server. Please verify you configured client.\n";
    }
    print "User: '$username' deleted.\n"
}

1;