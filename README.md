
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

