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
				if(explorer.checkIfRepository(postParams.path)){
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
		console.log('******');
		var config = explorer.getConfig(path);
		console.log(config);
		var promise = new Promise(function(resolve,reject){
			var auth = explorer.userPassToBase64(config.username,config.password);
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
		var config = explorer.getConfig(path);
		apiAddUser(config,username,password,admin).then(function(result){
			res.json({error:0,message:result});
			res.end();
		});
	}

	var apiAddUser = function(config,username,password,admin){
		var promise = new Promise(function(resolve,reject){
			var auth = explorer.userPassToBase64(config.username,config.password);
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
	
	return app;
}();