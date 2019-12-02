$(function(){
	//アコーディオンメニュー
	$('.contents_selected_menu_title').on('click', function(){
		$(this).parents('.accordion-inner').toggleClass('hidden')
	})
})