// Fix resolution between prototype and jquery.
jQuery.noConflict();

function closeModal(id) {
  jQuery("#" + id).modal('hide')
}

jQuery(document).ready(
	function($){

    function updateNotifications() {
  	  $("#notificationsArea").html("<strong>Loading...</strong>");
      $.get('/notifications/panel', function(data) {
			  $('#notificationsArea').html(data);
			});
    }

    function periodicActions() {
	    updateCount();
    }

    function isStillLoggedIn() {
	    $.ajax({
				  url: "/index/logged_in",
			    cache: false,
			    dataType: "json",
			    success: function (json) {
			      valid = json.valid;
			      
			      if (valid) {
				      periodicActions();
			      } else {
				      window.location = "/index/timeout"
			      } 
			    },
			    error: function (e, xhr) {
            clearInterval();
			    }
			  });
    }

    function updateCount() {
			$.ajax({
				  url: "/notifications/get_count",
			    cache: false,
			    dataType: "json",
			    success: function (json) {
			      count = json.count;
			      
			      $("#notificationButton").html(count);
			      if (count == 0) {
				      $("#notificationButton").removeClass("btn-success");
			      } else {
				      $("#notificationButton").addClass("btn-success");
			      }
			    },
			    error: function (e, xhr) {
            clearInterval();
			    }
			  });
		}

		// background updater for notifications count.
		setInterval(isStillLoggedIn, 15000);

		$('#notificationBox').modal({
		  keyboard: true,
		  show: false
		})

		$('#notificationBox').on('show', function () {
			updateNotifications();
		})

		$("a[rel=tooltip]").tooltip();
		$("i[rel=tooltip]").tooltip();
		$("a[rel=popover]").popover();
		$('.tabs a:first').tab('show');
		
		prettyPrint();

    // Do jQuery stuff using $
    //$("div").hide();
  });

