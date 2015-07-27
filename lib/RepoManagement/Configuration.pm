#!/bin/env perl
package RepoManagement::Configuration;

use Exporter qw(import);
our @ISA = 'Exporter';
our @EXPORT_OK = qw(
                    $MYCVS_GLOBAL_BASEDIR $MYCVS_GLOBAL_CONFIG_LOC
                    $MYCVS_USERS_DB $MYCVS_GROUPS_DB $MYCVS_DB_FOLDER
                    $MYCVS_HTTP_PORT $MYCVS_REPO_STORE $MYCVS_CONFIG_NAME
                    $MYCVS_ADMINS_DB $MYCVS_REMOTE_SUFFIX $MYCVS_BACKUP_STORE
                    $MYCVS_DB_BACKUP_STORE $MYCVS_REPO_BACKUP_STORE
                    $MYCVS_BACKUP_SUFFIX
                    );
##################Client Configuration vars###################
our $MYCVS_CONFIG_NAME = qw(config);
our $MYCVS_REMOTE_SUFFIX = qw(remote_copy);
##################Server Configuration Vars###################
# MYCVS_GLOBAL_BASEDIR repository independent
our $MYCVS_GLOBAL_BASEDIR = $ENV{HOME}.qw(/mycvs);
#our $MYCVS_GLOBAL_BASEDIR = qw(/opt/.mycvs);
our $MYCVS_DB_FOLDER = $MYCVS_GLOBAL_BASEDIR.qw(/db);
# User DB file location
our $MYCVS_USERS_DB = $MYCVS_DB_FOLDER.qw(/users.db);
# Admins DB location
our $MYCVS_ADMINS_DB = $MYCVS_DB_FOLDER.qw(/admins.db);
# User DB file location
our $MYCVS_GROUPS_DB = $MYCVS_DB_FOLDER.qw(/groups.db);

# Backup Store location
our $MYCVS_BACKUP_STORE = $MYCVS_GLOBAL_BASEDIR.qw(/backup);
# DB Backup location
our $MYCVS_DB_BACKUP_STORE = $MYCVS_BACKUP_STORE.qw(/db);
# Repo Backup Location
our $MYCVS_REPO_BACKUP_STORE = $MYCVS_BACKUP_STORE.qw(/repo);
# Backup file suffix
our $MYCVS_BACKUP_SUFFIX = qw(tgz);

# Repository store location
our $MYCVS_REPO_STORE = $MYCVS_GLOBAL_BASEDIR.qw(/repo);
# Server listening port
our $MYCVS_HTTP_PORT = 8080;

1;