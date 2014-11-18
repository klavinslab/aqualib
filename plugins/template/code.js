Plugin.prototype.update = function() {

  this.ajax({x:0},function(result) {
    if ( result.error ) {
      $('#main').append('<p><b>Interface Error: </b>'+result.error+'</p>');
    } else {
      render_json($("#main"),result);
    }  
  });

}

p = new Plugin();
p.update();