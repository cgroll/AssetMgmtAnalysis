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

#######################
## strategy analysis ##
#######################

## the script shall conduct a thorough analysis for a given strategy.

#####################
## define strategy ##
#####################

## define estimator
estimatorType = AssetMgmt.ExpWeighted

## define (initial) strategy
strat = AssetMgmt.MinSigma(0.0015)

###############
## load data ##
###############

## load and process data
include("dev/prepareData.jl")

## puts the following variables into workspace
## - priceData
## - assetInfo
## - discRetsData

nObs, nAss = size(discRetsData)

###############################
## apply estimator over time ##
###############################

musOverTime, sigmasOverTime, corrOverTime =
    AssetMgmt.applyMuSigmaModelEstimator(estimatorType,
                                         discRetsData)

## visualize moments over time
p = gdfPlot(musOverTime);
draw(SVG("dev_pics/mus_overTime.svg", 15cm, 10cm), p)

p = gdfPlot(sigmasOverTime);
draw(SVG("dev_pics/sigmas_overTime.svg", 15cm, 10cm), p)

p = gdfPlot(corrOverTime);
draw(SVG("dev_pics/corrs_overTime.svg", 15cm, 10cm), p)

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
draw(SVG("dev_pics/muRange_overTime.svg", 15cm, 10cm), p)

p = gdfPlot(sigmaRange);
draw(SVG("dev_pics/sigmaRange_overTime.svg", 15cm, 10cm), p)

#######################################
## visualize universe for given date ##
#######################################

relevantDate = Date(2014, 5, 3)

## estimate model again
mod = AssetMgmt.fitModel(estimatorType, discRetsData, relevantDate)

## visualize model
p = AssetMgmt.plotAssetMoments(mod);
draw(SVG("dev_pics/singleUniverse.svg", 15cm, 10cm), p)

## together with efficient frontier
##---------------------------------

p = AssetMgmt.plotEff(mod);
draw(SVG("dev_pics/singleUniverse_effFront.svg", 15cm, 10cm), p)

####################
## apply strategy ##
####################

allWgts, pfMoments = applyStrategy(strat, estimatorType, discRetsData)

allWgtsData =
    composeDataFrameMissingVals(allWgts, names(discRetsData)) |>
    x -> Timenum(x, idx(discRetsData))

pfMomentsData =
    composeDataFrameMissingVals(pfMoments, [:mu, :sigma]) |>
    x -> Timenum(x, idx(discRetsData))

#######################
## visualize weights ##
#######################

p = gdfPlot(allWgtsData);
draw(SVG("dev_pics/weightsOverTime.svg", 15cm, 10cm), p)

## get real wgts without NAs
noNAinds = asArr(allWgtsData[:, 1], Float64, NaN) |>
	x -> !isnan(x[:, 1])
realWgts = allWgtsData[noNAinds, :]

## get number of weights
nWgts = size(realWgts, 1)

## with continuous colors
##-----------------------

## create x, y and color vectors
xVals = repmat([1:nWgts]', nAss, 1)[:]
yVals = (asArr(realWgts, Float64)')[:]
colVals = repmat([1:nAss], nWgts, 1)[:]

df = DataFrame(x = xVals, y = yVals, color = colVals)

## plot only positive weights
posWgts = df[df[:y] .> 0, :]
negWgts = df[df[:y] .< 0, :]

pPos = plot(posWgts, x="x", y="y", color="color",
            Geom.bar(position=:stack));

pNeg = plot(negWgts, x="x", y="y", color="color",
            Geom.bar(position=:stack));
draw(SVG("dev_pics/weightsOverTimeStacked1.svg", 15cm, 10cm),
            vstack(pPos, pNeg))

## with usual asset colors
##------------------------

colVals = repmat(names(realWgts), nWgts, 1)[:]

df = DataFrame(x = xVals, y = yVals, color = colVals)

## plot only positive weights
posWgts = df[df[:y] .> 0, :]
negWgts = df[df[:y] .< 0, :]

pPos = plot(posWgts, x="x", y="y", color="color",
            Geom.bar(position=:stack));

pNeg = plot(negWgts, x="x", y="y", color="color",
            Geom.bar(position=:stack));
draw(SVG("dev_pics/weightsOverTimeStacked2.svg", 30cm, 30cm),
            vstack(pPos, pNeg))

##########################################
## visualize expected portfolio moments ##
##########################################

p = gdfPlot(pfMomentsData);
draw(SVG("dev_pics/expectedMoment.svg", 15cm, 10cm), p)

## get scaled moments
scaledPfMomentsData = deepcopy(pfMomentsData)
for ii=1:size(scaledPfMomentsData, 1)
    currMu = get(scaledPfMomentsData, ii, 1)
    currSigma = get(scaledPfMomentsData, ii, 2)
    if !isna(currMu)
        scaledMu, scaledSigma =
            AssetMgmt.defaultMuSigmaScaling(currMu, currSigma)
        scaledPfMomentsData[ii, 1] = scaledMu
        scaledPfMomentsData[ii, 2] = scaledSigma
    end
end

p = gdfPlot(scaledPfMomentsData);
draw(SVG("dev_pics/expectedMoment_scaled.svg", 15cm, 10cm), p)


###################################################################
## plot portfolio moments for all portfolios with given universe ##
###################################################################

p = AssetMgmt.plotPfsAndUniverse(mod, allWgts[!isnan(allWgts[:, 1]), :]);
draw(SVG("dev_pics/singleUniverse_allPfs.svg", 15cm, 10cm), p)


###################################################
## compared with universe and efficient frontier ##
###################################################

relevantDate = Date(2014, 5, 4)

## get efficient frontier moments
muEff, sigmaEff = AssetMgmt.getEffFrontier(mod)
scaledMuEff, scaledSigmaEff =
    AssetMgmt.defaultMuSigmaScaling(muEff, sigmaEff)

## get asset moments
muAss = mod.mu
sigmaAss = AssetMgmt.getVolas(mod)
scaledMuAss, scaledSigmaAss =
    AssetMgmt.defaultMuSigmaScaling(muAss, sigmaAss)

## get portfolio moments
validDates = idx(scaledPfMomentsData) .<= relevantDate
pfMoments = scaledPfMomentsData[validDates, :][end, :]

scaledPfMu = get(pfMoments, 1, 1)
scaledPfSigma = get(pfMoments, 1, 2)

p = plot(layer(x=scaledSigmaEff, y=scaledMuEff, Geom.line),
         layer(x=scaledSigmaAss, y=scaledMuAss, Geom.point),
         layer(x=[scaledPfSigma], y=[scaledPfMu], color=[2.], Geom.point));

draw(SVG("dev_pics/portfolio_and_universe.svg", 15cm, 10cm), p)


######################
## weights analysis ##
######################

## - diversification
## - turnover
## - portfolio moments together with universe at given day

#################
## investments ##
#################

df = composeDataFrameMissingVals(allWgts, names(discRetsData))
inv = AssetMgmt.Investments(df, idx(discRetsData))
