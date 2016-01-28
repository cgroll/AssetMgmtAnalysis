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
var x = d3.scale.linear()
    .range([0, width]);

var y = d3.scale.linear()
    .range([height, 0]);

var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom");

var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left")
    .ticks(5);

// parse dates and remove missing values
var parseDate = d3.time.format("%Y-%m-%d").parse;

var line = d3.svg.line()
    .interpolate("basis")
    .x(function(d) { return x(d.annual_sigmas); })
    .y(function(d) { return y(d.annual_mus); });

var momentData = d3.csv("allUnivInfo_short.csv", function (data) {
    
    data.forEach(function(d) {
        d.idx = parseDate(d.idx);
    });
    
    x.domain(d3.extent(data, function(d) { return +d.annual_sigmas; }));
	 y.domain(d3.extent(data, function(d) { return +d.annual_mus; }));
    
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
        .text("GDP in bn $");
    
    // var gdp = svg.selectAll("circle")
    //     .data(data)
    //     .enter()
    //     .append("circle")
	 // 	  .attr("cx", function(d) {
	 // 			return x(+d.annual_sigmas);
	 // 	  })
	 // 	  .attr("cy", function(d) {
	 // 			return y(+d.annual_mus);
	 // 	  })
	 // 	  .attr("r", 2);
	 
	 // get current date
	 var currDate = data[5].idx;
	 
	 // select all points of current date
	 svg.selectAll("circle")  
        .data(data)                                     
		  .enter().append("circle")
		  .attr("cx", function(d) {
	 			return x(+d.annual_sigmas);
	 	  })
	 	  .attr("cy", function(d) {
	 			return y(+d.annual_mus);
	 	  })                               
		  .filter(function(d) { return d.idx.getTime() == currDate.getTime() })        // <== This line
        .style("fill", "red")                            // <== and this one
        .attr("r", 3.5);

	 var effFront = svg.selectAll("effLine")

	 effFront.datum(data)
		  .append("g")
        .attr("class", "effLine")
        .append("path")
        .attr("class", "line")
	 	  .attr("fill", "none")
	 	  .attr('stroke', 'blue')
	 	  .attr('stroke-width', 2)
        .attr("d", line(data));

	 
	 // svg.append("g")
    //     .attr("class", "effLine")
    //     .append("path")
    //     .attr("class", "line")
	 // 	  .attr("fill", "none")
	 // 	  .attr('stroke', 'blue')
	 // 	  .attr('stroke-width', 2)
    //     .attr("d", line(data));
    
	 
})
