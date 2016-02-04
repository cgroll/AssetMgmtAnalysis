// define accessor functions
function xAcc(d) { return +d.annual_sigmas; }
function yAcc(d) { return +d.annual_mus; }
function colorAcc(d) { return d.name; }


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

var colorScale = d3.scale.category20();

// define line interpreter
var line = d3.svg.line()
	 .interpolate("basis")
    .x(function(d) { return xScale(xAcc(d)); })
    .y(function(d) { return yScale(yAcc(d)); });

var xAxis = d3.svg.axis()
    .scale(xScale)
    .orient("bottom");

var yAxis = d3.svg.axis()
    .scale(yScale)
    .orient("left")
    .ticks(5);

// parse dates and remove missing values
var parseDate = d3.time.format("%Y-%m-%d").parse;

var momentData = d3.csv("allUnivInfo_short.csv", function (data) {

	 // determine axis from complete data
	 xScale.domain(d3.extent(data, function(d) { return xAcc(d); }));
	 yScale.domain(d3.extent(data, function(d) { return yAcc(d); }));
	 
	 // group data by date and portfolio type
	 var groupedDates = d3.nest()
		  .key(function(d) { return d.idx; })
		  .key(function(d) { return d.pfType})
		  .entries(data);

	 // append x axis
    svg.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")")
        .call(xAxis);

	 // append y axis with label
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
	 
	 // Add the date label; the value is set on transition.
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

	 // plot single day correctly
	 var assetDots = svg.selectAll("asset circle")
		  .data(groupedDates[0].values[0].values);

	 // enter + update method asset points
	 assetDots.enter()
		  .append("circle")
		  .attr("class", "asset circle")
		  .call(position)
		  .style("fill", function(d) { return colorScale(colorAcc(d)); });

	 // enter + update global minimum
	 var gmvDot = svg.selectAll("gmv circle")
		  .data(groupedDates[0].values[1].values);

	 gmvDot.enter()
		  .append("circle")
		  .attr("class", "gmv circle")
		  .call(position);

	 // enter + update max sharpe
	 var maxSharpeDot = svg.selectAll("maxSharpe circle")
		  .data(groupedDates[0].values[2].values);

	 maxSharpeDot.enter()
		  .append("circle")
		  .attr("class", "maxSharpe circle")
		  .call(position)
		  .style("fill", "blue");
	 
	 // enter + update method efficient frontier
	 svg.append("path")
		  .datum(groupedDates[0].values[3].values)
		  .attr("class", "line")
		  .attr("d", line);

	 
	 // function update(newData) {
		  
	 // 	  var momentDots = svg.selectAll("circle")
	 // 			.data(newData.values[0].values);
		  
	 // 	  // enter method
	 // 	  momentDots.enter()
	 // 			.append("circle")
	 // 			.call(position);
		  
	 // 	  // update method
	 // 	  momentDots
	 // 			.transition()
	 // 			.duration(1000)
	 // 			.call(position);
		  
	 // 	  // exit method
	 // 	  momentDots.exit().remove();

	 // 	  // change date label
	 // 	  label.text(newData.key)
	 // }

	 // var endInd = groupedDates.length;
	 // var thisInd = 0;
	 // var interval = setInterval(function() {
	 // 	  update(groupedDates[thisInd])
    //     thisInd++; 
    //     if(thisInd >= endInd) clearInterval(interval);
    // }, 500);

})
