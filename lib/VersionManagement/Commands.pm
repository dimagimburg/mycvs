#!/bin/env perl
package VersionManagement::Commands;
use strict; use warnings;

# Perl libs & vars
use File::Basename;
use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(
                checkin_file checkout_file print_revision_diff
                print_revisions
                );
# Internal libs
use lib qw(../);
use VersionManagement::Impl;

# Checks in file. If first checkin uses function checkin_first.
# also creates $filename.rev_num.diff. File will include reverse diff of file
# + TimeStamp of date when created.
sub checkin_file {
    my ($file_path) = @_;
    die "'$file_path' $!.\n" if (! -f $file_path);
    
    make_checkin($file_path);
}

# Checkouts file from repository at given revision.
# Prints error if file not in repository or revision not found.
# If revision not defined users last revision
sub checkout_file {
    my ($file_path, $revision) = @_;
    die "'$file_path' $!.\n" if (! -f $file_path);
    make_checkout($file_path, $revision);
}

# Prints diff in prety form at given revision
# If revision not defined users last revision.
sub print_revision_diff  {
    my ($file_path, $revision) = @_;
    my @lines = get_diff($file_path,$revision);
    if (! @lines) {
        print "There are no diferences.\n";
    } else {
        # Print diff. 
        foreach(@lines) {
            print $_;
        }
    }
}

# Prints all revisions of file in pretty form.
# Probably won't be implemented :))
# Example:
# FileName: <>
# Revision: <>, TimeStamp: <>
# Revision: <>, TimeStamp: <>
sub print_revisions {
    my ($file_path) = @_;
    my @revisions = get_revisions($file_path);
    my $index = 0;
    
    if (@revisions) {
        print "Revisions for the file: '$file_path':\n";
        print "==========================================\n";
        foreach(@revisions) {
            my $diff_file = dirname($file_path)."/.mycvs/".basename($file_path).".$_.diff";
            my $timestamp = format_time_stamp(get_file_time($diff_file));
            printf ("Revision: %4d, Timestamp: %s", $_, $timestamp) if defined($_);
            if ($index <=> $#revisions) {
                print "\n";
            } else {
                print " <--- Latest revision\n";
            }
            $index++;
        }
    } else {
        die "Can't find revisions of given file.\n";
    }
}

1;
