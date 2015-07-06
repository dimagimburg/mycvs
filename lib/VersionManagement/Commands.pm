#!/bin/env perl
package VersionManagement::Commands;
use strict; use warnings;

# Perl libs & vars
use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(
                checkin_file checkout_file print_revision_diff
                print_revisions
                );

# Checks in file. If first checkin uses function checkin_first.
# also creates $filename.rev_num.diff. File will include reverse diff of file
# + TimeStamp of date when created.
sub checkin_file {
    my ($file_path) = @_;
    
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
}

# Prints all revisions of file in pretty form.
# Probably won't be implemented :))
# Example:
# FileName: <>
# Revision: <>, TimeStamp: <>
# Revision: <>, TimeStamp: <>
sub print_revisions {
    
}

1;