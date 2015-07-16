#!/bin/env perl
package VersionManagement::Commands;
use strict; use warnings;

# Perl libs & vars
use File::Basename;
use Exporter qw(import);
use Cwd;
use Cwd qw(realpath);
our @ISA = qw(Exporter);
our @EXPORT = qw(
                checkin_file checkout_file print_revision_diff
                print_revisions
                );
# Internal libs
use lib qw(../);
use VersionManagement::Impl;
use HTTP::HttpServerRequests;

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
    my ($timestamp, @lines_array) = make_checkout($file_path, $revision);
    if ((!defined($timestamp)) || (@lines_array)) {
        die "Revision: '$revision' does not exists.\n";
    }
    save_lines_array_to_file(\@lines_array, $file_path);
    set_file_time($file_path, $timestamp);
}



# Prints diff in prety form at given revision
# If revision not defined users last revision.
sub print_revision_diff  {
    my ($file_path, $revision) = @_;
    
    die "No file given.\n" if ! defined($file_path);
    die "Given file not exists.\n" if ! -f $file_path;
    
    my @lines = get_remote_plain_diff(realpath($file_path), $revision);
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
    if (! -f $file_path) {
        print "File not found locally.\nChecking remote repository...\n\n";
    }
    
    my @revisions = get_remote_revisions(realpath($file_path));
    my $index = 0;

    
    if (@revisions) {
        print "Revisions for the file: '$file_path':\n";
        print "==========================================\n";
        foreach(@revisions) {
            print $_."\n";
        }
    } else {
        die "Can't find revisions of given file.\n";
    }
}

1;
