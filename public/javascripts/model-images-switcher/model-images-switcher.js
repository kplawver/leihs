/*
 * Model Images Switcher
 *
 * This script provides functionalities to switch images of a model easily on the show-view
 *
 * @name Model Images Switcher
 * @author Sebastian Pape <email@sebastianpape.com>
 * @last-change 15.07 11:27
*/

$(document).ready(function(){
	setupBindings();
});

function setupBindings() {
    // MOUSEENTER
    $('#model #images img').bind('mouseenter', function(){
        hoveredItem = $(this);
        $('#model #bigimages img').each(function() {
            if($(this).attr('src') == hoveredItem.attr('src').replace(/_thumb/g, "")) {
                $(this).stop().fadeIn();
                $('#model #bigimages .first').stop().animate({
                    opacity: 0
                });
            }
        });
    });
    
    // MOUSELEAVE
    $('#model #images img').bind('mouseleave', function(){
        hoveredItem = $(this);
        $('#model #bigimages img').each(function() {
            if($(this).attr('src') == hoveredItem.attr('src').replace(/_thumb/g, "")) {
                if($(this).css("opacity") != 1) {
                    $(this).removeAttr("style");
                }
                $(this).stop().fadeOut(400, function(){
                    $(this).removeAttr("style");
                });
                $('#model #bigimages .first').stop().animate({
                    opacity: 1
                });
            }
        });
    });
}