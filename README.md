MyCVS uses the same code for server and CLI client

* CLI Client Installation:
   - git clone mycvs into folder of your choise
   - add folder where you cloned to the PATH:
        - CentOS/RHEL/Fedora -> echo "export PATH=$PATH:/path/to/mysvs/folder" >> ~/.bash_profile
        - Debian/Ubuntu      -> echo "export PATH=$PATH:/path/to/mysvs/folder" >> ~/.bashrc

* Server Installation:
   - same as client but at the end issue "mycvs.pl server start"
        - You'll be asked to create admin user if not exists already

* Bash completion for Server/Client:
   - Added bash completion to most of mycvs commands
     Just copy mycvs_completion to /etc/bash_completion.d folder

# Web Server API

* GET:
   - /repo/revision?reponame=<repo_name>&filename=<repo_file_path>&revision=<rev#>
   - /repo/checkout?reponame=<repo_name>&filename=<repo_file_path>&revision=<revision#>
   - /repo/revisions?reponame=<repo_name>&filename=<repo_file_path>
   - /repo/revision?reponame=<repo_name>&filename=<repo_file_path>
   - /repo/timestamp?reponame=<repo_name>&filename=<repo_file_path>&revision=<revision#>
   - /repo/filelist?reponame=<reponame>

* POST:
   - /repo/checkin?reponame=<repo_name>&filename=<repo_file_path>
   - /repo/add?reponame=<repo_name>
   - /repo/user/add?reponame=<repo_name>&username=<username>

   - /user/add?username=<username>&pass=<hash>&admin=<true/false>
* DELETE:
   - /repo/del?reponame=<repo_name>
   - /user/del?username=<username>
   - /repo/user/del?reponame=<reponame>&username=<username>
