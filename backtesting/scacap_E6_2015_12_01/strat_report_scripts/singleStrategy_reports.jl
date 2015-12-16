################################################################
## script should be called from backtest/scacap_E6_2015_12_01 ##
################################################################

## The script creates a report for each single strategy where
## respective weights are stored in backtest_wgts.

########################
## get all strategies ##
########################

wgtFiles = readdir("backtest_wgts")
nStrats = length(wgtFiles)
stratNames = [split(wgtFiles[ii], ".")[1] for ii=1:nStrats]

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

##############################
## dev with single strategy ##
##############################

for currStratInd=1:nStrats

    currFileName = wgtFiles[currStratInd]
    currStratName = stratNames[currStratInd]


########################
## define output file ##
########################

fname = joinpath(pwd(), "report_output/$(currStratName)_report.html")
outfile = open(fname, "w")

#######################
## define html marco ##
#######################

function imgCode(picNumb)
    return """<img src="../pics/$currStratName-$(picNumb).svg" alt="Returns" width="1000px"/>
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

<h1 id="report">$currStratName report</h1>

"""

write(outfile, htmlCode)

introParagraph = """<p>This report should give an overview over the
performance of strategy $currStratName during backtesting.</p>

"""
write(outfile, introParagraph)


###############
## load wgts ##
###############

invs = AssetMgmt.readInvestments("backtest_wgts/$currFileName")

###############
## load data ##
###############

## load and process data
include("../../dev/prepareData.jl")

## path needs to be relative to present directory
priceData, assetInfo, discRetsData = prepareData("../../financial_data/raw_data/")

nObs, nAss = size(discRetsData)

picsCounter = 1

#####################
## get short names ##
#####################

shortNames = String[string(names(invs)[ii]) for ii=1:nAss] |>
    x -> Symbol[split(x[ii], "_")[1] for ii=1:nAss]

names!(invs.vals, shortNames)
names!(discRetsData.vals, shortNames)

#######################
## visualize weights ##
#######################

weightsHeader = """<h2 id="weights-analysis">Weights analysis</h2>

"""
write(outfile, weightsHeader)
write(outfile, "\n")

weightsParagraph = """<p>Some plots to see weights changes over time:</p>

"""

write(outfile, weightsParagraph)


p = gdfPlot(convert(Timematr, invs),
            Guide.xlabel("time"),
            Guide.ylabel("μ"));
draw(SVG("pics/$currStratName-$picsCounter.svg", 15cm, 10cm), p)
write(outfile, imgCode(picsCounter))
picsCounter += 1

## get number of weights
nWgts = size(invs, 1)

## with continuous colors
##-----------------------

## create x, y and color vectors
xVals = repmat([1:nWgts]', nAss, 1)[:]
yVals = (asArr(invs)')[:]
colVals = repmat([1:nAss], nWgts, 1)[:]

df = DataFrame(x = xVals, y = yVals, color = colVals)

## plot only positive weights
posWgts = df[df[:y] .> 0, :]
negWgts = df[df[:y] .< 0, :]

pPos = plot(posWgts, x="x", y="y", color="color",
            Geom.bar(position=:stack));

pNeg = plot(negWgts, x="x", y="y", color="color",
            Geom.bar(position=:stack));
draw(SVG("pics/$currStratName-$picsCounter.svg", 15cm, 10cm),
            vstack(pPos, pNeg))
write(outfile, imgCode(picsCounter))
picsCounter += 1

## with usual asset colors
##------------------------

colVals = repmat(names(invs), nWgts, 1)[:]

df = DataFrame(x = xVals, y = yVals, color = colVals)

## plot only positive weights
posWgts = df[df[:y] .> 0, :]
negWgts = df[df[:y] .< 0, :]

pPos = plot(posWgts, x="x", y="y", color="color",
            Geom.bar(position=:stack));

pNeg = plot(negWgts, x="x", y="y", color="color",
            Geom.bar(position=:stack));
draw(SVG("pics/$currStratName-$picsCounter.svg", 30cm, 30cm),
     vstack(pPos, pNeg))
write(outfile, imgCode(picsCounter))
picsCounter += 1


###########################
## get portfolio returns ##
###########################

performanceHeader = """<h2 id="performance">Performance</h2>

"""
write(outfile, performanceHeader)
write(outfile, "\n")

performanceParagraph = """<p>Some plots to analyse portfolio evolution:</p>

"""
write(outfile, performanceParagraph)


pRets = AssetMgmt.invRet(invs, discRetsData)

p = gdfPlot(pRets,
            Guide.xlabel("time"),
            Guide.ylabel("discrete net return"));
draw(SVG("pics/$currStratName-$picsCounter.svg", 15cm, 10cm), p)
write(outfile, imgCode(picsCounter))
picsCounter += 1

#######################################
## get idealized portfolio evolution ##
#######################################

pEvol = log(ret2price(pRets, log = false))


## get normalized log asset prices
##--------------------------------

matchingAssetPrices = priceData[idx(pEvol), :]
matchingAssetRets = price2ret(log(matchingAssetPrices), log = true)
matchingAssetPricesNormed = ret2price(matchingAssetRets, log = true)


tn = [matchingAssetPricesNormed pEvol]

nAss = size(matchingAssetPricesNormed, 2)
newAssetInfo = DataFrame()
newAssetInfo[:AssetLabel] = names(tn)
newAssetInfo[:Color] = [String["asset" for ii=1:nAss], "portfolio"]
newAssetInfo[:Label] = [String["" for ii=1:nAss], "minSigma"]

col1 = Color.RGB(0.8, 0.8, 0.8)
col2 = Color.RGB(0.8, 0., 0.)
p = AssetMgmt.gdfGroupPlot(tn,
                           Scale.color_discrete_manual(color(col1),
                                                       color(col2)),
                           Guide.xlabel("time"),
                           Guide.ylabel("log return"),
                           Guide.colorkey("Type"),
                           variableInfo = newAssetInfo,
                           joinCol = :AssetLabel,
                           colorCol = :Color,
                           labelCol = :Label,
                           shiftLabels = 3.)
draw(SVG("pics/$currStratName-$picsCounter.svg", 15cm, 10cm), p)
write(outfile, imgCode(picsCounter))
picsCounter += 1


#####################
## net performance ##
#####################

## specify transaction costs
tc = 0.002

## get turnover
tov = AssetMgmt.turnover(invs, discRetsData)

function getNetPerformance(pRets::Timematr,
                           tov::Timematr,
                           tc::Float64 = 0.002)
    ## preallocation
    nObs =size(pRets, 1)
    netPerf = Array(Float64, nObs)
    tovArr = asArr(tov, Float64, NaN)
    netPerf[1] = 1*(1 + get(pRets, 1, 1)) # one Euro after first day
    for ii=2:nObs
        ## get money amount traded: evening portfolio value last day
        ## times turnover this day (in the morning)
        tradedMoney = tovArr[ii]*netPerf[ii-1]
        tradingCosts = tradedMoney*tc 
        morningValue = netPerf[ii-1] - tradingCosts
        eveningValue = morningValue*(1 + get(pRets, ii, 1))
        netPerf[ii] = eveningValue
    end
    return Timematr(netPerf, [:netPerf], idx(pRets))
end

netPerf = getNetPerformance(pRets, tov)

netPerfExt = Timematr([1; asArr(netPerf, Float64, NaN)],
                      [:pNetPerf],
                      [idx(pEvol)[1]; idx(netPerf)])

## visualize
##----------

tn = [matchingAssetPricesNormed pEvol log(netPerfExt)]

nAss = size(matchingAssetPricesNormed, 2)
newAssetInfo = DataFrame()
newAssetInfo[:AssetLabel] = names(tn)
newAssetInfo[:Color] = [String["asset" for ii=1:nAss], "gross", "net"]
newAssetInfo[:Label] = [String["" for ii=1:nAss], "minSigma", "minSigmaNet"]

col1 = Color.RGB(0.8, 0.8, 0.8)
col2 = Color.RGB(0.8, 0., 0.)
col3 = Color.RGB(0., 0.8, 0.)
p = AssetMgmt.gdfGroupPlot(tn,
                           Scale.color_discrete_manual(color(col1),
                                                       color(col2),
                                                       color(col3)),
                           Guide.xlabel("time"),
                           Guide.ylabel("log return"),
                           Guide.colorkey("Type"),
                           variableInfo = newAssetInfo,
                           joinCol = :AssetLabel,
                           colorCol = :Color,
                           labelCol = :Label,
                           shiftLabels = 3.)
draw(SVG("pics/$currStratName-$picsCounter.svg", 15cm, 10cm), p)
write(outfile, imgCode(picsCounter))
picsCounter += 1


##################
## moments plot ##
##################

muStrat = mean(asArr(pRets, Float64, NaN))
sigmaStrat = std(asArr(pRets, Float64, NaN))

lastDate = idx(discRetsData)[end]
mod = AssetMgmt.fitModel(AssetMgmt.SampleMoments,
                         discRetsData,
                         lastDate)

moments = DataFrame()
moments[:AssetLabel] = [mod.names; symbol(currStratName)]
moments[:mu] = [mod.mu; muStrat]
moments[:sigma] = [AssetMgmt.getVolas(mod); sigmaStrat]

plotVarInfo = DataFrame()
plotVarInfo[:AssetLabel] = [mod.names; symbol(currStratName)]
plotVarInfo[:Class] = [["asset" for ii=1:nAss]; "portf"]
plotVarInfo[:Labels] = [["" for ii=1:nAss]; currStratName]

p = AssetMgmt.plotAssetMoments(moments,
                               Theme(default_point_size = 5px),
                               variableInfo = plotVarInfo,
                               colorCol = :Class,
                               labelCol = :Labels)

draw(SVG("pics/$currStratName-$picsCounter.svg", 15cm, 10cm), p)
write(outfile, imgCode(picsCounter))
picsCounter += 1

###################
## dev copy code ##
###################

## p = AssetMgmt.plotAssetMoments(mod, Theme(default_point_size = 5px))
## draw(SVG("pics/$currStratName-$picsCounter.svg", 15cm, 10cm), p)

###################
## plot turnover ##
###################

turnoverHeader = """<h2 id="turnover">Turnover</h2>

"""
write(outfile, turnoverHeader)
write(outfile, "\n")

turnoverParagraph = """<p>Some plots to analyse portfolio rebalancing:</p>

"""
write(outfile, turnoverParagraph)


function plotTov(tm::Timematr, args...)
    if size(tm, 2) > 1
        error("Turnover plot only defined for single time series")
    end
    ## get dates
    dats = dat2num(tm)
    ## get values
    vals = asArr(tm, Float64, NaN)[:]
    return Gadfly.plot(x = dats, y = vals,
                       Geom.bar(),
                       args...)
end

p = plotTov(tov, Guide.xlabel("time"),
            Guide.ylabel("Turnover"))
draw(SVG("pics/$currStratName-$picsCounter.svg", 15cm, 10cm), p)
write(outfile, imgCode(picsCounter))
picsCounter += 1


#######################
## plot trading days ##
#######################

tradInds = AssetMgmt.isTradingDay(invs, discRetsData)

tradDays = Timematr(tradInds*1., [:TradingDay], idx(invs))

p = plotTov(tradDays, Guide.xlabel("time"),
            Guide.ylabel("Trading Day"))
draw(SVG("pics/$currStratName-$picsCounter.svg", 15cm, 10cm), p)
write(outfile, imgCode(picsCounter))
picsCounter += 1


## TODO:
## - intended turnover

##################
## moments plot ##
##################

## - kernel density
## - 

htmlEnd = """</body></html>"""
write(outfile, htmlEnd)

close(outfile)

end
