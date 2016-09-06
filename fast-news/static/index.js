$('.modal').click(function(e) {
	if ($(e.target).parents('.box').length == 0) {
		$(e.currentTarget).hide();
	}
})

$('#try').click(function() {
	$('#signup-modal').show();
	$('#signup input[type=email]').focus();
})

$('#signup').submit(function(e) {
	e.preventDefault();
	var email = $('#signup input[type=email]').val();
	if (email.length) {
		$('#signup input[type=submit]').val('Loading...');
		submitEmail(email, function(success) {
			$('#signup input[type=submit]').val('Submit');
			if (success) {
				$('#signup-modal').hide();
				$('#confirm-modal').show();
			} else {
				alert("Sorry, there was an error adding you to the list.")
			}
		})
	}
})

$('#confirm-modal form').submit(function(e) {
	e.preventDefault();
	$('#confirm-modal').hide();
})

function submitEmail(email, callback) {
	var url = '/email_list/add?email=' + encodeURIComponent(email);
	$.post(url, function(cb) {
		callback(true);
	})
}
