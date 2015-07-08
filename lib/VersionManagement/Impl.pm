#!/bin/env perl
package VersionManagement::Impl;
use strict; use warnings;

# Perl libs & vars
use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(
                make_checkin make_checkout get_diff
                get_revisions
                );

# Checks in file. If first checkin uses function checkin_first.
# also creates $filename.rev_num.diff. File will include reverse diff of file
# + TimeStamp of date when created.
sub make_checkin {
    my ($file_path) = @_;
    
}

# Add new file to repository also creates $filename.rev_num.diff file under .mycvs directory
# at the same level as file. Uses: RepoManagement::Init::init_local() that will create .mycvs dir
# if not exists.
sub checkin_first {
    my ($file_path) = @_;
    
}

# Checkouts file from repository at given revision.
# Prints error if file not in repository or revision not found.
# If revision not defined users last revision
sub make_checkout {
    my ($file_path, $revision) = @_;
}

sub get_diff {
    my ($file_path, $revision) = @_;
    my $old_diff = '';
    if (defined($revision)) {
        $old_diff = $file_path.'.'.$revision.'.'.'diff';
    } else {
        $old_diff = $file_path.'.'.'diff';
    }
    
    # If given revision file not found exit
    #open(old_handle, $old_file) or die "Unable to open given revision. $!\n";
    
    
}
# Merges diff on file. Receives file and diff as array of lines
# Returns new file as array. pass then with \@
sub merge_diif_on_file {
    my ($file, $diff) = @_;
    # Nasty PERL references. Ahhrrrrr :(
    my @file_array = @$file; my @diff_array = @$diff;
    my @new_array = ();
    
    foreach my $row(@diff_array) {
        my @values = split(' ', $row);
        my $file_row_op = $values[0]; # Extract row operation
        my $file_row_num = $values[1]; # Extract row number
        undef @values;
        
    }
    
}
# Returns diff of file from repository at given revision.
# Prints error if file not in repository or revision not found.
# if revision not defined uses latest revision
# Returns diff array between two files, each cell represents
# Cangeset. <-+> <line_num> <if + then here text>. Example
# - 2
# + 2 Some text
sub get_diff_on_two_files {
    my ($new_file, $old_file) = @_;
#    my $old_file = $file_path.'.'.$revision.'.'.'diff';
    my @diff = (); # diff lines
    my ($old_line, $new_line);
    
    open(new_handle, $new_file) or die "Unable to open file. $!. Is it exists?\n";
    open(old_handle, $old_file) or die "Unable to open previous revision. $!\n";
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

# Returns all revision of given file
sub get_revisions {
    my ($file_path) = @_;
}

1;