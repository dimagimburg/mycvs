# mycvs
a project in PERL for custom cvs

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
