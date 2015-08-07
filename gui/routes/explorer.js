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
		var isRepository = checkIfRepository(currentPathString);
		var bottomList;
		getDirectoryContent(currentPathString).then(function(content){
			bottomList = content;
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
		});
	}

	var changePath = function(newPath,res) {
		var currentPath = splitPath(newPath);
		var subPaths = getSubPaths(currentPath);
		var bottomList;
		getDirectoryContent(newPath).then(function(content){
			bottomList = content;
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
		}, function(rej){
			res.json({error:rej}).end();
				return;
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

	var getFilesProperties = function(content,path,files,remoteFilesList){
		for(var i = 0; i < files.length; i++){
			var filePath = path + '/' + files[i];
			var nextFile = fs.lstatSync(filePath);
			var lastModified = nextFile.mtime;
			var isRepository = checkIfRepository(filePath);
			var inRepo = isInRepo(filePath);
			var inRemote = false;
			if(remoteFilesList && remoteFilesList.indexOf(files[i]) > -1){
				inRemote = true;
			}
			if(nextFile.isDirectory()){
				content.directories.push({ directoryName : files[i] , lastModified : new Date(lastModified) , isRepository : isRepository , inRepo : inRepo });
			} else {
				content.files.push({fileName : files[i] , lastModified : new Date(lastModified) , inRepo : inRepo , inRemote : inRemote });
			} 
		}
		return content;
	}

	// returns object with 2 arrays of directories and files in path
	var getDirectoryContent = function(path){
		var promise = new Promise(function(resolve,reject){
				var content = {
					directories : [],
					files : []
				};
				try{
					var config = getConfig(path);
					var files = fs.readdirSync(path);
					if(config){
						getRemoteFileList(config)
							.then(function(remoteFilesList){
								// there is remote file list for this repo
								content = getFilesProperties(content,path,files,remoteFilesList);
								resolve(content);
							}, function(){
								// no file list fo repo
								content = getFilesProperties(content,path,files);
								resolve(content);
							});
					} else {
						content = getFilesProperties(content,path,files);
						resolve(content);
					}
				} catch (e) {
					console.log(e);
					reject(false);
				}
		});
		return promise;
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

	var getConfigLine = function(pathToConfigFile){
		return fs.readFileSync(pathToConfigFile).toString();
	}

	var getConfig = function(pathOfDirectory){
		var configFilePath = path.join(pathOfDirectory , '.mycvs' , 'config');
		if(fs.existsSync(configFilePath)){
			return parseConfig(getConfigLine(configFilePath));
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

	/** returns true if file is in repo folder (if some of his root nodes has .mycvs/config file) */
	var isInRepo = function(filePath){
		var subPaths = getSubPaths(splitPath(filePath));
		for(var i = subPaths.length - 2; i > 0; i--){
			var repoPathToCheck = path.join(subPaths[i],'.mycvs','config');
			if(fs.existsSync(repoPathToCheck)){
				return filePath;
			}
		}
		return false;
	}

	/* get remote file list with config, if there is no config return false. */
	var getRemoteFileList = function(config){
		console.log('in get remote');
		if(config){
			var username = config.username;
			var password = config.password;
			var reponame = config.reponame;
			var server = config.server + ':' + config.port;
			usernamePasswordBase64 = new Buffer(username + ':' + password).toString('base64');
			//process.chdir('/home/dima/Desktop/another-test');
			console.log(username,password,reponame,server);
			var promise = new Promise(function(resolve,reject){
				request({
					method: 'GET',
					url: 'http://' + server + '/repo/filelist?reponame=' + reponame,
					headers : {
						"Authorization" : "Basic " + usernamePasswordBase64
					}
				}, function(err, resp, body){
					if(err == null){
						console.log(body);
						resolve(body); 
					} else {
						reject(err);
					}
				});		
			});
			return promise;
		} else {
			return false;
		}
	}

	var userPassToBase64 = function(username,password){
		return new Buffer(username + ':' + password).toString('base64');
	}

	app.checkIfRepository = checkIfRepository;
	app.getConfig = getConfig;
	app.userPassToBase64 = userPassToBase64;
	app.getRemoteFileList = getRemoteFileList;

	return app;
}();