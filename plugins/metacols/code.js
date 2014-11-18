Plugin.prototype.render = function(data) {

  var table = $(aq.template('metacol-table'));

  $.each(data.metacols,function(i) {

    var row = $("<tr />")
      .addClass("metacol-table-row")
      .data("submitter",this.login == data.current_user.login ? "yes" : "no")
      .append("<td>" + aq.metacol_link(this.id) + "</td>")
      .append("<td>" + aq.filename(this.path) + "</td>")
      .append("<td>" + aq.user_link(this.user_id,this.login) + "</td>")
      .append("<td>" + this.date + "</td>");

    table.append(row);

  });


  $("#main").empty().append(table);

  $("#current-user").html(data.current_user.login);
  $('#limit-to-current-user').attr("checked", this.limit);

}

Plugin.prototype.update = function() {

  var that = this;

  this.ajax({x:0},function(result) {
    if ( result.error ) {
      $('#main').append('<p><b>Interface Error: </b>'+result.error+'</p>');
    } else {
      that.render(result);
    }  
  });

}

Plugin.prototype.limiter = function() {

  var rows = $(".metacol-table-row").filter(function() { return $(this).data("submitter") != "yes"; } );

  if ( this.limit ) {
    rows.hide();
  } else {
    rows.show();
  }

}

Plugin.prototype.init = function() {

  var that = this;
  this.limit = false;

  p.update();

  $('#limit-to-current-user').on("click",function() {
    that.limit = !that.limit;
    that.limiter();
  });

}

p = new Plugin();
p.period(60000);
p.init();
