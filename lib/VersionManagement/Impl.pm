#!/bin/env perl
package VersionManagement::Impl;
use strict; use warnings;

# Perl libs & vars
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
                delete_file get_dir_contents_recur
                );

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
            return;
        }
        
        my @diff_rev = get_diff_on_two_files($file_path, $prev_revision_file);
        if (! @diff_rev) {
            print "Only timestamp changed in file. Nothing to checkin.\n";
            return;
        }
        
        my $prev_time = get_file_time($prev_revision_file);
        save_lines_array_to_file(\@diff_rev, $prev_revision_file);
        set_file_time($prev_revision_file, $prev_time);
    }
    
    copy $file_path, $next_revision_file;
    set_file_time($next_revision_file,get_file_time($file_path));
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
    #@lines = read_lines_from_file($file_path);
    #$timestamp = get_file_time($file_path);
    unlink $file_path;
    
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
    }
    
    if (grep (/^$revision$/, @revisions)) {
        # Found needed revision. will merge diff before copy.
        my $latest_diff = dirname($file_path).'/.mycvs/'.basename($file_path).'.'.$revisions[-1].'.diff';
        my $given_diff = dirname($file_path).'/.mycvs/'.basename($file_path).'.'.$revision.'.diff';
        
        copy $latest_diff, $file_path or die "Cant\'t find one of the revisions.\n";
        
        my @latest_lines = read_lines_from_file($file_path);
        my @diff_to_merge = get_diff($file_path, $revision);
        @merged_file = merge_back_diff_on_file(\@latest_lines, \@diff_to_merge);
        #save_lines_array_to_file(\@merged_file, $file_path);
        #$timestamp = get_file_time($given_diff);
        #set_file_time($file_path, get_file_time($given_diff));
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
    if (($revision > 0) && ($revision <= $revisions[-1])) {
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
    open(file_handle, ">$filename") or die "Can't save file.\n";
    foreach my $line(@array) {
        print file_handle $line;
    }
    close(file_handle)
}

sub save_string_to_new_file {
    my ($str, $filename) = @_;
    open(file_handle, ">$filename") or die "Can't save file.\n";
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
# Returns diff of file from repository at given revision.
# Prints error if file not in repository or revision not found.
# if revision not defined uses latest revision
# Returns diff array between two files, each cell represents
# Cangeset. <-+> <line_num> <if + then here text>. Example
# - 2 Some old text
# + 2 Some new text
sub get_diff_on_two_files {
    my ($new_file, $old_file) = @_;
#    my $old_file = $file_path.'.'.$revision.'.'.'diff';
    my @diff = (); # diff lines
    my ($old_line, $new_line);
    
    open(new_handle, $new_file) or die "Unable to open file. $!. Is it exists?\n";
    open(old_handle, $old_file) or die "Unable to open previous revision. $!.\n";
    #if (! -T $file_path) {
    #    return; # Given file is binary file. Not trying to diff it
    #}

    while ($new_line = <new_handle>) {
        $old_line = readline old_handle;
        # Stop if we can't read old file anymore
        if (! defined($old_line)) {last;}
        
        if ($new_line ne $old_line) {
            push @diff, '- '.$..' '.$old_line;
            push @diff, '+ '.$..' '.$new_line;
        }
    }
    # If we still have more lines in one of the files, read them all
    # Read till end of old file and mark all 'spare' lines as -
    # in new file diff
    while ($old_line = <old_handle>) {
        push @diff, '- '.$..' '.$old_line;
    }
    # Read till end of new file and mark all 'spare' lines as +
    # in new file diff. Also make sure that we not missing line
    while ($new_line) {
        push @diff, '+ '.$..' '.$new_line;
        $new_line = readline new_handle;
    }
    close(new_handle); close(old_handle);
    return @diff;
}

# Returns all revision of given file.
# sorted.
sub get_revisions {
    my ($file_path)   = @_;
    my $rev_index = -2;
    my $file_dir_name = dirname($file_path);
    my $file_name     = basename($file_path);
    my (@files, @revisions);
    @revisions = ();
    
    @files = get_dir_contents($file_dir_name, $file_name);
                #or die "No revisions for the whole folder. Checkin something.\n";
    
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
    
    @files = grep {/^${expr}/} readdir dir_handle;
    
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
    return @$files;
}

sub _wanted {
   return if ! -e;
   my ($files, $dir) = @_;

   $File::Find::name =~ s/^${dir}//;
   return if $File::Find::name eq "";
   return if $File::Find::name =~ /lock/;

   push( @$files, $File::Find::name ) if $File::Find::name!~ /\.mycvs/;
}


sub format_time_stamp {
    my ($timestamp) = @_;
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
    delete_file($file_path);
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
    my @files = ();
    my $dir = dirname($filename);
    $filename = basename($filename);
    
    
    if (! -d $dir) {
        return; # Return undef
    }
    
    opendir(dir_handle, $dir);
    
    @files = grep {/${filename}\.lock/} readdir dir_handle;
    
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
    my $username;
    
    if (is_file_locked($file_path)) {
        my $lockfile = get_lock_file($file_path);
        $username = (split('\.', $lockfile))[2];
        return $username;
    } else {
        return;
    }
}

sub delete_file {
    my ($file_path) = @_;
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

1;