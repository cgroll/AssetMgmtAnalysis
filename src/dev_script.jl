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


###########################
## get moments over time ##
###########################

function getTimeVaryingMoments(modType::Type{AssetMgmt.SampleMoments},
                               data::Timematr)
    ## get all days
    allDats = idx(data)

    ## preallocation
    nObs, nAss = size(data)
    musOverTime = DataArray(Float64, nObs, nAss)
    sigmasOverTime = DataArray(Float64, nObs, nAss)
    nCovs = int((nAss)*(nAss-1)/2)
    corrOverTime = DataArray(Float64, nObs, nCovs)

    for ii=1:length(allDats)
        thisDat = allDats[ii]
    
        ## estimate moments
        mod = AssetMgmt.fitModel(modType, data, thisDat)

        ## extract mus and sigmas
        if AssetMgmt.isDef(mod)
            musOverTime[ii, :] = mod.mu'
            sigmasOverTime[ii, :] =
                (Float64[sqrt(mod.sigma[jj, jj]) for jj=1:nAss])'

            ## get correlation matrix
            d = diagm(1./sqrt(diag(mod.sigma)))
            corrMatr = d*mod.sigma*d

            ## extract correlations
            corrs = vcat([corrMatr[(jj+1:end), jj] for jj=1:(nAss-1)]...)
            corrOverTime[ii, :] = corrs'
        end
    end

    ## transform to Timenum
    dfMus = DataFrame()
    dfSigmas = DataFrame()
    for ii=1:nAss
        thisNam = names(data)[ii]
        dfMus[thisNam] = musOverTime[:, ii]
        dfSigmas[thisNam] = sigmasOverTime[:, ii]
    end

    dfCorrs = DataFrame()
    for ii=1:size(corrOverTime, 2)
        dfCorrs[ii] = corrOverTime[:, ii]
    end
    
    musOverTimeTd = Timenum(dfMus, idx(data))
    sigmasOverTimeTd = Timenum(dfSigmas, idx(data))
    corrOverTimeTd = Timenum(dfCorrs, idx(data))
    return (musOverTimeTd, sigmasOverTimeTd, corrOverTimeTd)
end

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
