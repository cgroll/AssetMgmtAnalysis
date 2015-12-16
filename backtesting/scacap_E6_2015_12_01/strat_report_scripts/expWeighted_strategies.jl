################################################################
## script should be called from backtest/scacap_E6_2015_12_01 ##
################################################################

## The script calculates investment weights for a series of
## strategies and saves each one to file.

## It also could show some properties for the estimator used, which is
## the same for all strategies in this script.

## define estimator name
estName = "expWeighted"

########################
## define output file ##
########################

fname = joinpath(pwd(), "report_output/$estName.html")
outfile = open(fname, "w")

#######################
## define html marco ##
#######################

function imgCode(picNumb)
    return """<img src="../pics/$(estName)-$(picNumb).svg" alt="Returns" width="1000px"/>
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

introParagraph = """<p>This report should give an overview over the
estimator being used.</p>

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

######################
## define estimator ##
######################

## the estimator is common to all strategies in this script
estimatorType = AssetMgmt.ExpWeighted

###############
## load data ##
###############

## load and process data
currDir = pwd()
include(joinpath(currDir, "../../dev/prepareData.jl"))

## path needs to be relative to present directory
priceData, assetInfo, discRetsData = prepareData("../../financial_data/raw_data/")

## puts the following variables into workspace
## - priceData
## - assetInfo
## - discRetsData

nObs, nAss = size(discRetsData)

picsCounter = 1

###############################
## apply estimator over time ##
###############################

tvMomentsHeader =
    """<h2 id="time-varying-moments">Time-varying moments</h2>

"""
write(outfile, tvMomentsHeader)

tvParagraph = """<p>Show estimator applied successively over time:</p>"""
write(outfile, tvParagraph)


musOverTime, sigmasOverTime, corrOverTime =
    AssetMgmt.applyMuSigmaModelEstimator(estimatorType,
                                         discRetsData)

## visualize moments over time
p = gdfPlot(musOverTime);
draw(SVG("pics/$estName-$picsCounter.svg", 15cm, 10cm), p)
write(outfile, imgCode(picsCounter))
picsCounter += 1

p = gdfPlot(sigmasOverTime);
draw(SVG("pics/$estName-$picsCounter.svg", 15cm, 10cm), p)
write(outfile, imgCode(picsCounter))
picsCounter += 1

p = gdfPlot(corrOverTime);
draw(SVG("pics/$estName-$picsCounter.svg", 15cm, 10cm), p)
write(outfile, imgCode(picsCounter))
picsCounter += 1


#####################
## mu-sigma-ranges ##
#####################

## mu-sigma ranges can be required to set some realistic values for
## target moments in Markowitz strategies.

currHeader =
    """<h2 id="mu-sigma-ranges">Mu-sigma-ranges</h2>

"""
write(outfile, currHeader)

currPara = """<p>Get highest and lowest mu and sigma estimators over time:</p>"""
write(outfile, currPara)


## show mu and sigma ranges
##-------------------------

function getRange(valsOverTime::Timematr)
    ## get the range for some values over time
    nObs = size(valsOverTime, 1)
    
    ## find minimum and maximum
    minVal = Array(Float64, nObs)
    maxVal = Array(Float64, nObs)
    valsOverTimeRaw = asArr(valsOverTime, Float64, NaN)
    for ii=1:nObs
        minVal[ii] = minimum(valsOverTimeRaw[ii, :])
        maxVal[ii] = maximum(valsOverTimeRaw[ii, :])
    end
    
    ## encapsulate in DataFrame
    df = DataFrame()
    df[:minVal] = minVal
    df[:maxVal] = maxVal

    ## encapsulate in Timenum
    valRange = Timematr(df, idx(valsOverTime))

    return valRange
end

muRange = getRange(musOverTime)
sigmaRange = getRange(sigmasOverTime)

p = gdfPlot(muRange);
draw(SVG("pics/$estName-$picsCounter.svg", 15cm, 10cm), p)
write(outfile, imgCode(picsCounter))
picsCounter += 1

p = gdfPlot(sigmaRange);
draw(SVG("pics/$estName-$picsCounter.svg", 15cm, 10cm), p)
write(outfile, imgCode(picsCounter))
picsCounter += 1

htmlEnd = """</body></html>"""
write(outfile, htmlEnd)

close(outfile)

######################
## apply strategies ##
######################

wgtsFilePath = "backtest_wgts"

## Sigma minimization with given mu value
##---------------------------------------

## no short-selling

muTarget = 0.0015

## define (initial) strategy
strat = AssetMgmt.MinSigma(muTarget)

invs, pfMoments =
    AssetMgmt.applyStrategy(strat, estimatorType, discRetsData)

## save to file
fname = "minSigma.csv"
fullname = joinpath(wgtsFilePath, fname)
AssetMgmt.writeInvestments(fullname, invs);



## Sigma minimization with given mu value and threshold TO-filter
##---------------------------------------------------------------

################################
## redefine estimator for dev ##
################################

## the estimator is common to all strategies in this script
estimatorType = AssetMgmt.ExpWeighted

## define (initial) strategy
strat = AssetMgmt.MinSigma(0.0015)


## define filter
tovFilt = AssetMgmt.ThresHoldDeviance(0.4)

## set strategy
fullStrat = AssetMgmt.SeparateTurnover(strat, tovFilt)

invs, pfMoments =
    AssetMgmt.applyStrategy(fullStrat, estimatorType, discRetsData)


## save to file
fname = "minSigmaThresFilter.csv"
fullname = joinpath(wgtsFilePath, fname)
AssetMgmt.writeInvestments(fullname, invs);
