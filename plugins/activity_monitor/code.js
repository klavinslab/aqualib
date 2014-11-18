HOUR = 60*60*1000;
DAY = 24*HOUR;

Plugin.prototype.settings = function() {
  var that = this;

  $.cookie.json = true;

  if ( ! $.cookie('params') ) {
    this.window = 7;   // days
    this.tick = 8;     // hours
    this.refresh = 60; // seconds
    $.cookie('params',{window: 7, tick: 4, refresh: 60});
  } else {
    this.window = $.cookie('params').window;
    this.tick = $.cookie('params').tick;     
    this.refresh = $.cookie('params').refresh;
  }

  $("#info").click(function() { 
    $("#window").val(that.window);
    $("#tick").val(that.tick);
    $("#refresh").val(that.refresh);    
    $("#data").css('display','none');
    $("#settings").css('display','block');   
  } );

  $("#save-settings").click(function() { 
    that.window = parseFloat($("#window").val());
    that.tick = parseFloat($("#tick").val());
    that.refresh = parseFloat($("#refresh").val()); 
    $.cookie('params',{window: that.window, tick: that.tick, refresh: that.refresh});    
    $("#data").css('display','block');
    $("#settings").css('display','none');
    that.init();
  } );

  $("#cancel").click(function() {   
    $("#data").css('display','block');
    $("#settings").css('display','none');  
  } );

}

Plugin.prototype.init= function() {

  //console.log([this.window,this.tick,this.refresh]);

  var now = new Date().getTime();
  var that = this;

  this.bins = [];
  for (var t=0; t<this.window*24; t += this.tick ) {
    this.bins.unshift ( { from: now - t*HOUR, to: now - t*HOUR + this.tick*HOUR, jobs: [], samples: [] } ) 
  }

  p.period(1000*this.refresh);
  this.last_update = 0;
  this.get_data(now-this.window*DAY);

  if ( this.window > 1 ) {
    $("#info").html("Last " + this.window + " days");
  } else {
    $("#info").html("Last " + this.window*24 + " hours");
  }

}

Plugin.prototype.update_bins = function(data) {

  var n = this.bins.length-1;

  // add new bin if needed
  if ( this.last_update >= this.bins[n].to ) {
    this.bins.push ( { from: this.bins[n].to, to: this.bins[n].to + this.tick*HOUR, jobs: [] } )
    this.bins.shift;
  }

  this.add_to_bins(data,"jobs");
  this.add_to_bins(data,"samples");

}

Plugin.prototype.add_to_bins = function(data,field) {

  var n = this.bins.length-1;

  // put new data points in bins
  for ( var i=0; i<data[field].length; i++ ) {
    var t = new Date(data[field][i].updated_at).getTime();
    j = n;
    while ( t < this.bins[j].from && j > 0 ) {
      j--;
    }
    if ( j >= 0 ) {
      this.bins[j][field].push(data[field][i].id);
    }
  }

}

Plugin.prototype.get_data = function(since) {

  var that = this;

  this.ajax({since:since/1000},function(result) {
    if ( result.error ) {
      $('#data').append('<p><b>Interface Error: </b>'+result.error+'</p>');
      that.period(-1);
    } else {
      //console.log(result);
      that.last_update = new Date(result.timestamp).getTime();
      that.update_bins(result);
      that.render(result);
    }  
  });

  //console.log('ajax request made');

}

Plugin.prototype.update = function(data) {
  this.get_data(this.last_update);
}

Plugin.prototype.render = function(data) {

  //console.log('render');

  var jobs=[];
  var samples=[];

  for ( var i=0; i<this.bins.length; i++ ) {
    jobs.push([this.bins[i].from,_.uniq(this.bins[i].jobs).length]);
    samples.push([this.bins[i].from,_.uniq(this.bins[i].samples).length]);
  }

  var opts = {
    xaxis: {
      show: true
    },
    yaxes: [ 
      { min: 0 }, 
      { position: "right", min: 0 } 
    ],
    grid: {
      minBorderMargin: 0,
      borderWidth: {
        top: 0, right: 0, bottom: 0, left: 0
      }
    }
  };

  $("#data").plot([ 
    { label: "Jobs Completed", 
      data: jobs, 
      bars: {
        show: true,
        barWidth : this.tick*HOUR,
        lineWidth: 0,
        color: "rgba(255, 165, 0, 0.8)",
        fillColor: "rgba(255, 165, 0, 0.8)"
      } },
    { label: "Samples Created", 
      data: samples, 
      bars: {
        show: true,
        barWidth : this.tick*HOUR,
        lineWidth: 0,
        color: "rgba(90, 90, 255, 0.5)",        
        fillColor: "rgba(90, 90, 255, 0.5)",
      },
      yaxis: 2
     }      
  ],opts);

}

p = new Plugin();
p.settings();
p.init();


