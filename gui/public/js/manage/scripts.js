$(document).ready(function(){
	console.log('manage scripts loaded');
	var selectedMemberUsername;

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

	function clearSelectedMembers(){
		selectedMemberUsername = '';
		$('.member-selected').removeClass('member-selected');
	}

	function toggleRemoveMember(){
		if(selectedMemberUsername == ''){
			$('.member-actions').find('.remove-member').hide();
		} else {
			$('.member-actions').find('.remove-member').show();
		}
	}
});