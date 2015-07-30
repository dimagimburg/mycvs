module.exports = function(){
  	var express = require('express');
  	var app = express();
  	var fs = require('fs');
  	var path = require('path');
	var request = require('request');
	var Promise = require('promise');

  	app.get('/', function(req, res) {
  		console.log('explorer route');	
  		init(res);
	});

	app.post('/',function(req,res) {
		var postParams = req.body;
		switch(postParams.event){
			case 'changePath':
				changePath(postParams.newPath,res);
				break;
			case 'chooseDirectory':
				process.chdir(postParams.currentPath);
				console.log(process.cwd());
				chooseDirectory(postParams.currentPath,res);
				break;
			case 'createRepository':
				createRepository(postParams.currentPath);
				res.json({'error':'0'});
				res.end();
				break;
			case 'createConfig':
				createConfig(postParams,res);
				break;
		}
	});

	var init = function(res) {
		var currentPathString = getUserHome();
		var currentPath = splitPath(currentPathString);
		var subPaths = getSubPaths(currentPath);
		var bottomList = getDirectoryContent(currentPathString);
		var isRepository = checkIfRepository(currentPathString);

		var upperPath = {
			currentPath : currentPath,
			subPaths : subPaths
		};
		res.render('pages/explorer',{
			currentPathString : currentPathString,
			upperPath : upperPath,
			bottomList : bottomList,
			isRepository : isRepository
		});
	}

	var changePath = function(newPath,res) {
		var currentPath = splitPath(newPath);
		var subPaths = getSubPaths(currentPath);
		var bottomList = getDirectoryContent(newPath);
		if(!bottomList){
			res.json({error:'Can\'t access path. Access denied'}).end();
			return;
		}
		var isRepository = checkIfRepository(newPath);

		var upperPath = {
			currentPath : currentPath,
			subPaths : subPaths
		};

		res.render('pages/explorer',{
			currentPathString : newPath,
			upperPath : upperPath,
			bottomList : bottomList,
			isRepository : isRepository
		});
	}	

	var getUserHome = function() {
		var rawPath =  process.env[(process.platform == 'win32') ? 'USERPROFILE' : 'HOME'];
		return rawPath;
	}

	var splitPath = function(rawPath) {
		var splitted = rawPath.split('/');
		splitted.shift();
		return splitted;
	}

	var getSubPaths = function(pathArray) {
		var subPaths = [];
		if(pathArray.length <= 1) return pathArray;
		subPaths[0] = '/' + pathArray[0];
		for(var i = 1; i < pathArray.length; i++){
			subPaths.push(subPaths[i-1] + '/' + pathArray[i]);	
		}
		return subPaths;
	}

	// returns object with 2 arrays of directories and files in path
	var getDirectoryContent = function(path){
		var content = {
			directories : [],
			files : []
		};
		try{
			var files = fs.readdirSync(path);
			for(var i = 0; i < files.length; i++){
				var filePath = path + '/' + files[i];
				var nextFile = fs.lstatSync(filePath);
				//console.log(nextFile);
				var lastModified = nextFile.mtime;
				var isRepository = checkIfRepository(filePath);
				if(nextFile.isDirectory()){
					content.directories.push({ directoryName : files[i] , lastModified : new Date(lastModified) , isRepository : isRepository });
				} else {
					content.files.push({fileName : files[i] , lastModified : new Date(lastModified)});
				} 
			}
			return content;
		} catch (e) {
			return false;
		}
	};

	// checks if exists .mycvs directory and config file
	var chooseDirectory = function(currentPath,res){
		var configFilePath = path.join(currentPath, '.mycvs', 'config');
		var mycvsConfigFile = fs.stat(configFilePath,function(error,stats){
			if(error == null){
				fs.readFile(configFilePath,'utf8',function(err,data){
					if(err == null){
						var configParsed = parseConfig(data);
						res.send({
							error : 0,
							url : '/manage'
						});
					}
				});
			} else {
				res.send({ error : 1 , status : error});
			}
		});
		return;
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

	var checkIfRepository = function(pathString){
		var configFilePath = path.join(pathString, '.mycvs', 'config');
		return fs.existsSync(configFilePath);
	}

	var createRepository = function(currentPath){
		fs.mkdirSync(path.join(currentPath, '.mycvs'));
	}

	var createConfig = function(params,res){
		var fileName = path.join(params.path,'.mycvs','config');
		var config = params.config;
		var configLine = config.username + ':' + config.password + ':' + config.reponame + ':' + config.server + ':' + config.port;
		console.log(fileName,configLine);
		fs.appendFileSync(fileName,configLine);
		addRepoToServer(config.reponame,config.username,config.password)
			.then(function(success,error){
				changePath(params.path,res);	
			});
	}

	var addRepoToServer = function(reponame,username,password){
		var usernamePasswordBase64 = new Buffer(username + ':' + password).toString('base64');
		var promise = new Promise(function(resolve,reject){
			request({
				method: 'POST',
				url: 'http://localhost:8080/repo/add?reponame=' + reponame,
				headers : {
					"Authorization" : "Basic " + usernamePasswordBase64
				}
			}, function(err, resp, body){
				console.log(err, resp, body);
				if(err == null){ 
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