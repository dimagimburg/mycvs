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
our @ISA = qw(Exporter);
our @EXPORT = qw(
                create_user_record create_group_record
                get_user_groups add_user_to_group_impl remove_user_from_group
                remove_group change_pass get_pass_hash login_user
                logout_user get_session exists_user generate_pass_hash
                exist_user_in_group is_user_admin create_admin_user
                list_users create_admin_user
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
    my $pass_hash = generate_pass_hash($pass);
    

    if(exists_users_db_file()){
        # file user.db exists
        if(exists_user($user_name)){
            # username entered already exists, show error message
            print "user: ".$user_name." already exists, cannot add existing user.\n";
        } else {
            # file exists, new user, add user to file
            append_user_to_users_db_file($user_name,$pass_hash);
            print "user: ".$user_name." successfully added.\n";
        }
    } else {
        # user.db not exists
        if(exists_base_dir()){
            # /opt/.mycvs exists create file user.db and add the user
            append_user_to_users_db_file($user_name,$pass_hash);
            print "user: ".$user_name." successfully added.\n";
        } else {
            # CANT ADD USER WHEN THERE IS NO .MYCVS INITIALIZED IN OPT
            # SEE WHAT IS THE SOLUTION
            print "repository is not initialized.\n";
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

    if (exists_users_db_file()) {

        return search_pattern_in_line_begining($username,$MYCVS_USERS_DB);

    } else {
        print "please initialize mycvs.\n";
    }
}

# Check if users db exist
sub exists_users_db_file {
    if (-e $MYCVS_USERS_DB) { return 1 }
    return 0;
}

# Creates user db
sub create_user_db {

}

###################################################################

############################# GROUPS ##############################

# Creates group record in DB
sub create_group_record {
    my ($group_name) = @_;
    if(exists_groups_db_file()){
        # file groups.db exists
        if(exists_group($group_name)){
            # group entered already exists, show error message
            print "group: ".$group_name." already exists, cannot add existing group.\n";
        } else {
            # file exists, new user, add user to file
            append_group_to_groups_db_file($group_name);
            print "group: ".$group_name." successfully added.\n";
        }
    } else {
        # groups.db not exists
        if(exists_base_dir()){
            # /opt/.mycvs exists create file groups.db and add the group
            append_group_to_groups_db_file($group_name);
            print "group: ".$group_name." successfully added.\n";
        } else {
            # CANT ADD USER WHEN THERE IS NO .MYCVS INITIALIZED IN OPT
            # SEE WHAT IS THE SOLUTION
            print "repository is not initialized.\n";
        }
    }
}

# appends to end of groups.db file the new group
sub append_group_to_groups_db_file {
    my($group_name) = @_;
    open(my $fh, '>>', $MYCVS_GROUPS_DB) or die "\n\nerror opening groups.db file\n\n";
    print $fh "$group_name:\n";
    close($fh);
}

# returns true if file groups.db exists else false
sub exists_groups_db_file{
    if (-e $MYCVS_GROUPS_DB) { return 1 }
    return 0;
}

# returns true if group passed in exists else false
sub exists_group{
    my ($group_name) = @_;

    if (exists_groups_db_file()) {

        return search_pattern_in_line_begining($group_name,$MYCVS_GROUPS_DB);

    } else {
        print "please initialize mycvs.\n";
    }
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
        print "user: $user_name not exists.\n"
    }
    return @groups;
}

# Adds user to group. If group not exists prints error
sub add_user_to_group_impl {
    my ($user_name, $group_name) = @_;
    if(exists_user($user_name)){
        # user exists in users.db
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
                if($row_splited[0] eq $group_name){
                    # group name found, now check if user already exsists in group
                    if($row_splited[1] =~ /$user_name/){
                        # user name already exists in group, keep moving on
                        print "user: $user_name is already in group: $group_name\n";
                        print $out $row;
                    } else {
                        # user addition to group
                        @group_splited = split(/\n/,$row,2); # escaping the \n in the end of the line.
                        print $out $group_splited[0].$user_name.":\n";
                        print "user: $user_name added successfully to group: $group_name\n";
                    }
                } else {
                    # group name not found keep on the loop
                    print $out $row;
                }
            }

            close ($in);
            close ($out);

            rename ($outfile, $infile) || die "Unable to rename: $!"; # rename the temp file to the original file.

        } else {
            # wrong group name
            print "group: $group_name not exists.\n"
        }
    } else {
        # wrong user name
        print "user: $user_name not exists.\n"
    }
}

# Removes user from group
sub remove_user_from_group {
    my ($user_name, $group_name) = @_;
    if(exists_user($user_name)){
        # user exists in users.db
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
                if($row_splited[0] eq $group_name){
                    # group name found, now check if user already exsists in group
                    if($row_splited[1] =~ /$user_name/){
                        my $new_row = $row_splited[1] =~ s/$user_name//g;
                        $new_row =~ s/:://g;
                        print $out $new_row;
                    }
                } else {
                    # group name not found keep on the loop
                    print $out $row;
                }
            }

            close ($in);
            close ($out);

            rename ($outfile, $infile) || die "Unable to rename: $!"; # rename the temp file to the original file.

        } else {
            # wrong group name
            print "group: $group_name not exists.\n"
        }
    } else {
        # wrong user name
        print "user: $user_name not exists.\n"
    }
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

    } else {
        # wrong group name
        print "group: $group_name not exists.\n"
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
    my $group_pattern = "^$groupname";

    open(my $fh, '<:encoding(UTF-8)', $groups_db_path);

    while(my $row = <$fh>){
        chomp $row;
        if($row =~ /$group_pattern/){
            # group found
            my @users = split(':',$row);
            foreach my $user (@users){
                if($username eq $user) { return 1; }
            }
            return 0;
        }
    }
    return 0;
}

# Will check if user is admin user
sub is_user_admin {
    my ($username) = @_;
    my @admins = list_admin_users();
    foreach my $admin(@admins) {
        if ($admin eq $username) {
            return 0;
        }
    }
    return 1;
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
    if (-f $MYCVS_ADMINS_DB) {
        return;
    }
    my @lines = read_lines_from_file($MYCVS_ADMINS_DB);
    return split(' ', @lines);
}



1;