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
						remoteFileList = trimToArrayFileList(fileList);
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
		console.log('data',req.body);
		currentPath = req.body.currentPath;
		res.redirect('/');
		res.end();
	});

	var init = function(){
		var promise = new Promise(function(resolve,reject){
			config = explorer.getConfig(currentPath);
			resolve();
		});
		return promise;
	}

	var trimToArrayFileList = function(fileList){
		var temp = fileList.split('\n');
		temp.splice(-1,1);
		for(var i = 0; i < temp.length; i++)
			temp[i] = temp[i].substr(1);
		return temp;
	}

	var getLocalFilesSync = function(path,remoteFileList){
		var allFiles = fs.readdirSync(path);
		// get the diference between the remote and local to get local file ignoring .mycvs
		return allFiles.minus(remoteFileList.concat('.mycvs'));
	}

	Array.prototype.minus = function(a) {
    	return this.filter(function(i) {return a.indexOf(i) < 0;});
	};

	return app;
}();