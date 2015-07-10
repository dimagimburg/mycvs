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
    make_checkin($file_path);
}

# Checkouts file from repository at given revision.
# Prints error if file not in repository or revision not found.
# If revision not defined users last revision
sub checkout_file {
    my ($file_path, $revision) = @_;
}

# Prints diff in prety form at given revision
# If revision not defined users last revision.
sub print_revision_diff  {
    my ($file_path, $revision) = @_;
    my @lines = get_diff($file_path,$revision);
    foreach(@lines) {
        print $_;
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
    
    if (@revisions) {
        print "Revisions for the file: '$file_path':\n";
        print "==========================================\n";
        foreach(@revisions) {
            my $diff_file = dirname($file_path)."/.mycvs/".basename($file_path).".$_.diff";
            my $timestamp = format_time_stamp(get_file_time($diff_file));
            printf ("Revision: %4d, Timestamp: %s\n", $_, $timestamp) if defined($_);
        }
    } else {
        die "Can't find revisions of given file.\n";
    }
    
}

1;
