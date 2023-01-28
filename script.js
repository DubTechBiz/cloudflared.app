"use strict";
$('code[data-copy="true"]').on('click', function() {
	navigator.clipboard.writeText($(this).text().trim());
})
$(document).ready(() => {
	$('code[data-copy="true"]').each((i, e) => {
		$(e).tooltip({
			title: "Click to copy"
		});
	});
});
