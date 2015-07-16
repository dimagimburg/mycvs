# mycvs
a project in PERL for custom cvs

dima 17.7
fixed bug in requests, set up init functions (mycvs init, mycvs clientconfig) added to init_global the creation of base dir, get_user_groups remove_user_from_group remove_group implemented still need to be tested, need to remove prints from functions

dima 14.7
  need to decide what we do with groups and how to give permissions to each repository.
  
  * what i thought about is:
    - root user can create repositories wherever he wants (with init and with checkin).
    - when root creates repository (local) (in what/ever/path e.g.) he intialize the with user and password that should be already found in the users.db.
    - if valid we create on local .mycvs directory (what/ever/path/.mycvs/) the admin file with the name of the and the hash of the password (READONLY file that can be edited only by root, we can also encrypt somehow the content).
    - when initialization is complete the user asked to login to create the session (overwrite it in /opt/.mycvs/session)
    - this admin can create a group and associate it with the current repository by ceating group (created also and stored in groups.db) and then can add users from the users.db to the group.
    
    * admin : 
      - create groups and associate with repository
      - remove group associated with repository
      - add users to group
      - remove users from group
      - checkin/checkout files
      - backup/restore
      
    * users :
      - checkin/checkout

# Web Server API

* GET:
   - /repo/revision?reponame=<repo_name>&filename=<repo_file_path>&revision=<rev#>
   - /repo/checkout?reponame=<repo_name>&filename=<repo_file_path>&revision=<revision#>
   - /repo/revisions?reponame=<repo_name>&filename=<repo_file_path>
   - /repo/timestamp?reponame=<repo_name>&filename=<repo_file_path>&revision=<revision#>
   - /repo/filelist?reponame=<reponame>

* POST:
   - /repo/checkin?reponame=<repo_name>&filename=<repo_file_path>
   - /repo/add?reponame=<repo_name>
   - /repo/user/add?reponame=<repo_name>&username=<username>
   - /repo/ulock?filename=<repo_file_path>

   - /user/add?username=<username>&pass=<hash>&admin=<true/false>
* DELETE:
   - /repo/del?reponame=<repo_name>
   - /user/del?username=<username>
   - /repo/user/del?reponame=<reponame>&username=<username>

