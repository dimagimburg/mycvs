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

# Returns diff of file from repository at given revision.
# Prints error if file not in repository or revision not found.
# if revision not defined users latest revision
sub get_diff {
    my ($file_path, $revision) = @_;
}

# Returns all revision of given file
sub get_revisions {
    my ($file_path) = @_;
}

1;