$(document).ready(function(){
	console.log('explorer client events loaded');

	var currentPath = $('.path').find('.directory:last').data('path');

	$('.directory').click(function(){ changePath($(this)); });
	$('.choose-directory').click(function(){ chooseDirectory(currentPath); });
	$('.create-repository').click(function(){ openCreateRepositoryForm(currentPath); });
	$('#create-repository-form').submit(function(event){  createRepository(); event.preventDefault();});
	

	var changePath = function(clicked){
		console.log('change dir to: ' + clicked.data('path'));
		$.ajax({
			method : 'POST',
			url : 'http://localhost:3000',
			data : {
				event : 'changePath', 
				newPath : clicked.data('path')
			},
			success : function(response){
				if(!response.error){
					$('body').html(response);
				} else {
					$('.error').html(response.error);
					$('.error').fadeIn().delay(1000).fadeOut();
				}
			}
		});
	}

	var chooseDirectory = function(currentPath){
		console.log(currentPath);
		$.ajax({
			method : 'POST',
			url : 'http://localhost:3000',
			data : {
				event : 'chooseDirectory', 
				currentPath : currentPath
			},
			success : function(response){
				if(!response.error)
					window.location = 'http://localhost:3000' + response.url + '?path=' + encodeURIComponent(currentPath);
			}
		});
	}

	var openCreateRepositoryForm = function(currentPath){
		$.ajax({
			method : 'POST',
			url : 'http://localhost:3000',
			data : {
				event : 'createRepository', 
				currentPath : currentPath 
			},
			success : function(response){
				if(!parseInt(response.error)){
					$('#myModal').modal();
				}
			}
		});
	}

	var createRepository = function(){
		var config = getConfig();
		$('.close-create-repository-button').attr('disabled',true);
		$('.create-repository-button').attr('disabled',true);
		$.ajax({
			method : 'POST',
			url : 'http://localhost:3000',
			data : {
				event : 'createConfig',
				path : currentPath,
				config : config 
			},
			success : function(response){
				$('#myModal').modal('hide');
				$('body').html(response);
			}
		});
	}

	var getConfig = function(){
		var createRepositoryForm = $('#create-repository-form');
		var config = {
			username : createRepositoryForm.find('#username').val(),
			password : createRepositoryForm.find('#password').val(),
			reponame : createRepositoryForm.find('#reponame').val(),
			server : createRepositoryForm.find('#serveraddres').val(),
			port : createRepositoryForm.find('#serverport').val()
		};
		return config;
	}

});