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

## load and process data
include("dev/prepareData.jl")

## puts the following variables into workspace
## - priceData
## - assetInfo
## - discRetsData

nObs, nAss = size(priceData)

#####################################
## write mu-sigma universe to file ##
#####################################

include(joinpath(homedir(),
                 "research/julia/AssetMgmt/test/createTestData.jl"))

## scacapE6Names and mus20011202 and covMatr20011202 

mod = AssetMgmt.SampleMoments(mus20011202, covMatr20011202, scacapE6Names)

## get moments directly
nPfs = 50
effMus, effSigmas = AssetMgmt.getEffFrontier(mod, nPoints = nPfs)

## get efficient portfolio weights
xEff = AssetMgmt.getEffPortfolios(mod, nPoints = nPfs)

## calculate moments

effMus2 = zeros(nPfs)
effSigmas2 = zeros(nPfs)
for ii=1:nPfs
    effMus2[ii] = AssetMgmt.getPMean(xEff[ii, :][:], mod.mu)
    effSigmas2[ii] =
        sqrt(AssetMgmt.getPVar(xEff[ii, :][:], mod.sigma))
end

## test equality
@test_approx_eq_eps effMus effMus2 1e-14
@test_approx_eq_eps effSigmas effSigmas2 1e-14


###############################
## test efficient portfolios ##
###############################

mod = AssetMgmt.fitModel(AssetMgmt.SampleMoments,
                         discRetsData, Date(2001,12,2))

muTarget = 0.003

wgts = AssetMgmt.getEffPfGivenMu(mod, muTarget)

## get portfolio moments
AssetMgmt.getPMean(wgts, mod.mu)

wgts = AssetMgmt.getEffPortfolios(mod)

###############################
## estimate universeEstimate ##
###############################

univ = AssetMgmt.estimate(AssetMgmt.SampleMoments,
                          discRetsData, Date(2001,12,2))

p = AssetMgmt.plotEff(univ.Universe);
draw(SVG("dev_pics/effFront.svg", 15cm, 10cm), p)


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



################
## unit tests ##
################

## run tests
include(joinpath(homedir(), "research/julia/AssetMgmt/test/runtests.jl"))

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

##############
## plotting ##
##############

p = AssetMgmt.plotAssetMoments(mod, legendName = "AssetLabel");
p = AssetMgmt.plotAssetMoments(mod);

p = AssetMgmt.plotAssetMoments(mod, assetInfo;
                               colCol = :RiskClass)
draw(PDF("pics/universePlot.pdf", 15cm, 10cm), p)





kk = getTimeVaryingMoments(AssetMgmt.SampleMoments, aggrDiscRetsData)

loadPlotting()

p = gdfPlot(kk[1]);
draw(PDF("pics/mus_overTime.pdf", 15cm, 10cm), p)

p = gdfPlot(kk[2]);
draw(PDF("pics/sigmas_overTime.pdf", 15cm, 10cm), p)

p = gdfPlot(kk[3]);
draw(PDF("pics/corrs_overTime.pdf", 15cm, 10cm), p)


#######################
## test optimizeWgts ##
#######################

gmv = AssetMgmt.GMVSS()

xGMV = AssetMgmt.optimizeWgts(uFit, gmv)



col = :AssetClass
colName = "Asset class"

draw(PDF("pics/universePlot.pdf", 15cm, 10cm), p)


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
