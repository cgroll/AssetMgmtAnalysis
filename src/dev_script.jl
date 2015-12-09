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
include(joinpath(homedir(), "research/julia/AssetMgmt/src/AssetMgmt.jl"))

## load and process data
include("src/prepareData.jl")


##########################
## gross to log moments ##
##########################

muGross = 1 + 0.0003999045704988394
sigma = sqrt(1.0075481833724383e-7)

nAss = size(mod.mu, 1)
for ii=1:nAss
    muGross = 1 + mod.mu[ii]
    sigma = sqrt(mod.sigma[ii, ii])

    ## to log moments
    muLog, sigmaLog =
        AssetMgmt.grossRetMomentsToLogRetMoments(muGross, sigma)

    display(ii)
    
    ## and back
    muGrossOut, sigmaOut =
        AssetMgmt.logRetMomentsToGrossRetMoments(muLog, sigmaLog)

    @test muGross == muGrossOut
    @test_approx_eq_eps sigma sigmaOut 1e-14
end

#######################
## scaling functions ##
#######################

muScaled = ones(nAss)
sigmaScaled = ones(nAss)
for ii=1:nAss
    muSc, sigSc =
        AssetMgmt.defaultMuSigmaScaling(mod.mu[ii], sqrt(mod.sigma[ii, ii]))
    muScaled[ii] = muSc
    sigmaScaled[ii] = sigSc
end


modScaled = AssetMgmt.SampleMoments(muScaled, diagm(sigmaScaled),
                                    names(aggrDiscRetsData))


p = AssetMgmt.plotAssetMoments(modScaled)
draw(PDF("pics/scaled_moments.pdf", 15cm, 10cm), p)


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
