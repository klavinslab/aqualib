Plugin.prototype.render = function(data) {

  var that=this;
  var table = $(aq.template('activity-table'));
  var max = 0;
  $.each(data,function(i) {
    if ( data[i].count > max) {
      max = data[i].count;
    }
  });

  $.each(data,function(i) {
    table.append($('<tr>')
      .append('<td>' + aq.user_link(data[i].id,data[i].login)+'</td>')
      .append('<td><div class="bar" style="width:'+(100*data[i].count/max)+'%">'+data[i].count+'</div></td>')
      .append('<td>'+data[i].latest+'</td>')      
    );   
  });

  $("#main").empty().append(table);

  $("#days").val(this.days).change(function(){
    that.days = parseInt($("#days").val());
    that.update();
  });

}

Plugin.prototype.update = function() {

  var that = this;

  this.ajax({num:this.days},function(result) {
    if ( result.error ) {
      $('#main').append('<p><b>Interface Error: </b>'+result.error+'</p>');
    } else {
      that.render(result.data);
    }
  });

}

p = new Plugin();
p.days = 10;
p.period(10*60000);
p.update();
