#!/bin/env perl
package VersionManagement::Commands;
use strict; use warnings;

# Perl libs & vars
use File::Basename;
use File::Copy qw(move);
use Exporter qw(import);
use Cwd;
use Cwd qw(realpath);
our @ISA = qw(Exporter);
our @EXPORT = qw(
                checkin_file checkout_file print_revision_diff
                print_revisions print_file_list print_local_files_diff
                );
# Internal libs
use lib qw(../);
use VersionManagement::Impl;
use RepoManagement::Init;
use HTTP::HttpServerRequests;
use RepoManagement::Configuration qw($MYCVS_REMOTE_SUFFIX);

# Checks in file. If first checkin uses function checkin_first.
# also creates $filename.rev_num.diff. File will include reverse diff of file
# + TimeStamp of date when created.
sub checkin_file {
    my ($file_path) = @_;
    die "You must provide at least filename to this command.\n" if ! defined $file_path;
    die "Local file not found.\n" if ! -f $file_path;
    
    my ($current_user, $last_user) = get_remote_last_user(realpath($file_path));
    if (defined($last_user) && ($last_user ne $current_user)) {
        print "Last checkin not made by you.\n";
        print "Last user that made checkin is: '$last_user'.\n";
        print "If not sure, you can view diff before checkin.\n";
        print "Do you want to force checkin? [y/n] (n - default) ";
        my $answer = <STDIN>; chomp $answer;
        if ($answer ne "y") {
            die "Canceling checkin...\n";
        }
    }
    
    my $reply = post_remote_checkin(realpath($file_path));
    die "Can't checkin.\n" if ! defined($reply);
    print $reply;
}

# Checkouts file from repository at given revision.
# Prints error if file not in repository or revision not found.
# If revision not defined uses last revision
sub checkout_file {
    my ($file_path, $revision) = @_;
    die "You must provide at least filename to this command.\n" if ! defined $file_path;
    print "Local file not found. Trying to get from remote...\n" if ! -f $file_path;
    
    get_remote_checkout(realpath($file_path), $revision);
    
    if (-f $file_path) {
        print "Do you want to overwrite existing file?[y/n] (y - default) ";
        my $answer = <STDIN>; chomp $answer;
        if ($answer ne "n") {
            delete_file($file_path);
            move ($file_path.'.'.$MYCVS_REMOTE_SUFFIX, $file_path);
        }
    } else {
        move ($file_path.'.'.$MYCVS_REMOTE_SUFFIX, $file_path);
    }
}



# Prints diff in prety form at given revision
# If revision not defined users last revision.
sub print_revision_diff  {
    my ($file_path, $revision) = @_;
    if (! defined($file_path) && defined($revision)) {
        die "You need to specify filename.\n";
    }
    
    die "No file given.\n" if ! defined($file_path);
    die "Given file not exists.\n" if ! -f $file_path;
    
    my @lines = get_remote_plain_diff(realpath($file_path), $revision);
    if (! @lines) {
        print "There are no diferences.\n";
    } else {
        # Print diff.
        print "Printing diff for file: '$file_path'\n";
        print "=======================\n";
        foreach(@lines) {
            print $_;
        }
    }
}

sub print_local_files_diff {
    my ($new_file, $old_file) = @_;
    if (!defined($old_file) || !defined($new_file)) {
        die "You need to specify two files for diff.\n";
    }
    
    die "'$old_file' not exists.\n" if ! -f $old_file;
    die "'$new_file' not exists.\n" if ! -f $new_file;
    
    my @lines = get_diff_on_two_files($new_file, $old_file);
    if (! @lines) {
        print "There are no diferences.\n";
    } else {
        # Print diff.
        print "Diff for files: '$new_file' and '$old_file'\n";
        print "=======================\n";
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

sub print_file_list {
    my @files = get_remote_repo_content();
    my $reporoot = get_repo_root(getcwd().'/.');
    # Creating hash of local files for easy access
    my %local_files = map { $_ => 1 } get_dir_contents_recur($reporoot.'/');
    chdir $reporoot;
    
    if (!@files && !%local_files) {
        die "Remote Repository and Local store doesn't have files\n";
    }
    print "Listing repository files relative to Reporoot.\n";
    print "Reporoot: '$reporoot'\n";
    print "R - remote, L - local, LR - local&remote\n";
    print "==============================\n";
    foreach my $file(@files) {
        $file =~ s/^\///;
        if (defined($local_files{$file})) {
            print "LR - Filename: '$file'\n";
            delete $local_files{$file};
        } else {
            print "R  - Filename: '$file'\n";
        }
    }
    foreach(keys %local_files) {
        print "L  - Filename: '$_'\n" if ! -d $_;
    }
    
}

1;
