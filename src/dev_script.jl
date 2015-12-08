## load some required packages
using TimeData
using DataFrames
using Econometrics
using Base.Test
using Dates

#####################################
## load parts of AssetMgmt package ##
#####################################

include(joinpath(homedir(),
                 "research/julia/AssetMgmt/src/universeModels.jl"))
include(joinpath(homedir(),
                 "research/julia/AssetMgmt/src/universeEstimate.jl"))
include(joinpath(homedir(),
                 "research/julia/AssetMgmt/src/initialStrategies.jl"))
include(joinpath(homedir(),
                 "research/julia/AssetMgmt/src/strategies.jl"))

## include(joinpath(homedir(),
                 ## "research/julia/AssetMgmt/src/estimation.jl"))


## load asset management package
include(joinpath(homedir(), "research/julia/AssetMgmt/src/AssetMgmt.jl"))

## load and process data
include("src/prepareData.jl")

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

#######################
## test optimizeWgts ##
#######################

gmv = AssetMgmt.GMVSS()

xGMV = AssetMgmt.optimizeWgts(uFit, gmv)


#################################
## visualize mu-sigma universe ##
#################################

annualFactor = 52
mus = ((1 + mod.mu).^annualFactor - 1)*100
diagSigmas = Float64[mod.sigma[ii, ii] for ii=1:nAss]
sigmas = diagSigmas*sqrt(annualFactor)*100

## define function symbol to string and vice versa
## define function to annualize mus and sigmas
nams = UTF8String[string(xx) for xx in mod.names]
momentsTable = DataFrame(AssetLabel = nams, mu = mus, sigma = sigmas)

momentsTableExt = join(momentsTable, assetInfo, on = :AssetLabel)

p = plot(momentsTableExt, x="sigma", y="mu", color="AssetClass", Geom.point);

draw(PDF("pics/universePlot.pdf", 15cm, 15cm), p)


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
