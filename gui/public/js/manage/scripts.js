$(document).ready(function(){
	console.log('manage scripts loaded');
	var selectedMemberUsername;
	var selectedLocalFile;

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