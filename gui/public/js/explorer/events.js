$(document).ready(function(){
	console.log('explorer client events loaded');
	$('.directory').click(function(){ changePath($(this)); });
	$('.choose-directory').click(function(){ chooseDirectory(currentPath); });

	var currentPath = $('.path').find('.directory:last').data('path');

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

});