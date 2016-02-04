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
		  .attr("class", "thisFracInd label")
		  .attr("text-anchor", "end")
		  .attr("y", height - 24)
		  .attr("x", width)
		  .text(groupedDates[0].key);
	 
	  var momentDots = svg.selectAll("circle")
        .data(interpolateData(0))
		  .enter().append("circle")
        .call(position);
	 
	 // Positions the dots based on data.
	 function position(dot) {
	 	  dot.attr("cx", function(d) { return xScale(xAcc(d)); })
	 			.attr("cy", function(d) { return yScale(yAcc(d)); })
	 	  		.style("fill", "red")                            // <== and this one
	 			.attr("r", 3.5);
	 }
	 
	 // Updates the display to show the specified year.
	 function displayDate(thisFracInd) {
		  momentDots.data(interpolateData(thisFracInd))
				.call(position);
		  // label.text(Math.round(year));
	 }
	 
	 // get data for fractional index
	 function interpolateData(thisFracInd) {
		  // round index
		  ind = indexQuantize(thisFracInd)
		  return groupedDates[ind].values
	 }
	 
	 function indexQuantize(t){
		  var interpolate = d3.scale.quantize() // <-C .domain([0, 1])
				.range([0, 1, 2]);
		  // return function(t){ // <-D
		  return interpolate(t);
		  // };
	 }
	 
	 function tweenDate() {
		  var thisFracInd = d3.interpolateNumber(0, 4)
		  return function(t) { displayDate(thisFracInd(t)) };
	 }
	 
	 svg.transition()
		  .duration(20000)
		  .ease("linear")
		  .tween("thisFracInd", tweenDate);
	 
	 // update method
	 // momentDots.transition().duration(1000)
	 // .tween("date", indexQuantize);
	 
	 // setTimeout( function (){ displayDate(indexQuantize(0.77)); }, 2000);
	 
	 // exit method
	 // momentDots.exit().remove();
	 
})
