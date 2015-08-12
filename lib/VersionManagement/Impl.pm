#!/bin/env perl
package VersionManagement::Impl;
use strict; use warnings;

# Perl libs & vars
use Data::Dumper;
use File::Basename;
use File::Find;
use File::Copy qw(copy);
use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(
                make_checkin make_checkout get_diff
                get_revisions format_time_stamp get_file_time set_file_time
                save_lines_array_to_file read_lines_from_file merge_back_diff_on_file
                get_revisions get_dir_contents format_time_stamp get_file_time
                set_file_time is_file_locked get_locked_user save_string_to_new_file
                get_timestamp get_merged_plain_file lock_file unlock_file is_file_locked
                delete_file get_dir_contents_recur print_revisions_to_array
                get_diff_on_two_files mark_last_user get_last_user
                );
# Internal libs
use lib qw(../);
use RepoManagement::Configuration qw($MYCVS_DB_FOLDER);

# Checks in file. If first checkin uses function checkin_first.
# also creates $filename.rev_num.diff. File will include reverse diff of file
# + TimeStamp of date when created.
sub make_checkin {
    my ($file_path) = @_;
    RepoManagement::Init::init_local(dirname($file_path));
    my @revisions = get_revisions($file_path);
    my $next_revision = 1;
    
    if (@revisions) {
        $next_revision = $next_revision + $revisions[-1];
    }
    
    my $next_revision_file = dirname($file_path).'/.mycvs/'.basename($file_path).'.'.$next_revision.'.diff';
    
    if ($next_revision > 1) {
        my $prev_revision_file = dirname($file_path).'/.mycvs/'.basename($file_path).'.'.$revisions[-1].'.diff';
        if (get_file_time($prev_revision_file) == get_file_time($file_path)) {
            print "Nothing changed in file. Nothing to checkin.\n";
            return 2;
        }
        
        my @diff_rev = get_diff_on_two_files($file_path, $prev_revision_file);
        if (! @diff_rev) {
            print "Only timestamp changed in file. Nothing to checkin.\n";
            return 3;
        }
        
        my $prev_time = get_file_time($prev_revision_file);
        save_lines_array_to_file(\@diff_rev, $prev_revision_file);
        set_file_time($prev_revision_file, $prev_time);
    }
    
    copy $file_path, $next_revision_file;
    set_file_time($next_revision_file,get_file_time($file_path));
}
# Saves the last user that did checkin
sub mark_last_user {
    my ($filename, $username) = @_;
    if (!defined($filename) || ! -f $filename) {
        return;
    }
    my $marker_file = get_last_user_marker($filename);
    
    if (defined($marker_file)) {
        my $dir = dirname($filename);
        delete_file("$dir/$marker_file");
    }
    save_string_to_new_file("", $filename.'.last_checkin.'.$username);
    
}
# Gets last user that made checkin on file
sub get_last_user {
    my ($file_path) = @_;
    my ($username, $marker_file, @splitted);
    $marker_file = get_last_user_marker($file_path);
    
    if (defined($marker_file)) {
        @splitted = split('\.', $marker_file);
        $username = $splitted[-1];
        return $username;
    } else {
        return;
    }
}
# Gets last user marker file
sub get_last_user_marker {
    my ($filename) = @_;
    return if ! defined($filename);
    my @files = ();
    my $dir = dirname($filename);
    $filename = basename($filename);
    
    
    if (! -d $dir) {
        return; # Return undef
    }
    
    opendir(dir_handle, $dir);
    
    @files = grep {/\Q${filename}.last_checkin\E/} readdir dir_handle;
    
    closedir(dir_handle);
    if (@files) {
        return $files[0];
    } else {
        return;
    }
}

# Returns merged file lines array at specific revision
sub get_merged_plain_file {
    my ($file_path, $revision) = @_;
    my @lines = ();
    my $timestamp = 0;
    if (! defined($file_path)) {
        return;
    }
    ($timestamp, @lines) = make_checkout($file_path, $revision);
    
    return ($timestamp, @lines);
}

# Checkouts file from repository at given revision.
# Prints error if file not in repository or revision not found.
# If revision not defined users last revision
# returns timesamp and merged array of file lines
sub make_checkout {
    my ($file_path, $revision) = @_;
    my @revisions = get_revisions($file_path);
    my $timestamp; my @merged_file;
    
    if (! defined($revision)) {
        # Will get the latest file if available.
        $revision = 1;
        $revision = $revisions[-1] if @revisions;
    }
    
    if (grep (/^$revision$/, @revisions)) {
        # Found needed revision. will merge diff before copy.
        my $latest_diff = dirname($file_path).'/.mycvs/'.basename($file_path).'.'.$revisions[-1].'.diff';
        my $given_diff = dirname($file_path).'/.mycvs/'.basename($file_path).'.'.$revision.'.diff';
        
        #copy $latest_diff, $file_path or die "Cant\'t find one of the revisions.\n";
        
        my @latest_lines = read_lines_from_file($file_path);
        my @diff_to_merge = get_diff($file_path, $revision);
        @merged_file = merge_back_diff_on_file(\@latest_lines, \@diff_to_merge);
        $timestamp = get_file_time($given_diff);
    } else {
        return;
    }
    return ($timestamp, @merged_file);
}

# Recieves file_path and revision to compare
# Returns diff between given file and given revision
# If revision not given returns diff between file and last revision.
sub get_diff {
    my ($file_path, $revision) = @_;
    my @diff = ();
    
    if (! defined($revision)) {
        $revision = 0;  # Get last revision if exists
    } elsif ($revision <= 0) {
        die "Incorrect revision.\n";
    }
    
    
    my @revisions = get_revisions($file_path);
    
    my $last_rev_path = dirname($file_path).'/.mycvs/'.basename($file_path).'.'.$revisions[-1].'.diff';
    
    @diff = get_diff_on_two_files($file_path, $last_rev_path);
    
    if (($revision > 0) && ($revision < $revisions[-1])) {
        # First merge is different.
        my @old_rev_lines = read_lines_from_file($last_rev_path);
        @old_rev_lines = merge_back_diff_on_file(\@old_rev_lines, \@diff);
        
        for (my $i = 2; $revision < $revisions[-1]; $i++) {
            $last_rev_path = dirname($file_path).'/.mycvs/'.basename($file_path).'.'.$revisions[0-$i].'.diff';
            @diff = read_lines_from_file($last_rev_path);
            @old_rev_lines = merge_back_diff_on_file(\@old_rev_lines, \@diff);
            
            $revision++;
        }
        # Temporary save file
        save_lines_array_to_file(\@old_rev_lines, $file_path.'.merged');
        @diff = get_diff_on_two_files($file_path, $file_path.'.merged');
        delete_file($file_path.'.merged');
    }
    
    return @diff;
}
# Read file to array of lines.
sub read_lines_from_file {
    my ($file) = @_;
    open(file_handle, $file) or die "$!.\n";
    my @lines = <file_handle>;
    close file_handle;
    return @lines;
}
sub save_lines_array_to_file {
    my ($arr, $filename) = @_;
    my @array = @$arr;
    RepoManagement::Init::check_and_create_dir(dirname($filename));
    open(file_handle, ">$filename") or die "Can't save file. save lines array to file\n";
    foreach my $line(@array) {
        print file_handle $line;
    }
    close(file_handle)
}

sub save_string_to_new_file {
    my ($str, $filename) = @_;
    RepoManagement::Init::check_and_create_dir(dirname($filename));
    open(file_handle, ">$filename") or die "Can't save file. save string to new file\n";
    print file_handle $str;
    close(file_handle)
}
# Merges diff on file. Receives file and diff as array of lines (pass array with \@)
# Returns new file as array. 
sub merge_back_diff_on_file {
    my ($file, $diff) = @_;
    # Nasty PERL references. Ahhrrrrr :(
    my @file_array = @$file; my @diff_array = @$diff;
    
    foreach my $row(@diff_array) {
        my @values       = split(' ', $row);
        my $file_row_op  = $values[0]; # Extract row operation
        my $file_row_num = $values[1]; # Extract row number
        shift(@values); shift(@values); # Eliminate +- and row number
        my $file_row_txt = join(' ', @values); # Get row text
        
        undef @values;
        
        # Because we using reverse logic. We will treat
        # + as - line and - as + line. Tricky :)
        if ($file_row_op eq '+') {
            # Remove line in file_array that wasn't exist in previous revision
            splice @file_array, ($file_row_num-1), 1;
        } elsif ($file_row_op eq '-') {
            # Add line
            splice @file_array, ($file_row_num), 0, $file_row_txt."\n";
        } else {
            # We found undefined operation sign. Shouldn't be here.
            die "Found undefined diff operator. Probably corrupted file.\n";
        }
    }
    return @file_array;
    
}

# returns index of line when change end
sub check_where_change_end {
    my ($oldf, $newf, $old_index, $new_index) = @_;
    my @old_lines = @$oldf;
    my @new_lines = @$newf;
    my $new_len = @new_lines;
    my $old_len = @old_lines;
    
    return if $new_index >= $new_len; # we can't read more from new file
    return if $old_index >= $old_len; # we can't read more from old file
    
    for (my $index = $old_index; $index < $old_len; $index++) {
        if ($old_lines[$index] eq $new_lines[$new_index]) {
            return $index;
        }
    }
    return;
}
# Returns diff of file from repository at given revision.
# Prints error if file not in repository or revision not found.
# if revision not defined uses latest revision
# Returns diff array between two files, each cell represents
# Cangeset. <-+> <line_num> <if + then here text>. Example
# - 2 Some old text
# + 2 Some new text
sub get_diff_on_two_files {
    my ($new_file, $old_file) = @_;
    my @old_lines = read_lines_from_file($old_file);
    my @new_lines = read_lines_from_file($new_file);
    my $new_len = @new_lines;
    my $old_len = @old_lines;
    my $new_counter; my $old_counter = 0;
    my @diff = ();
    
    for ($new_counter = 0; $new_counter < $new_len; $new_counter++) {
        # Stop if old file doesn't have anymore lines to read
        if ($old_counter >= $old_len) {
            # We reached end on old file but not new file.
            # Lets save it
            push @diff, '+ '.($old_counter+1).' '.$new_lines[$old_counter];
            next;
        }
        
        if ($new_lines[$new_counter] ne $old_lines[$old_counter]) {
            # we detected change on line
            my $after_removed_index = check_where_change_end(\@old_lines, \@new_lines, $old_counter, $new_counter);
            my $after_added_index   = check_where_change_end(\@new_lines, \@old_lines, $new_counter, $old_counter);
            
            if (defined($after_removed_index)) {
                # We detected removed lines. lets save them
                for (; $old_counter < $after_removed_index; $old_counter++) {
                    push @diff, '- '.($old_counter+1).' '.$old_lines[$old_counter];
                }
            }
            elsif (defined($after_added_index)) {
                # We detected added lines. lets save them
                for (; $new_counter < $after_added_index; $new_counter++) {
                    push @diff, '+ '.($old_counter+1).' '.$new_lines[$new_counter];
                }
            }
            else {
                # The line was only changed
                push @diff, '- '.($old_counter+1).' '.$old_lines[$old_counter];
                push @diff, '+ '.($old_counter+1).' '.$new_lines[$new_counter];
            }
            
        }
        $old_counter++;
    }
    # If we still have old file lines unsaved so they got removed from new file
    while ($old_counter < $old_len) {
        push @diff, '- '.($old_counter+1).' '.$old_lines[$old_counter];
        $old_counter++;
    }
    
        
    return @diff;
}

# Returns all revision of given file.
# sorted.
sub get_revisions {
    my ($file_path)   = @_;
    my $rev_index     = -2;
    my $file_dir_name = dirname($file_path);
    my $file_name     = basename($file_path);
    my (@files, @revisions);
    @revisions = ();
    
    @files = get_dir_contents($file_dir_name, $file_name.'.');
    
    foreach my $file(@files) {
        next if -d $file; # Skip if we got dir by mistake.
        my @splited = split('\.', $file);
        push @revisions, $splited[$rev_index] if $splited[$rev_index] ;
    }
    
    @revisions = sort {$a <=> $b} @revisions;
    
    return @revisions;
}

# Returns list of files in given directory based on EXPR.
# Returns undef if can't open dir.
sub get_dir_contents {
    my ($dir, $expr) = @_;
    my @files = ();
    $dir = "$dir/.mycvs";
    
    if (! -d "$dir") {
        return; # Return undef
    }
    
    opendir(dir_handle, $dir);
    
    @files = grep {/^\Q${expr}\E/} readdir dir_handle;
    
    closedir(dir_handle);
    return @files;
}

sub get_dir_contents_recur {
    my ($dirname) = @_;
    my $files= [];
    my $wanted = sub { _wanted($files, $dirname) };
    if (! -d $dirname) {
        return;
    }
    
    find($wanted, $dirname);
    return sort(@$files);
}

sub _wanted {
   return if ! -e;
   return if -d;
   my ($files, $dir) = @_;

   $File::Find::name =~ s/^${dir}//;
   return if $File::Find::name eq "";
   return if $File::Find::name =~ /\.lock\./;
   return if $File::Find::name =~ /\.last_checkin\./;

   push( @$files, $File::Find::name ) if $File::Find::name!~ /\.mycvs/;
}


sub format_time_stamp {
    my ($timestamp) = @_;
    if (!defined($timestamp)) {
        $timestamp = 0;
    }
    
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($timestamp);
    my $pretty_time = sprintf("%02d-%02d-%02d_%02d-%s-%d",
                       $hour, $min, $sec, $mday, $months[$mon], $year+1900);
    return $pretty_time;
}

sub get_file_time {
    my ($file) = @_;
    my @file_props = stat($file);
    return $file_props[9];
}

sub set_file_time {
    my ($file, $timestamp) = @_;
    return utime($timestamp, $timestamp, $file);
}

sub lock_file {
    my ($file_path, $user) = @_;
    my $lockfile = $file_path.'.lock.'.$user;
    if (is_file_locked($file_path)) {
        return 0;
    } else {
        save_string_to_new_file("", $lockfile);
        return 1;
    }
}

sub unlock_file {
    my ($file_path) = @_;
    if (!defined($file_path)) {
        return;
    }
    my $dir = dirname($file_path);
    my $lock_file_name = get_lock_file($file_path);
    if (defined($lock_file_name)) {
        delete_file("$dir/$lock_file_name");
    }
}

# Checks if file locked.
sub is_file_locked {
    my ($file_path) = @_;
    if (defined(get_lock_file($file_path))) {
        return 1;
    } else {
        return 0;
    }
}

sub get_lock_file {
    my ($filename) = @_;
    #return if ! defined($filename);
    my @files = ();
    my $dir = dirname($filename);
    $filename = basename($filename);
    
    
    if (! -d $dir) {
        return; # Return undef
    }
    
    opendir(dir_handle, $dir);
    
    @files = grep {/\Q${filename}.lock\E/} readdir dir_handle;
    
    closedir(dir_handle);
    if (@files) {
        return $files[0];
    } else {
        return;
    }
}

# returns username of user that locked file.
sub get_locked_user {
    my ($file_path) = @_;
    my ($username, @splitted);
    
    if (is_file_locked($file_path)) {
        my $lockfile = get_lock_file($file_path);
        @splitted = split('\.', $lockfile);
        $username = $splitted[-1];
        return $username;
    } else {
        return;
    }
}

sub delete_file {
    my ($file_path) = @_;
    return if !defined $file_path;
    if (-f $file_path) {
        unlink $file_path;
    }
}

sub get_timestamp {
    my ($file_path, $revision) = @_;
    if (!defined($file_path)) {
        return;
    }
    
    if (!defined($revision)) {
        $revision = 1;
    }
    my $real_file_name = dirname($file_path).'/.mycvs/'.basename($file_path).'.'.$revision.'.diff';
    
    if (! -f $real_file_name) {
        return;
    }
    
    return get_file_time($real_file_name);
}

sub print_revisions_to_array {
    my ($file_path) = @_;
    my @revisions = get_revisions($file_path);
    my @lines;
    my $index = 0;
    my $line_index = 0;
    
    if (@revisions) {
        foreach(@revisions) {
            my $diff_file = dirname($file_path)."/.mycvs/".basename($file_path).".$_.diff";
            my $timestamp = format_time_stamp(get_file_time($diff_file));
            if (!defined($timestamp)) {
                $timestamp = 0;
            }
            
            $lines[$line_index++] = sprintf ("Revision: %4d, Timestamp: %s", $_, $timestamp) if defined($_);
            if ($index <=> $#revisions) {
                $lines[$line_index++] = sprintf "\n";
            } else {
                $lines[$line_index++] = sprintf " <--- Latest revision\n";
            }
            $index++;
        }
    } else {
        return;
    }
    return @lines;
}

sub check_if_admin_file_exists{
    if (-e $MYCVS_DB_FOLDER."/admins.db") { return 1 }
    return 0;
}

sub check_if_admin_exists{
    if (-s $MYCVS_DB_FOLDER."/admins.db") {
        return 1;
    }
    return 0;
}

1;