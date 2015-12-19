## load some required packages
using TimeData
using DataFrames
using Econometrics
using Base.Test
using Dates

#####################################
## load parts of AssetMgmt package ##
#####################################

## load asset management package
include(joinpath(homedir(),
                 "research/julia/AssetMgmt/src/AssetMgmt.jl"))

include(joinpath(homedir(), "research/julia/AssetMgmt/src/AssetMgmt.jl"))

## load and process data
include("dev/prepareData.jl")

relPath = "../../financial_data/raw_data/"

## puts the following variables into workspace
## - priceData
## - assetInfo
## - discRetsData

nObs, nAss = size(priceData)

##########################
## filter TO strategies ##
##########################

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

inds = [1:5]
dats = idx(invs)[inds]
rets = asArr(discRetsData[dats, :], Float64)
AssetMgmt.evolWgtsCore(asArr(invs[1:5, :], Float64), rets)

currDate = idx(invs)[2]
## estimate universe
univ = AssetMgmt.estimate(estimatorType, discRetsData, currDate)

pastInvInds = idx(invs) .< currDate
invHistory = invs[pastInvInds, :]

## get evening weights
evolWgts(invHistory, discRetsData[currDate, :])
optimizeWgts(fullStrat, univ, invs)

## get turnover
tov = AssetMgmt.turnover(invs, discRetsData)

## get trading days
tradInds = AssetMgmt.isTradingDay(invs, discRetsData)

##################################################
## test evolWgts: can be taken for unit test!!! ##
##################################################

initialVol = ones(4)
initialPrices = 100*ones(4)
nextPrices = [120 140 90 80]'

## get current weights
pfValue = sum(initialVol.*initialPrices)
initialWgts = initialVol.*initialPrices ./ pfValue

## get next period weights
pfValueNext = sum(initialVol.*nextPrices)
nextWgts = initialVol.*nextPrices ./ pfValueNext

## get returns
discRets = (nextPrices - initialPrices)./initialPrices

nextWgtsWithReturns = AssetMgmt.evolWgtsCore((initialWgts[:])', (discRets[:])')

@test_approx_eq nextWgtsWithReturns nextWgts'

#########################################################
## upper lines for evolWgts can be used as unit test!! ##
#########################################################

vols = ones(4, 4)
prices = [100*ones(4)',
          [120 140 90 80],
          [130 110 100 90],
          [120 150 110 110]]
          

## calculate weights
wgts = vols.*prices./ sum(vols.*prices, 2)

## get returns
discRets = (prices[2:end, :] - prices[1:(end-1), :]) ./
	prices[1:(end-1), :]

eveningWgts = AssetMgmt.evolWgtsCore(wgts[1:3, :], discRets)

@test_approx_eq wgts[2:end, :] eveningWgts

## create investments
nams = [:bli, :bla, :blub, :blo]
dats = [Date(2010,1,3);
        Date(2010,1,4);
        Date(2010,1,5)]

dfInvs = composeDataFrame(wgts[1:3, :], nams)
testInvs = AssetMgmt.Investments(dfInvs, dats)

testRets = Timematr(discRets, nams, dats)

expTov = Timematr(zeros(Float64, 3), [:turnOver], dats)
actTov = AssetMgmt.turnover(testInvs, testRets)
@test expTov == actTov
@test AssetMgmt.isTradingDay(testInvs, testRets) == [true; false; false]


################
## SeparateTO ##
################

tovFilt = AssetMgmt.ThresHoldDeviance(0.4)
strat = AssetMgmt.MinSigma(0.0015)

sepToStrat = AssetMgmt.SeparateTurnover(strat, tovFilt)



################
## unit tests ##
################

## run tests
include(joinpath(homedir(), "research/julia/AssetMgmt/test/runtests.jl"))

###################################
## composeDataFrameMissingValues ##
###################################

function composeDataFrameMissingVals(vals::Array{Float64, 2},
                                     nams::Array{Symbol, 1})

    df = DataFrame()
    nObs, nAss = size(vals)
    for ii=1:nAss
        da = DataArray(Float64, nObs)
        for jj=1:nObs
            if !isnan(vals[jj, ii])
                da[jj] = vals[jj, ii]
            end
        end
        df[nams[ii]] = da
    end
    return df
end



##########################################
## apply estimator / strategy over time ##
##########################################

estimatorType = AssetMgmt.ExpWeighted
strat = AssetMgmt.MinSigma(0.03)

data = discRetsData

## for mu-sigma strategies also give back expected portfolio moments
## for each period

allWgts, pfMoments = applyStrategy(estimatorType, strat, data)


wgtsSums = sum(allWgts, 2)
wgtsSums = wgtsSums[!isnan(wgtsSums)]
@test_approx_eq_eps  wgtsSums ones(length(wgtsSums)) 1e-10


########################
## efficient frontier ##
########################

kk = AssetMgmt.getEffFrontier(univ)

xx = AssetMgmt.defaultMuSigmaScaling(kk[1], kk[2])

p = plot(x=xx[2], y=xx[1], Geom.point);
draw(SVG("dev_pics/effFront.svg", 15cm, 10cm), p)


#######################################
## optimize with respect to strategy ##
#######################################

strat = AssetMgmt.GMVSS()

xGMV = AssetMgmt.optimizeWgts(univ, strat)
gmvWgts = AssetMgmt.makeWeights(xGMV')

p = AssetMgmt.plotPfsAndUniverse(univ.Universe, gmvWgts)
draw(SVG("dev_pics/universeMoments.svg", 15cm, 10cm), p)



###########################
## optimize for each day ##
###########################




#####################################
## estimate and visualize universe ##
#####################################

mod = AssetMgmt.fitModel(AssetMgmt.SampleMoments,
                         aggrDiscRetsData, Date(2015,12,1))
p1 = AssetMgmt.plotAssetMoments(mod);
draw(PDF("pics/universePlot.pdf", 15cm, 10cm), p1)

p2 = AssetMgmt.plotAssetMoments(mod, assetInfo = assetInfo,
                               joinCol = :AssetLabel,
                               colorCol = :AssetClass,
                               legendName = "Asset class");
draw(PDF("pics/universePlot_classColoring.pdf", 15cm, 10cm), p2)

p3 = AssetMgmt.plotAssetMoments(mod, assetInfo = assetInfo,
                                joinCol = :AssetLabel,
                                colorCol = :Region,
                                legendName = "Region");
draw(PDF("pics/universePlot_regionColoring.pdf", 15cm, 10cm), p3)

p4 = AssetMgmt.plotAssetMoments(mod, assetInfo = assetInfo,
                               joinCol = :AssetLabel,
                               colorCol = :RiskClass,
                               legendName = "Risk class");
draw(PDF("pics/universePlot_riskColoring.pdf", 15cm, 10cm), p4)

draw(PDF("pics/universe_all_colorings.pdf", 30cm, 20cm),
     vstack(hstack(p1, p2), hstack(p3, p4)))




EMACS_STOPPER_EMACS_STOPPER_EMACS_STOPPER

######################
## type definitions ##
######################

## UniverseModel: describes the current asset setting
## - the current settings also could be described with moments only
## UniverseEstimation:
## - comprises fitted UniverseModel with information about data and
## estimation parameters used for fitting
## - estimate(SampleMoments, aggrDiscRetsData, Date(2015,12,1))
## Strategy:
## - multi-period strategy dealing with interaction of TO and Universe
## InitialStrategy:
## - defines strategy if turnover will be dealt with separately
## TOFilter: for the case of disjunct strategy / TO heuristics
## - defines heuristics to reduce turnover

## optimize: with given Universe and strategy one can optimize
## ## deposit in: no initial value
## optimize(mod::Universe, s::InitialStrategy,
##          data::Timematr)

## ## with initial investment: turnover case
## optimize(mod::Universe, s::Strategy,
##          data::Timematr, InvHistory::Investments)

## test for positive definiteness
## isposdef(A) 

########################
## test SampleMoments ##
########################

## check undefined model
mod = AssetMgmt.SampleMoments()
@test !AssetMgmt.isDef(mod)

## estimate model
mod = AssetMgmt.fitModel(AssetMgmt.SampleMoments, aggrDiscRetsData, Date(2015,12,1))

## test with too less observations
mod = AssetMgmt.fitModel(AssetMgmt.SampleMoments,
                         aggrDiscRetsData, Date(1999,3,3),
                         minObs = 30)
@test !AssetMgmt.isDef(mod)

######################
## UniverseEstimate ##
######################

mod = AssetMgmt.fitModel(AssetMgmt.SampleMoments,
                         aggrDiscRetsData, Date(2015,12,1))
uFit = AssetMgmt.MuSigmaUniverse(mod, Date(1999,3,3), aggrDiscRetsData)

## directly with single function
uFit = AssetMgmt.estimate(AssetMgmt.SampleMoments,
                          aggrDiscRetsData, Date(2015,12,1))

uFit = AssetMgmt.estimate(AssetMgmt.ExpWeighted,
                          aggrDiscRetsData, Date(2015,12,1))


## optimize single period
##-----------------------

## deposit in: no initial value
optimize(mod::Universe, s::Strategy,
         data::Timematr)

## with initial investment: turnover case
optimize(mod::Universe, s::Strategy,
         data::Timematr, InvHistory::Investments)

## optimization code could be equal for any SeparateTurnover strategy
## with MuSigmaStrategy.

## strategy
##---------

## in many cases consisting of two separate components:
## - optimal response to current universe
## - turnover heuristics


## easiest strategy:
## - Markowitz, given mu
## - can be applied to all MuSigma universe descriptions
## - has to be combined with turnover heuristics
