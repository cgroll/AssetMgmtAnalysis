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

## define estimator
estimatorType = AssetMgmt.ExpWeighted

## define (initial) strategy
strat = AssetMgmt.MinSigma(0.0015)

invs, pfMoments =
    AssetMgmt.applyStrategy(strat, estimatorType, discRetsData)
    

##########################################
## visualize expected portfolio moments ##
##########################################

p = gdfPlot(pfMoments);
draw(SVG("dev_pics/expectedMoment.svg", 15cm, 10cm), p)

## get scaled moments
scaledPfMoments = deepcopy(pfMoments)
for ii=1:size(scaledPfMoments, 1)
    currMu = get(scaledPfMoments, ii, 1)
    currSigma = get(scaledPfMoments, ii, 2)
    if !isna(currMu)
        scaledMu, scaledSigma =
            AssetMgmt.defaultMuSigmaScaling(currMu, currSigma)
        scaledPfMoments[ii, 1] = scaledMu
        scaledPfMoments[ii, 2] = scaledSigma
    end
end

p = gdfPlot(scaledPfMoments);
draw(SVG("dev_pics/expectedMoment_scaled.svg", 15cm, 10cm), p)


###################################################################
## plot portfolio moments for all portfolios with given universe ##
###################################################################

p = AssetMgmt.plotPfsAndUniverse(mod, asArr(invs));
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
validDates = idx(scaledPfMoments) .<= relevantDate
pfMomentsSingleDay = scaledPfMoments[validDates, :][end, :]

scaledPfMu = get(pfMomentsSingleDay, 1, 1)
scaledPfSigma = get(pfMomentsSingleDay, 1, 2)

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

####################
## apply strategy ##
####################

## define estimator
estimatorType = AssetMgmt.ExpWeighted

## define (initial) strategy
strat = AssetMgmt.MinSigma(0.0015)

invs, pfMoments =
    AssetMgmt.applyStrategy(strat, estimatorType, discRetsData)



