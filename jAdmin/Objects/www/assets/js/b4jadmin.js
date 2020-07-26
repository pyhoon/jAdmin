    $( document ).ready(function() {
      $("#btnLogin").click(function(e) {
        e.preventDefault();
        $.ajax({
          type: "POST",
          url: "signin",
          data: $("form").serialize(), 
          success: function(result)
          {
           if (result.success) {
            window.location  = '/';
          }
          else {
            //alert(result.errorMessage);
            $(".alert").html(result.errorMessage);
            $(".alert").fadeIn();
          }
        },
        error: function (xhr, ajaxOptions, thrownError) {
          //alert(thrownError);
          $(".alert").html(thrownError);
          $(".alert").fadeIn();  
        }
      });
      });

      $("#btnLogout").click(function(e) {
        e.preventDefault();
        $.ajax({
          type: "POST",
          url: "logout",
          success: function()
          {
            window.location  = '/';
          },
          error: function (xhr, ajaxOptions, thrownError) {
          //alert(thrownError);
          $("#page-alert").html(thrownError);
          $("#page-alert").fadeIn();          
        }
      });
      });

      // On change of dropdown fire on change event
      $('#selectdatabase').change( function()
      {
        $.ajax({   
          type: "POST",
          url: "selectdatabase",
          data: {
            selectdatabase: $('#selectdatabase').find("option:selected").val()
          },
          success: function(data)
          {
            //adds the echoed response to our container
            $("#datatables").html(data);
          }
        });
        return;
      });

      $("#btnExecute").click(function(e) {
        e.preventDefault();
        $.ajax({
          type: "POST",
          url: "execute",
          data: {
           selectdatabase: $('#selectdatabase').find("option:selected").val(),
           statement: $('#statement').val()                    
         },
          // data: $("form").serialize(),
          success: function(result)
          {
           if (result.success) {
            //window.location  = '/';
            $("#execute-alert").removeClass("alert-danger");
            $("#execute-alert").addClass("alert-success");
            $("#execute-alert").html('Success');
            $("#execute-alert").fadeIn(); 
          }
          else {
            $("#execute-alert").html('Failed');
            $("#execute-alert").fadeIn();             
          }
        },
        error: function (xhr, ajaxOptions, thrownError) {
          //alert(thrownError);
          $("#execute-alert").html(thrownError);
          $("#execute-alert").fadeIn();          
        }
      });
      });
    });