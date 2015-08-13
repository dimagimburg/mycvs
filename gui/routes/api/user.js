module.exports = function(){
  	var express = require('express');
  	var app = express();
  	var fs = require('fs');
  	var path = require('path');
	var request = require('request');
	var Promise = require('promise');
	var explorer = require('../explorer');

	app.post('/',function(req,res) {
		var postParams = req.body;
		switch (postParams.event) {
			case 'addUser':
				if(checkIfRepository(postParams.path)){
					addUser(postParams.username,postParams.password,postParams.admin,postParams.path,res);
				} else {
					res.json({error: 1, message : 'Please add user from repository directory'});
					res.end();
				}
				break;
			case 'backupDB':
				backupDB(postParams.path).then(function(response){
					res.end('');
				});
				break;
		}
	});

	var backupDB = function(path){
		var config = getConfig(path);
		console.log(config);
		var promise = new Promise(function(resolve,reject){
			var auth = userPassToBase64(config.username,config.password);
			console.log(auth);
			console.log('http://' + config.server + ':' + config.port + '/backup/backupdb');
			request({
				method: 'POST',
				url: 'http://' + config.server + ':' + config.port + '/backup/backupdb',
				headers : {
					"Authorization" : "Basic " + auth
				}
			}, function(err, resp, body){
				if(err == null){
					resolve(body); 
				} else {
					console.log(err);
					reject(err);
				}
			});		
		});
		return promise;
	}

	var addUser = function(username,password,admin,path,res){
		var config = getConfig(path);
		apiAddUser(config,username,password,admin).then(function(result){
			res.json({error:0,message:result});
			res.end();
		});
	}

	var apiAddUser = function(config,username,password,admin){
		var promise = new Promise(function(resolve,reject){
			var auth = userPassToBase64(config.username,config.password);
			request({
				method: 'POST',
				url: 'http://' + config.server + ':' + config.port + '/user/add?username=' + username + '&pass=' + password + '&admin=' + admin,
				headers : {
					"Authorization" : "Basic " + auth
				}
			}, function(err, resp, body){
				if(err == null){
					resolve(body); 
				} else {
					console.log(err);
					reject(err);
				}
			});		
		});
		return promise;
	}

	var checkIfRepository = function(pathString){
		var configFilePath = path.join(pathString, '.mycvs', 'config');
		return fs.existsSync(configFilePath);
	}

	var getConfig = function(pathOfDirectory){
		var configFilePath = path.join(pathOfDirectory , '.mycvs' , 'config');
		if(fs.existsSync(configFilePath)){
			return parseConfig(getConfigLine(configFilePath));
		}
	}

	var userPassToBase64 = function(username,password){
		return new Buffer(username + ':' + password).toString('base64');
	}

	var getConfigLine = function(pathToConfigFile){
		return fs.readFileSync(pathToConfigFile).toString();
	}

	var parseConfig = function(configString){
		configArray = configString.replace(/(\r\n|\n|\r)/gm,"").split(':');
		return {
			server : configArray[0],
			port : configArray[1],
			reponame : configArray[2],
			username : configArray[3],
			password : configArray[4],
		}
	}
	
	return app;
}();