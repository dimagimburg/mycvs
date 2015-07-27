#!/bin/env perl
package RepoManagement::BackupRestoreImpl;
use strict; use warnings;

# Perl libs & vars
use File::Copy qw(move);
use File::Basename;
use File::Find;
use File::Path qw(make_path remove_tree);
use Cwd qw(realpath);
use Archive::Tar;
use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(
                get_db_backups get_repo_backups
                db_backup_do db_restore_do
                repo_backup_do repo_restore_do
                );
                
# Internal libs
use lib qw(../);
#use VersionManagement::Impl;
use UserManagement::Impl;
use RepoManagement::Configuration qw(
                                $MYCVS_DB_FOLDER $MYCVS_REPO_STORE
                                $MYCVS_DB_BACKUP_STORE $MYCVS_REPO_BACKUP_STORE
                                $MYCVS_BACKUP_SUFFIX
                                );
                                
sub get_db_backups {
    my @file_list = get_backup_files($MYCVS_DB_BACKUP_STORE);
    my @backup_list = ();
    foreach my $file(@file_list) {
        $file =~ s/\.${MYCVS_BACKUP_SUFFIX}$//;
        if ($file eq "") {next;} # Skip filename if it includes only $MYCVS_BACKUP_SUFFIX
        
        push @backup_list, $file;
    }
    
    return @backup_list;
}

sub get_repo_backups {
    my ($reponame) = @_;
    if (!defined($reponame) || ! exists_group($reponame)) {
        return;
    }
    
    my @file_list = get_backup_files("$MYCVS_REPO_BACKUP_STORE/$reponame");
    my @backup_list = ();
    foreach my $file(@file_list) {
        $file =~ s/\.${MYCVS_BACKUP_SUFFIX}$//;
        if ($file eq "") {next;} # Skip filename if it includes only $MYCVS_BACKUP_SUFFIX
        
        push @backup_list, $file;
    }
    
    return @backup_list;
}

sub db_backup_do {
    my $dir     = $MYCVS_DB_FOLDER;
    my $dstfile = "$MYCVS_DB_BACKUP_STORE/".format_time_stamp(time)."\.$MYCVS_BACKUP_SUFFIX";
    return create_archive($dir, $dstfile);
}

sub repo_backup_do {
    my ($reponame) = @_;
    if (!defined($reponame) || ! exists_group($reponame)) {
        return 0;
    }
    
    my $dir     = "$MYCVS_REPO_STORE/$reponame";
    my $dstfile = "$MYCVS_REPO_BACKUP_STORE/$reponame/".format_time_stamp(time)."\.$MYCVS_BACKUP_SUFFIX";
    
    return create_archive($dir, $dstfile);
}

sub db_restore_do {
    my ($backupname) = @_;
    my $srcfile = "$MYCVS_DB_BACKUP_STORE/$backupname\.$MYCVS_BACKUP_SUFFIX";
    return 0 if ! -f $srcfile;
    
    return extract_archive($srcfile, $MYCVS_DB_BACKUP_STORE);
}

sub repo_restore_do {
    my ($backupname, $reponame) = @_;
    my $status = 1;
    my $srcfile = "$MYCVS_REPO_BACKUP_STORE/$reponame/$backupname\.$MYCVS_BACKUP_SUFFIX";
    return 0 if ! -f $srcfile;
    
    $status = extract_archive($srcfile, $MYCVS_DB_BACKUP_STORE);
    if ($status == 1 && ! exists_group($reponame)) {
        create_group_record($reponame);
    }
    return $status;
}
# $dir to create archive from
# $dstfile - destination file to save archive to
sub create_archive {
    my ($dir, $dstfile) = @_;
    if (!defined($dir) || !-d $dir || !defined($dstfile)){
        return 0;
    }
    
    my $status = 1;
    my $current_dir = getcwd();
    
    $dir = realpath($dir);
    my $basedir = dirname($dir);
    my $dstdir  = dirname(realpath($dstfile));
    if (!-d $dstdir) {
        make_path($dstdir) or return 0;
    }
    # change dir to parent dir so archive include the needed dir
    chdir $basedir;
    
    my @files;
    # List all files in given dir.
    find(sub { 
            $File::Find::name =~ s/^${basedir}//;
            $File::Find::name =~ s/^\///;
            return if $File::Find::name eq "";
            push @files,$File::Find::name
            }, 
         $dir);
    
    Archive::Tar->create_archive($dstfile, COMPRESS_GZIP, @files) or $status = 0;
    # change working dir back
    chdir $current_dir;
    return $status;
}

# $file - archive file
# $dstdir - destination folder where to extract archive
sub extract_archive {
    my ($file, $dstdir) = @_;
    if (!defined($file) || !-f $file || !defined($dstdir)){
        return 0;
    }
    my $status = 1;
    my $current_dir = getcwd();
    my $base = dirname(realpath($dstdir));
    if (-d $dstdir) {
        remove_tree($dstdir) or return 0;
    }
    
    $file = realpath($file);
    # change dir to extract location
    chdir $base;

    Archive::Tar->extract_archive($file, COMPRESS_GZIP) or $status = 0;
    # change working dir back
    chdir $current_dir;
    return $status;
}

sub get_backup_files {
    my ($dir) = @_;
    my @files = ();
    
    if (! -d $dir) {
        return; # Return undef
    }
    
    opendir(dir_handle, $dir);
    
    @files = grep{!/^\.$|^\.\.$/} readdir dir_handle;
    
    closedir(dir_handle);
    return @files;
}



1;