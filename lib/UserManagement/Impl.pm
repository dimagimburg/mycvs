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
use File::Copy qw(move);
our @ISA = qw(Exporter);
our @EXPORT = qw(
                create_user_record create_group_record
                get_user_groups add_user_to_group_impl remove_user_from_group
                remove_group change_pass get_pass_hash login_user
                logout_user get_session exists_user generate_pass_hash
                exist_user_in_group is_user_admin create_admin_user
                list_users create_admin_user create_user_record_silent
                remove_user list_admin_users remove_admin exists_group
                );
                
# Internal libs
use lib qw(../);
use RepoManagement::Configuration qw(
                                $MYCVS_GLOBAL_BASEDIR $MYCVS_USERS_DB $MYCVS_GROUPS_DB
                                $MYCVS_ADMINS_DB
                                );
use VersionManagement::Impl;

############################# USERS ###############################

# Creates user record in DB
sub create_user_record {
    my ($user_name, $pass) = @_;
    if (! defined($user_name) || ! defined($pass)) {
        return 0;
    }
    chomp $user_name; chomp $pass;
    my $pass_hash = generate_pass_hash($pass);
    
    if (exists_user($user_name)) {
        return 2;
    } else {
        # We'll add new user
        append_user_to_users_db_file($user_name, $pass_hash);
        return 1;
    }
    
    # 0 - error
    # 1 - success
    # 2 - already exists
}

# ----------------WHY 2 CREATE USER RECORD?----------------
# don't want to delete one of them without knowing what i am doing.

sub create_user_record_silent {
    my ($user_name, $pass_hash) = @_;
    if (!defined($user_name) || !defined($pass_hash)) {
        return;
    }
    
    if(exists_users_db_file()){
        # file user.db exists
        if(exists_user($user_name)){
            # username entered already exists, show error message
            return 2;
        } else {
            # file exists, new user, add user to file
            append_user_to_users_db_file($user_name,$pass_hash);
            return 1;
        }
    } else {
        # user.db not exists
        if(exists_base_dir()){
            # /opt/.mycvs exists create file user.db and add the user
            append_user_to_users_db_file($user_name,$pass_hash);
            return 1;
        } else {
            # CANT ADD USER WHEN THERE IS NO .MYCVS INITIALIZED IN OPT
            # SEE WHAT IS THE SOLUTION
            print "repository is not initialized.\n";
            return 0;
        }
    }
}

# appends new user to end of users.db file
sub append_user_to_users_db_file {
    my($username,$password) = @_;
    open(my $fh, '>>', $MYCVS_USERS_DB) or die "\n\nerror opening user.db file\n\n";
    print $fh "$username:$password\n";
    close($fh);
}

# Prints list users sorted by ABC
sub list_users {
    
    my $username;
    my @usernames;
    my @row_splited;

    open(my $fh, '<:encoding(UTF-8)', $MYCVS_USERS_DB);
    
    my $index = 0;
    while (my $row = <$fh>) {
        @row_splited = split(/:/,$row,2);
        $usernames[$index] = $row_splited[0];
        $index++;
    }
    close($fh);
    
    return sort(@usernames);
}

# returns true if user already exists in users.db else false
sub exists_user {
    my ($username) = @_;
    return 0 if !defined($username);
    chomp $username;
    return 0 if $username eq "";
    
    my @users_lines = read_lines_from_file($MYCVS_USERS_DB);
    if (@users_lines) {
        foreach my $user(@users_lines) {
            chomp $user;
            return 1 if $user =~ /^${username}/;
        }
    }
    return 0;
}

# Check if users db exist
sub exists_users_db_file {
    if (-e $MYCVS_USERS_DB) { return 1 }
    return 0;
}

###################################################################

############################# GROUPS ##############################

# Creates group record in DB
sub create_group_record {
    my ($group_name) = @_;
    if (exists_group($group_name)) {
        return 2; #group already exists
    } else {
        # Group not exists
        append_group_to_groups_db_file($group_name.':', $MYCVS_GROUPS_DB);
        return 1;
    }
}



# appends to end of groups.db file the new group
sub append_group_to_groups_db_file {
    my($group_name) = @_;
    open(my $fh, '>>', $MYCVS_GROUPS_DB) or die "\n\nerror opening groups.db file\n\n";
    print $fh "$group_name\n";
    close($fh);
}

# returns true if file groups.db exists else false
sub exists_groups_db_file{
    if (-e $MYCVS_GROUPS_DB) { return 1 }
    return 0;
}

# returns true if group passed in exists else false
sub exists_group {
    my ($group_name) = @_;
    return 0 if !defined($group_name);
    chomp $group_name;
    return 0 if $group_name eq "";
    
    my @group_lines = read_lines_from_file($MYCVS_GROUPS_DB);
    return 0 if ! @group_lines;
    
    foreach my $group(@group_lines) {
        return 1 if $group =~ /^${group_name}/;
    }
    return 0;
}
# Returns list of groups that user belongs to
sub get_user_groups {
    my ($user_name) = @_;
    my @groups = ();
    if(exists_user($user_name)){
        my $groups_file = $MYCVS_GROUPS_DB;
        open (my $fh,  '<', $groups_file ) || die "Can't open $groups_file $!\n"; # read
        while (my $row = <$fh>){
            my $group = (split(/:/,$row,2))[0];
            my $users = (split(/:/,$row,2))[1];
            if($users =~ /$user_name/){
                push(@groups,$group);
            }
        }
    } else {
        # user not exists
        return ();
    }
    return @groups;
}

# Adds user to group. If group not exists prints error
sub add_user_to_group_impl {
    my ($user_name, $group_name) = @_;
    my $status = 0;
    my @group_lines = read_lines_from_file($MYCVS_GROUPS_DB);
    my @new_group_lines = ();
    chomp $user_name; chomp $group_name;
    if (!exists_user($user_name) || ! exists_group($group_name)) {
        return 0; # No such user or group
    }
    
    if (! @group_lines) {
        # No groups exists
        $status = 0;
    } else {
        # groups exits let's check if user exist there
        foreach my $line(@group_lines) {
            chomp $line;
            my @group_line = split(':', $line);
            if ($group_line[0] eq $group_name) {
                if (! defined($group_line[1])) {
                    # No users in group. We'll add first one
                    push @new_group_lines, $line.$user_name."\n";
                    $status = 1;
                } elsif ($group_line[1] =~ /${user_name}/) {
                    # user already in group
                    return 2;
                } else {
                    # User not in group. lets add it.
                    push @new_group_lines, $line.','.$user_name."\n";
                    $status = 1;
                }
            } else {
                # We not found needed group continue loop
                push @new_group_lines, $line."\n";
            }
        }
    }
    # Save edited file
    save_lines_array_to_file(\@new_group_lines, $MYCVS_GROUPS_DB);
    return $status;
}

# Removes user from group
sub remove_user_from_group {
    my ($user_name, $group_name) = @_;
    if (!defined $group_name || !defined $user_name) {
        return 0;
    }
    chomp $user_name; chomp $group_name;
    if (!exists_user($user_name) || !exists_group($group_name)) {
        return 0;
    }
    
    my @new_lines = (); my $status = 0;
    my @group_lines = read_lines_from_file($MYCVS_GROUPS_DB);
    
    # here we know that given user and exists.
    foreach my $group_line(@group_lines) {
        chomp $group_line;
        my @splitted_group = split(':', $group_line);
        if ($splitted_group[0] eq $group_name) {
            # Check if we have users in group.
            if (defined($splitted_group[1]) && $splitted_group[1] =~ /${user_name}/) {
                # we found our user
                $splitted_group[1] =~ s/$user_name//;
                $splitted_group[1] =~ s/^,//; # if user was the first one
                $splitted_group[1] =~ s/,$//; # if user was the last one
                $splitted_group[1] =~ s/,,/,/; # if user was in the middle
                push @new_lines, $splitted_group[0].':'.$splitted_group[1]."\n";
                $status = 1;
            } else {
                # user not part of given group
                push @new_lines, $group_line."\n";
            }
        } else {
            # we not found our group. continue search
            push @new_lines, $group_line."\n";
        }
        
    }
    save_lines_array_to_file(\@new_lines, $MYCVS_GROUPS_DB);
    return $status;
}

# Removes group from DB.
sub remove_group {
    my ($group_name) = @_;
    if(exists_group($group_name)){
        # group exists in groups.db
        my @row_splited;
        my @group_splited;
        my $infile = $MYCVS_GROUPS_DB;
        my $outfile = "$infile.tmp"; # temp file which will be renamed after the insertion of new user

        open (my $in,  '<', $infile ) || die "Can't open $infile $!\n"; # read
        open (my $out, '>', $outfile) || die "Can't open $outfile $!\n"; # write

        while (my $row = <$in>){   
            @row_splited = split(/:/,$row,2); # get the group name from beggining of the line in groups.db
            if($row_splited[0] ne $group_name){
                print $out $row;
            }
        }

        close ($in);
        close ($out);

        rename ($outfile, $infile) || die "Unable to rename: $!"; # rename the temp file to the original file.
        return 1;
    } else {
        # wrong group name
        # print "group: $group_name not exists.\n";
        return 0;
    }
}

# Changes user password. If chnage_pass(new_user) create new hash.
sub change_pass {
    # Function uses generate_pass_hash function
    # Stores hash at the ent of the user's line in DB
}

# Returns password hash for user.
sub get_pass_hash {
    my ($user) = @_;
    my @row_splited;
    my @pass_hash;

    open(my $fh, '<:encoding(UTF-8)', $MYCVS_USERS_DB);
    
    while (my $row = <$fh>) {
        @row_splited = split(/:/,$row,2);
        if($row_splited[0] eq $user){
            @pass_hash = split(/\n/,$row_splited[1],2);
            return $pass_hash[0];
        }
    }
    return 0;
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


############################### GLOBAL ##################################

sub search_pattern_in_line_begining{
    my ($pattern,$file_path) = @_;

    my $pattern_begining_line = "^$pattern";

        open(my $fh, '<:encoding(UTF-8)', $file_path);

        while (my $row = <$fh>) {
            chomp $row;
            if($row =~ /$pattern_begining_line/) { 
                close($fh);
                return 1;
            }
        }

        close($fh);

        return 0;
}

# returns true if base dir mycvs/ exists, else false
sub exists_base_dir {
    if(-d $MYCVS_GLOBAL_BASEDIR) { return 1 }
    return 0;
}

# check if user exists in given group
sub exist_user_in_group {
    my ($username, $groupname) = @_;
    my $groups_db_path = $MYCVS_GROUPS_DB;
    
    my @lines = read_lines_from_file($MYCVS_GROUPS_DB);
    return 0 if ! @lines;
    
    chomp $username;
    foreach my $line(@lines) {
        chomp $line;
        my @group_line = split(':', $line);
        # split group line to check group
        if ($group_line[0] eq $groupname) {
            return 1 if $group_line[1] =~ /${username}/;
        }
    }
    return 0;
}

# Will check if user is admin user
sub is_user_admin {
    my ($username) = @_;
    my @admins = list_admin_users();
    foreach my $admin(@admins) {
        chomp $admin;
        if ($admin eq $username) {
            return 1;
        }
    }
    return 0;
}

sub create_admin_user {
    my ($username) = @_;
    my @admins = list_admin_users();
    
    if (!is_user_admin($username)) {
        $admins[@admins] = "$username\n";
        save_lines_array_to_file(\@admins, $MYCVS_ADMINS_DB);
        return 1;
    }
    return 0;
}

sub list_admin_users {
    if (!-f $MYCVS_ADMINS_DB) {
        return;
    }
    my @lines = read_lines_from_file($MYCVS_ADMINS_DB);
    return @lines;
}

sub remove_admin {
    my ($username) = @_;
    chomp $username;
    my @admins = list_admin_users();
    my @new_admins = ();
    foreach my $admin(@admins) {
        chomp $admin;
        if ($admin ne $username) {
            push @new_admins, $admin."\n";
        }
    }
    save_lines_array_to_file(\@new_admins, $MYCVS_ADMINS_DB);
}

sub remove_user {
    my ($username) = @_;
    return 0 if ! defined($username);
    return 0 if ! exists_user($username);
    chomp $username;
    
    my @user_groups = get_user_groups($username);
    my @user_lines  = read_lines_from_file($MYCVS_USERS_DB);
    my @new_users = ();
    
    foreach my $group(@user_groups) {
        remove_user_from_group($username, $group);
    }
    remove_admin($username);
    foreach my $user(@user_lines) {
        chomp $user;
        if ($user !~ /^${username}/) {
            push @new_users, $user."\n";
        }
    }
    save_lines_array_to_file(\@new_users, $MYCVS_USERS_DB);
    return 1;
}

1;