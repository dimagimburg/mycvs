module.exports = function(){
	var express = require('express');
	var app = express();
	var fs = require('fs');
	var path = require('path');
	var http = require('http');
	var request = require('request');
	var explorer = require('./explorer');
	var Promise = require('promise');
	var MYCVS_REPO_PATH = path.join(getUserHome(),'mycvs','repo');


	var currentPath;
	var config;
	var remoteFileList;
	var localFileList;

	app.get('/',function(req,res){
		if(currentPath){
			init()
				.then(function(){
					explorer.getRemoteFileList(config).then(function(fileList){
						remoteFileList = stringListToArray(fileList);
						setTimeStamps(remoteFileList);
						trimStartingSlashes(remoteFileList);
						localFileList = getLocalFilesSync(currentPath,remoteFileList);
						setDifferent(localFileList);
						console.log(localFileList);
						res.render('pages/manage',{
							path : currentPath,
							config : config,
							remoteFileList : remoteFileList,
							localFileList : localFileList,
							isRepository : explorer.checkIfRepository(currentPath)
						});
						res.end();
					});
				});
		} else {
			res.redirect('http://localhost:3000/');
			res.end();
		}
	});

	app.post('/', function(req, res) {
		switch(req.body.event){
			case 'repoMembers':
				getRepoMembers(config).then(function(members){
					var membersArray = stringListToArray(members);
					res.json({members : membersArray});
					res.end();
				});
				break;
			case 'addMember':
				addMember(config,req.body.username).then(function(response){
					res.end(response);
				});
				break;
			case 'removeMember':
				removeMember(config,req.body.username).then(function(response){
					res.end(response);
				});
				break;
			case 'checkin':
				checkin(config,req.body.filename).then(function(response){
					res.end(response);
				});
				break;
			case 'getRevisions':
				getRevisions(config,req.body.filename).then(function(response){
					res.end(response);
				});
				break;
			case 'backupRepo':
				backupRepo(config).then(function(response){
					res.end('Repo ' + config.reponame + ' backup created sucssesfuly');
				});
				break;
			default:
				currentPath = req.body.currentPath;
				res.redirect('/');
				res.end();
				break;
		}
	});

	var init = function(){
		var promise = new Promise(function(resolve,reject){
			config = explorer.getConfig(currentPath);
			resolve();
		});
		return promise;
	}

	var setTimeStamps = function(filesArray){
		for(var i = 0; i < filesArray.length; i++){
			var filename = filesArray[i];
			var pathToFile = path.join(currentPath,filename);
			var fileStats = fs.lstatSync(pathToFile);
			filesArray[i] = {
				filename : filename,
				modified : fileStats.mtime
			};
		}
	}

	var stringListToArray = function(list){
		var temp = list.split('\n');
		temp.splice(-1,1);
		return temp;
	}

	var trimStartingSlashes = function(filesArray){
		for(var i = 0; i < filesArray.length; i++)
			filesArray[i].filename = filesArray[i].filename.substr(1);
	}

	var getLocalFilesSync = function(path,remoteFiles){
		var allFiles = fs.readdirSync(path);
		allFiles = allFiles.minus(['.mycvs']);
		setTimeStamps(allFiles);
		// get the diference between the remote and local to get local file ignoring .mycvs
		for(var i = 0; i < remoteFiles.length; i++){
			for(var j = 0; j < allFiles.length; j++){
				var inRemote = allFiles[j].filename == remoteFiles[i].filename;
				if(inRemote){
					allFiles[j].remote = true;
				}
			}
		}

		return allFiles;
	}


	Array.prototype.minus = function(a) {
    	return this.filter(function(i) {return a.indexOf(i) < 0;});
	};

	var getRepoMembers = function(config){
		var promise = new Promise(function(resolve,reject){
			var usernamePasswordBase64 = explorer.userPassToBase64(config.username,config.password);
			request({
				method: 'GET',
				url: 'http://localhost:8080/repo/members?reponame=' + config.reponame,
				headers : {
					"Authorization" : "Basic " + usernamePasswordBase64
				}
			}, function(err, resp, body){
				if(err == null){
					resolve(body); 
				} else {
					reject(error);
				}
			});	
		});
		return promise;
	}

	var addMember = function(config,toAdd){
		var promise = new Promise(function(resolve,reject){
			var usernamePasswordBase64 = explorer.userPassToBase64(config.username,config.password);
			request({
				method: 'POST',
				url: 'http://localhost:8080/repo/user/add?username=' + toAdd + '&reponame=' + config.reponame,
				headers : {
					"Authorization" : "Basic " + usernamePasswordBase64
				}
			}, function(err, resp, body){
				if(err == null){
					resolve(body); 
				} else {
					reject(error);
				}
			});	
		});
		return promise;
	}

	var removeMember = function(config,toRemove){
		var promise = new Promise(function(resolve,reject){
			var usernamePasswordBase64 = explorer.userPassToBase64(config.username,config.password);
			request({
				method: 'DELETE',
				url: 'http://localhost:8080/repo/user/del?reponame=' + config.reponame + '&username=' + toRemove,
				headers : {
					"Authorization" : "Basic " + usernamePasswordBase64
				}
			}, function(err, resp, body){
				if(err == null){
					resolve(body); 
				} else {
					reject(error);
				}
			});	
		});
		return promise;
	}

	var checkin = function(config,filename){
		var promise = new Promise(function(resolve, reject){
			filename = '/' + filename;
			var usernamePasswordBase64 = explorer.userPassToBase64(config.username,config.password);
			request({
				method: 'POST',
				url: 'http://localhost:8080/repo/checkin?reponame=' + config.reponame + '&filename=' + filename,
				headers : {
					"Authorization" : "Basic " + usernamePasswordBase64
				}
			}, function(err, resp, body){
				if(err == null){
					resolve(body); 
				} else {
					reject(err);
				}
			});	
		});
		return promise;
	}

	var setDifferent = function(files){
		for(var i = 0; i < files.length; i++){
			var filePath = path.join(currentPath,files[i].filename);
			var fileModified = new Date(fs.lstatSync(filePath).mtime);
			var fileRemotePath = path.join(MYCVS_REPO_PATH, config.reponame, files[i].filename);
			if(fs.existsSync(fileRemotePath)){
				var fileRemoteModified = new Date(fs.lstatSync(fileRemotePath).mtime);
				files[i].different = fileRemoteModified.getTime() != fileModified.getTime();
			} else {
				files[i].different = false;
			}
		}
	}

	var getRevisions = function(config,filename){
		var promise = new Promise(function(resolve, reject){
			filename = '/' + filename;
			var usernamePasswordBase64 = explorer.userPassToBase64(config.username,config.password);
			request({
				method: 'GET',
				url: 'http://localhost:8080/repo/revisions?reponame=' + config.reponame + '&filename=' + filename,
				headers : {
					"Authorization" : "Basic " + usernamePasswordBase64
				}
			}, function(err, resp, body){
				if(err == null){
					resolve(body); 
				} else {
					reject(err);
				}
			});	
		});
		return promise;
	};

	var backupRepo = function(config){
		var promise = new Promise(function(resolve, reject){
			var usernamePasswordBase64 = explorer.userPassToBase64(config.username,config.password);
			request({
				method: 'POST',
				url: 'http://localhost:8080/backup/backuprepo?reponame=' + config.reponame,
				headers : {
					"Authorization" : "Basic " + usernamePasswordBase64
				}
			}, function(err, resp, body){
				if(err == null){
					resolve(body); 
				} else {
					reject(err);
				}
			});	
		});
		return promise;
	}

	function getUserHome() {
	  	return process.env[(process.platform == 'win32') ? 'USERPROFILE' : 'HOME'];
	}

	return app;
}();