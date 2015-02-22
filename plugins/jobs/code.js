
Plugin.prototype.render = function(data) {

  var that = this;
  var pills = [ "active", "pending", "urgent", "future" ];

  $.each(pills,function(i) {

    if ( data[this].length > 0 ) {

      var pill = this;
      var table = aq.template('job-table',{ pill: pill });

      $.each(data[this],function(j) {


        table.append(
          aq.template('job-table-row', { 
            pill: pill,
            job: aq.job_link(this.id,this.id),
            path: aq.filename(this.path) + (this.metacol_id > 0 ? " (" + aq.metacol_link(this.metacol_id) + ")" : ""),
            submitted_by: aq.user_link(this.submitted_by,this.submitted_login),
            user: aq.user_link(this.user_id,this.user_login),           
            group: aq.group_link(this.group_id,this.group_name),
            start_link: this.start,
            last_update: this.last_update
          }).data("submitter",this.submitted_login == data.current_user.login ? "yes" : "no")
        );
      });

      $('#'+this).empty().append(table);

    } else {

      $('#'+this).empty().append("<p class='text-center'>No "+this+' jobs.');

    }

    $('#'+this+'-pill').html(aq.capitalize(this)+': '+data[this].length);

  });

  $('#current-user').html(data.current_user.login);
  $('#limit-to-current-user').attr("checked", this.limit);

  $(function() {
    $('.confirm').click(function() {
        return window.confirm("Are you sure you want to start/resume this job?");
    });
});

}

Plugin.prototype.update = function() {

  var that = this;

  this.ajax({x:0},function(result) {
    if ( result.error ) {
      $('#main').append('<p><b>Interface Error: </b>'+result.error+'</p>');
    } else {
      that.render(result);
      that.limiter();      
    }  
  });

}

Plugin.prototype.limiter = function() {

  var rows = $(".job-table-row").filter(function() { return $(this).data("submitter") != "yes"; } );

  if ( this.limit ) {
    rows.hide();
  } else {
    rows.show();
  }

}

Plugin.prototype.init = function() {

  var that=this;

  $(".job-list").css('display','none');
  $("#pending").css('display','block');

  var pills = [ "active", "pending", "urgent", "future" ];

  $.each(pills,function(p) {

    $('#'+pills[p]+'-pill').click(function(e) {
      e.preventDefault();
      e.stopImmediatePropagation();
      $('ul.nav li').removeClass('active');
      $('.job-list').css('display','none');
      $(this).parent().addClass('active');
      $('#'+pills[p]).css('display','block');
    })

  });

  this.update();

  this.limit = false;

  $('#limit-to-current-user').on("click",function() {
    that.limit = !that.limit;
    that.limiter();
  });

}

p = new Plugin();
p.period(15000);
p.init();
