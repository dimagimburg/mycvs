module.exports = function(){
	var express = require('express');
	var app = express();
	var fs = require('fs');
	var path = require('path');
	var http = require('http');
	var request = require('request');
	var explorer = require('./explorer');
	var Promise = require('promise');


	var currentPath;
	var config;
	var remoteFileList;
	var localFileList;

	app.get('/',function(req,res){
		if(currentPath){
			init()
				.then(function(){
					explorer.getRemoteFileList(config).then(function(fileList){
						remoteFileList = trimToArray(fileList);
						trimStartingSlashes(remoteFileList);
						localFileList = getLocalFilesSync(currentPath,remoteFileList);
						res.render('pages/manage',{
							path : currentPath,
							config : config,
							remoteFileList : remoteFileList,
							localFileList : localFileList
						});
						res.end();
					});
				});
		} else {
			res.write('here 404');
			res.end();
		}
	});

	app.post('/', function(req, res) {
		console.log('manage route');
		switch(req.body.event){
			case 'repoMembers':
				getRepoMembers(config).then(function(members){
					var membersArray = trimToArray(members);
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

	var trimToArray = function(list){
		var temp = list.split('\n');
		temp.splice(-1,1);
		return temp;
	}

	var trimStartingSlashes = function(filesArray){
		for(var i = 0; i < filesArray.length; i++)
			filesArray[i] = filesArray[i].substr(1);
	}

	var getLocalFilesSync = function(path,remoteFileList){
		var allFiles = fs.readdirSync(path);
		// get the diference between the remote and local to get local file ignoring .mycvs
		return allFiles.minus(remoteFileList.concat('.mycvs'));
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
					console.log(body); 
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
					console.log(body); 
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
					console.log(body); 
					resolve(body); 
				} else {
					reject(error);
				}
			});	
		});
		return promise;
	}

	return app;
}();