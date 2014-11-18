Plugin.prototype.update = function() {

  this.ajax({x:0},function(result) {

    if ( result.error ) {

      $('#main').append('<p><b>Interface Error: </b>'+result.error+'</p>');

    } else {

      var date = new Date(result.timestamp);

      $('#timestamp').html(aq.nice_time(date));

      if(result.krill_response.error) {

        $('#alert').addClass('alert');
        $('#status').html(result.krill_response.error);
        $('#jobs').html('-');

      } else {

        $('#alert').removeClass('alert');
        $('#status').html('Running');

        var jobs = [];
        for ( var i=0; i<result.krill_response.jobs.length; i++ ) {
          jobs.push ( aq.job_link(result.krill_response.jobs[i]));
        }

        $('#jobs').html('['+jobs.join(',')+']');

        var d = _.difference(
          _.union(result.krill_response.jobs,result.active_krill_jobs),
          _.intersection(result.krill_response.jobs,result.active_krill_jobs)
        )

        if ( d.length > 0 ) {
          $('#alert').addClass('alert');
          $('#warnings').html('. Warning: The states of following jobs are inconsistent: ['+d.join(',')+']');
        } else {
          $('#alert').removeClass('alert');        
          $('#warnings').html('');
        }

      }

    }  

    var krill = [];
    var metacol = [];

    for ( var i=0; i<result.ps.length; i++ ) {
      var x = result.ps[i];
      if ( x.match ( /Krill/ ) ) {
        krill.push ( x.split(/[ ,]+/)[1] );
      }
      if ( x.match ( /Metacol/ ) ) {
        metacol.push ( x.split(/[ ,]+/)[1] );
      }
    }

    if ( krill.length == 0 ) {
      $('#krill').addClass('alert');
    } else {
      $('#krill').removeClass('alert');
    }

    if ( metacol.length == 0 ) {
      $('#metacol').addClass('alert');
    } else {
      $('#metacol').removeClass('alert');
    }

    $('#krill').html("[" + krill.join(',') + "]");
    $('#metacol').html("[" + metacol.join(',') + "]");    

  });

}

p = new Plugin();
p.period(60000);
p.update(); 