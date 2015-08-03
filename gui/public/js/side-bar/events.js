$(document).ready(function(){
	console.log('side bar events loaded');

	var currentPath = $('.path').find('.directory:last').data('path');
	console.log(currentPath);

	$('.add-user-side-bar').click(function(){ $('.add-user').toggle(150); });
	$('.cancel-add-user-button').click(function(){ $('.add-user').toggle(150); });
	$('#add-user-form').submit(function(event){ addUser(); event.preventDefault(); });

	var addUser = function(){
		console.log('user add');
		console.log($('#add-user-username').val(),$('#add-user-password').val());
		$.ajax({
			method : 'POST',
			url : 'http://localhost:3000/api/user',
			data : {
				event : 'addUser', 
				path : currentPath,
				username : $('#add-user-username').val(),
				password : $('#add-user-password').val()
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
});