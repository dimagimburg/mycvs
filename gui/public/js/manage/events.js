$(document).ready(function(){
	$('.files-list').click(function(){
		console.log('get files list');
		$.ajax({
			method : 'POST',
			url : 'http://localhost:3000/manage',
		});
	});
});


