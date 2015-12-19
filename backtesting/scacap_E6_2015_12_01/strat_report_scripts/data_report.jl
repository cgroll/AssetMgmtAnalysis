################################################################
## script should be called from backtest/scacap_E6_2015_12_01 ##
################################################################

########################
## define output file ##
########################

fname = joinpath(pwd(), "report_output/data_report.html")
outfile = open(fname, "w")

#######################
## define html marco ##
#######################

function imgCode(picNumb)
    return """<img src="../pics/data_report-$(picNumb).svg" alt="Returns" width="1000px"/>
"""
end

###############################
## print html header to file ##
###############################

htmlCode = """
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <meta http-equiv="Content-Style-Type" content="text/css" />
  <meta name="generator" content="pandoc" />
  <title></title>
  <style type="text/css">code{white-space: pre;}</style>
</head>
<body>
<h1 id="data-report">Data report</h1>

"""

write(outfile, htmlCode)

introParagraph = """<p>This report should give an overview over the data being used for backtesting.</p>

"""
write(outfile, introParagraph)

###################
## load packages ##
###################

## load some required packages
using TimeData
using DataFrames
using Econometrics
using Base.Test
using Dates
using Gadfly

loadPlotting()

## load asset management package
include(joinpath(homedir(),
                 "research/julia/AssetMgmt/src/AssetMgmt.jl"))

###############
## load data ##
###############

## load and process data
currDir = pwd()
include(joinpath(currDir, "../../dev/prepareData.jl"))

priceData, assetInfo, discRetsData = prepareData("../../financial_data/raw_data/")


## puts the following variables into workspace
## - priceData
## - assetInfo
## - discRetsData

nObs, nAss = size(discRetsData)

picsCounter = 1

shiftLabels = 1.

##########
## TODO ##
##########

## - add shorter names
## - fix y-axis number format

#####################
## plotting prices ##
#####################

priceHeader = """<h2 id="prices">Prices</h2>

"""
write(outfile, priceHeader)
write(outfile, "\n")

priceParagraph = """<p>Some plots to see price evolutions:</p>

"""

write(outfile, priceParagraph)

## create graphics
##----------------

## plot raw data
p = gdfPlot(priceData,
            Guide.xlabel("time"),
            Guide.ylabel("index value"),
            Scale.y_continuous(format=:plain));
draw(SVG("pics/data_report-$picsCounter.svg", 25cm, 15cm), p)
write(outfile, imgCode(picsCounter))
picsCounter += 1

## calculate normed log prices
##----------------------------

# prices without metadata
prices = asArr(priceData, Float64, NaN)

# cumulate log returns
logPrices = log(prices)
logRets = logPrices[2:end, :] - logPrices[1:end-1, :]
normedLogPrices = [zeros(1, nAss); cumsum(logRets, 1)]

# add metadata again
normedLogPriceData = Timematr(normedLogPrices, names(priceData), idx(priceData))

## calculate normed discrete returns
##----------------------------------

normedDiscRetsData = exp(normedLogPriceData) .- 1

# plot 
p = AssetMgmt.gdfPlotLabels(normedDiscRetsData,
                            Guide.xlabel("time"),
                            Guide.ylabel("discrete net return"),
                            shiftLabels = shiftLabels);
draw(SVG("pics/data_report-$picsCounter.svg", 25cm, 15cm), p)
write(outfile, imgCode(picsCounter))
picsCounter += 1

## plot normed log prices
##-----------------------

# plot 
p = AssetMgmt.gdfPlotLabels(normedLogPriceData,
                            Guide.xlabel("time"),
                            Guide.ylabel("log return"),
                            Scale.y_continuous(maxvalue=2.),
                            shiftLabels = shiftLabels
                            );
draw(SVG("pics/data_report-$picsCounter.svg", 25cm, 15cm), p)
write(outfile, imgCode(picsCounter))

picsCounter += 1

## plot with colorized asset class
##--------------------------------

p = AssetMgmt.gdfGroupPlot(normedLogPriceData,
                           Guide.xlabel("time"),
                           Guide.ylabel("log return"),
                           Guide.colorkey("Risk class"),
                           Scale.y_continuous(maxvalue=2.),
                           Scale.x_continuous(maxvalue=2016.),
                           variableInfo = assetInfo,
                           joinCol = :AssetLabel,
                           colorCol = :AssetClass,
                           shiftLabels = shiftLabels);
draw(SVG("pics/data_report-$picsCounter.svg", 25cm, 15cm), p)
write(outfile, imgCode(picsCounter))
picsCounter += 1


## plot with colorized region
##---------------------------

p = AssetMgmt.gdfGroupPlot(normedLogPriceData,
                           Guide.xlabel("time"),
                           Guide.ylabel("log return"),
                           Guide.colorkey("Region"),
                           Scale.y_continuous(maxvalue=2.),
                           Scale.x_continuous(maxvalue=2016.),
                           variableInfo = assetInfo,
                           joinCol = :AssetLabel,
                           colorCol = :Region,
                           shiftLabels = shiftLabels);
draw(SVG("pics/data_report-$picsCounter.svg", 25cm, 15cm), p)
write(outfile, imgCode(picsCounter))
picsCounter += 1

## plot with colorized risk class
##-------------------------------

p = AssetMgmt.gdfGroupPlot(normedLogPriceData,
                           Guide.xlabel("time"),
                           Guide.ylabel("log return"),
                           Guide.colorkey("Risk class"),
                           Scale.y_continuous(maxvalue=2.),
                           Scale.x_continuous(maxvalue=2016.),
                           variableInfo = assetInfo,
                           joinCol = :AssetLabel,
                           colorCol = :RiskClass,
                           shiftLabels = shiftLabels);
draw(SVG("pics/data_report-$picsCounter.svg", 25cm, 15cm), p)
write(outfile, imgCode(picsCounter))
picsCounter += 1

######################
## plotting returns ##
######################

returnHeader = """<h2 id="returns">Returns</h2>

"""
write(outfile, returnHeader)
write(outfile, "\n")

returnParagraph = """<p>Some return plots to check for stylized facts
and outliers:</p>

"""
write(outfile, returnParagraph)

## create graphics
##----------------

## get daily returns
discRetData = price2ret(priceData, log = false)

## p1 = gdfPlot(discRetData[:eqAs_DJAPSDET_Index]);
## p2 = gdfPlot(discRetData[:govEu_LEATTREU_Index]);
## draw(SVG("pics/data_report-7.svg", 25cm, 20cm),
##      vstack(p1, p2))

## plot returns for each series
for ii=1:nAss
    p = gdfPlot(discRetData[:, ii],
                Scale.y_continuous(minvalue=-0.2,
                                   maxvalue=0.2),
                Guide.xlabel("time"),
                Guide.ylabel("discrete net return"));
    draw(SVG("pics/data_report-$(picsCounter).svg", 25cm, 15cm),
         p)
    write(outfile, imgCode(picsCounter))
    picsCounter += 1
end

###############################
## plot time-varying moments ##
###############################

tvMomentsHeader =
    """<h2 id="time-varying-moments">Time-varying moments</h2>

"""
write(outfile, tvMomentsHeader)

tvParagraph = """<p>Show estimator applied successively over time:</p>"""
write(outfile, tvParagraph)


## specify default estimator
##--------------------------

defaultEstimators = [AssetMgmt.SampleMoments,
                     AssetMgmt.MovWinSampleMoments,
                     AssetMgmt.ExpWeighted]


for ii=1:length(defaultEstimators)

    currEst = string(defaultEstimators[ii])

    estName = lowercase(currEst)
    estimHeader = """<h3 id="estName">$currEst</h2>

"""
    
    write(outfile, estimHeader)

    outp = AssetMgmt.applyMuSigmaModelEstimator(defaultEstimators[ii],
                                         discRetsData)

    musOverTimeTd, sigmasOverTimeTd, corrOverTimeTd = outp

    p = gdfPlot(musOverTimeTd);
    draw(SVG("pics/data_report-$(picsCounter).svg", 25cm, 15cm), p)
    write(outfile, imgCode(picsCounter))
    picsCounter += 1

    p = gdfPlot(sigmasOverTimeTd);
    draw(SVG("pics/data_report-$(picsCounter).svg", 25cm, 15cm), p)
    write(outfile, imgCode(picsCounter))
    picsCounter += 1

    p = gdfPlot(corrOverTimeTd);
    draw(SVG("pics/data_report-$(picsCounter).svg", 25cm, 15cm), p)
    write(outfile, imgCode(picsCounter))
    picsCounter += 1

end

htmlEnd = """</body></html>"""
write(outfile, htmlEnd)

close(outfile)


