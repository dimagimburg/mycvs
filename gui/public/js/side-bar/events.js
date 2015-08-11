$(document).ready(function(){
	console.log('side bar events loaded');

	var currentPath = $('.path').find('.directory:last').data('path');
	console.log(currentPath);

	$('.backup-db').click(function(){
		backupDb();
	});

	$('.add-user-side-bar').click(function(){ $('.add-user').toggle(150); });
	$('.cancel-add-user-button').click(function(){ $('.add-user').toggle(150); });

	$('.add-admin-side-bar').click(function(){ $('.add-admin').toggle(150); });
	$('.cancel-add-admin-button').click(function(){ $('.add-admin').toggle(150); });

	$('#add-user-form').submit(function(event){ addUser(false); event.preventDefault(); });
	$('#add-admin-form').submit(function(event){ addUser(true); event.preventDefault(); });

	var addUser = function(admin){
		console.log('user add');
		console.log($('#add-user-username').val(),$('#add-user-password').val());

		var userOrAdmin = admin ? "admin" : "user"

		$.ajax({
			method : 'POST',
			url : 'http://localhost:3000/api/user',
			data : {
				event : 'addUser', 
				path : currentPath,
				admin : admin,
				username : $('#add-' + userOrAdmin + '-username').val(),
				password : $('#add-' + userOrAdmin + '-password').val()
			},
			success : function(response){
				if(response.error){
					$('.error').find('.error-message').html(response.message);
					$('.error').fadeIn().delay(1000).fadeOut();
				} else {
					$('.success').html(response.message);
					$('#add-user-username').val('');
					$('#add-user-password').val('');
					$('.success').fadeIn().delay(1000).fadeOut();
				}
			}
		});
	}

	var backupDb = function(){
		$.ajax({
			method : 'POST',
			url : 'http://localhost:3000/api/user',
			data : { event : 'backupDB', path : currentPath },
			success : function(response){
				$('.success').html('DataBase backup successfuly created.');
				$('.success').fadeIn().delay(2000).fadeOut();
			}
		});
	}
});