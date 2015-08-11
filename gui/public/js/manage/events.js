$(document).ready(function(){
	$('.members-list-button').click(function(){
		getMembers();
	});

	$('.remote-file').click(function(){
		var fileName = $(this).text().trim();
		getRevisions(fileName);
	});

	$('.add-member').click(function(){
		var memberToAdd = $('.add-member-username').val();
		console.log('add-member clicked',memberToAdd);
		addMemberToRepo(memberToAdd);
	});

	$('.remove-member').click(function(){
		var memberToRemove = $('.member-selected').text();
		console.log('remove',memberToRemove);
		removeMemberFromRepo(memberToRemove);
	});

	$('.checkin').click(function(){
		var fileToCheckin = $('.local-file-selected').text().trim();
		checkinFile(fileToCheckin);
	});

	$('.backup').click(function(){
		backupRepo();
	});

	var getMembers = function(){
		$.ajax({
			method : 'POST',
			url : 'http://localhost:3000/manage',
			data : {event : 'repoMembers'},
			success : function(response){
				var members = response.members;
				$('.members-list').html('');
				for(var i = 0; i < members.length; i++){
					var isAdmin = (i == 0) ? 'admin' : '';
					$('.members-list').append('<li class="member ' + isAdmin + ' list-group-item"><span class="glyphicon glyphicon-user member-icon"></span>' + members[i] + '</li>');
				}
			}
		});
	}

	var addMemberToRepo = function(memberToAdd){
		$.ajax({
			method : 'POST',
			url : 'http://localhost:3000/manage',
			data : {event : 'addMember', username : memberToAdd},
			success : function(response){
				if(response.indexOf('Not Found') > -1){
					$('.error-message').html('User Not Found');
					$('.error').fadeIn().delay(1000).fadeOut();
				} else if (response.indexOf('already exists') > -1) {
					$('.error-message').html(response);
					$('.error').fadeIn().delay(1000).fadeOut();
				} else if (response.indexOf('not supported') > -1) {
					$('.error-message').html(response);
					$('.error').fadeIn().delay(1000).fadeOut();
				} else {
					$('.success').html(response);
					$('.success').fadeIn().delay(1000).fadeOut();
					$('.add-member-username').val('');
					memberToAdd = '';
					getMembers();
				}
			}
		});
	}

	var removeMemberFromRepo = function(memberToRemove){
		$.ajax({
			method : 'POST',
			url : 'http://localhost:3000/manage',
			data : {event : 'removeMember', username : memberToRemove},
			success : function(response){
				if(response.indexOf('Not Found') > -1){
					$('.error-message').html('User Not Found');
					$('.error').fadeIn().delay(1000).fadeOut();
				} else if (response.indexOf('not supported') > -1) {
					$('.error-message').html(response);
					$('.error').fadeIn().delay(1000).fadeOut();
				} else {
					$('.success').html(response);
					$('.success').fadeIn().delay(1000).fadeOut();
					$('.remove-member').hide();
					getMembers();
				}
			}
		});
	}

	var checkinFile = function(fileName){
		$.ajax({
			method : 'POST',
			url : 'http://localhost:3000/manage',
			data : { event : 'checkin', filename : fileName},
			success: function(response){
				window.location = 'http://localhost:3000/manage';
			}
		});
	}

	var getRevisions = function(fileName){
		$.ajax({
			method : 'POST',
			url : 'http://localhost:3000/manage',
			data : { event : 'getRevisions', filename : fileName},
			success : function(response){
				console.log(response);
				$('.success').html('<div style="text-align:left;">' + response.replace('\n','<br>') + '</div>');
				$('.success').fadeIn().delay(2000).fadeOut();
			}
		});
	}

	var backupRepo = function(){
		$.ajax({
			method : 'POST',
			url : 'http://localhost:3000/manage',
			data : { event : 'backupRepo' },
			success : function(response){
				$('.success').html('<div style="text-align:left;">' + response.replace('\n','<br>') + '</div>');
				$('.success').fadeIn().delay(2000).fadeOut();
			}
		});
	}

});