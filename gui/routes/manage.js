module.exports = function(){
	var express = require('express');
	var app = express();
	var fs = require('fs');
	var path = require('path');
	var http = require('http');
	var request = require('request');


	app.get('/', function(req, res) {
		console.log('manage route');
		if(req.query.path){
			res.render('pages/manage');
		}	

  	app.post('/',function(req,res){
		console.log('got post request!@$@$!');
		request({
			url:'http://localhost:8080/repo/filelist/?reponame=TestRepos',
			headers : {
				"Authorization" : "Basic ZGltYWdpbWJ1cmc6ZGltYTE5NDUxOTQz"
			}
		}, function(err, resp, body){
			console.log(body);
		});
		
		res.end('ok');
	});

	});
	return app;
}();