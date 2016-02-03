// define accessor functions
function xAcc(d) { return +d.annual_sigmas; }
function yAcc(d) { return +d.annual_mus; }

// define margins
var margin = {top: 20, right: 80, bottom: 30, left: 150};

// graphics size without axis
var width = 960 - margin.left - margin.right;
var height = 500 - margin.top - margin.bottom;

var svg = d3.select("body").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

// axes scales
var xScale = d3.scale.linear()
    .range([0, width]);

var yScale = d3.scale.linear()
    .range([height, 0]);

var xAxis = d3.svg.axis()
    .scale(xScale)
    .orient("bottom");

var yAxis = d3.svg.axis()
    .scale(yScale)
    .orient("left")
    .ticks(5);

// parse dates and remove missing values
var parseDate = d3.time.format("%Y-%m-%d").parse;

var line = d3.svg.line()
    .interpolate("basis")
    .x(function(d) { return xAcc(d); })
    .y(function(d) { return yAcc(d); });

var momentData = d3.csv("allUnivInfo_short.csv", function (data) {
	 
	 // // transform dates to date format
    // data.forEach(function(d) {
    //     d.idx = parseDate(d.idx);
    // });
	 
	 // group data by date
	 var groupedDates = d3.nest()
		  .key(function(d) { return d.idx; })
		  .entries(data);
    
    xScale.domain(d3.extent(data, function(d) { return xAcc(d); }));
	 yScale.domain(d3.extent(data, function(d) { return yAcc(d); }));
    
    svg.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")")
        .call(xAxis);
    
    svg.append("g")
        .attr("class", "y axis")
        .call(yAxis)
        .append("text")
        .attr("transform", "rotate(-90)")
        .attr("y", 6)
        .attr("dy", ".71em")
        .style("text-anchor", "end")
        .text("Annualized expected return");
	 
	 // Add an x-axis label.
	 svg.append("text")
		  .attr("class", "x label")
		  .attr("text-anchor", "end")
		  .attr("x", width)
		  .attr("y", height - 6)
		  .text("Annualized volatility");
	 
	 // Add the year label; the value is set on transition.
	 var label = svg.append("text")
		  .attr("class", "year label")
		  .attr("text-anchor", "end")
		  .attr("y", height - 24)
		  .attr("x", width)
		  .text(groupedDates[0].key);
	 
	 // Positions the dots based on data.
	 function position(dot) {
	 	  dot.attr("cx", function(d) { return xScale(xAcc(d)); })
	 			.attr("cy", function(d) { return yScale(yAcc(d)); })
	 	  		.style("fill", "red")                            // <== and this one
	 			.attr("r", 3.5);
	 }
	 
	 function update(newData) {
		  
		  var momentDots = svg.selectAll("circle")
				.data(newData);
		  
		  // enter method
		  momentDots.enter()
				.append("circle")
				.call(position);
		  
		  // update method
		  momentDots.transition().duration(1000).call(position);
		  
		  // exit method
		  momentDots.exit().remove();
		  
	 }
	 
	 // var momentDots = update(groupedDates[0].values);
	 
	 // Start a transition that interpolates the data based on year.
	 // momentDots.transition()
	 //     .duration()
	 // 	  .data(groupedDates[1].values)
	 // 	  .call(position);
	 
	 // Tweens the entire chart by first tweening the year, and then the data.
	 // For the interpolated data, the dots and label are redrawn.
	 // function tweenDate() {
	 // 	  var thisDateInd = d3.interpolateNumber(0, 2);
	 // 	  return function(t) { displayDate(groupedDates[t].values); };
	 // }
	 
	 // function displayDate(thisData) {
	 // 	  momentDots.data(thisData, key).call(position);
	 // 	  label.text(thisData.key);
	 // }
	 
	 
	 // // get data for current date
	 // var currDateData = groupedDates[0].values;
	 
	 for ( var i = 0; i <= 2; ++i ) {
		  // update(groupedDates[i].values);
		  // update(groupedDates[i].values );
		  setTimeout( function (){ update(groupedDates[i].values ) }, 2000);
	 }
	 // setInterval(function () {
	 // dateInd = dateInd + 1;
	 // update(groupedDates[dateInd].values);
	 // }, 2000)
})
// render points subsequently
// 
// setTimeout( function (){ render(groupedDates[1].values ); }, 2000);
// setTimeout( function (){ render(groupedDates[2].values ); }, 3000);


// var effFront = svg.selectAll("effLine")

// effFront.datum(data)
// 	  .append("g")
//     .attr("class", "effLine")
//     .append("path")
//     .attr("class", "line")
// 	  .attr("fill", "none")
// 	  .attr('stroke', 'blue')
// 	  .attr('stroke-width', 2)
//     .attr("d", line(data));

