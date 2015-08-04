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

	app.get('/',function(req,res){
		if(currentPath){
			init().then(function(){
				res.render('pages/manage');
				res.end();
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

	return app;
}();