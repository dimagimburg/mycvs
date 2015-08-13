$(document).ready(function(){
	console.log('manage scripts loaded');
	var selectedMemberUsername;
	var selectedLocalFile;

	$('.remote-file').click(function(){
		var fileName = $(this).text().trim();
		var remotes = $('.remote-file');
		console.log(remotes);
		var selectedAlready = $(this).hasClass('remote-file-selected');
		for(var i = 0; i < remotes.length; i++){
			$(remotes[i]).removeClass('remote-file-selected');
		}
		if(!selectedAlready){
			$('.remote-files-actions').show(150);
			$(this).addClass('remote-file-selected');
		} else {
			$('.remote-files-actions').hide(150);
		}
	});

	$(document).on("click",".member",function(e){
		if(!$(e.target).hasClass('member-selected')){
			clearSelectedMembers();
			selectedMemberUsername = $(e.target).text();
			$(e.target).addClass('member-selected');
		} else {
			clearSelectedMembers();
		}
		toggleRemoveMember();
	});

	$(document).on("click",".local-file, .different",function(e){
		if(!$(e.target).hasClass('local-file-selected')){
			clearSelectedLocalFiles();
			selectedLocalFile = $(e.target).text();
			$(e.target).addClass('local-file-selected');
		} else {
			clearSelectedLocalFiles();
		}
		toggleCheckIn();
	});

	function clearSelectedLocalFiles(){
		selectedLocalFile = '';
		$('.local-file-selected').removeClass('local-file-selected');
	}

	function clearSelectedMembers(){
		selectedMemberUsername = '';
		$('.member-selected').removeClass('member-selected');
	}

	function toggleCheckIn(){
		if(selectedLocalFile == ''){
			$('.local-files-actions').find('.checkin').hide();
		} else {
			$('.local-files-actions').find('.checkin').show();
		}
	}

	function toggleRemoveMember(){
		if(selectedMemberUsername == ''){
			$('.member-actions').find('.remove-member').hide();
		} else {
			$('.member-actions').find('.remove-member').show();
		}
	}
});