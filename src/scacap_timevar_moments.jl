## load some required packages
using TimeData
using DataFrames
using Econometrics
using Base.Test
using Dates
using Gadfly

loadPlotting()

## using AssetMgmt

## load asset management package
include(joinpath(homedir(),
                "research/julia/AssetMgmt/src/AssetMgmt.jl"))

###########################
## load and process data ##
###########################

currDir = pwd()
include(joinpath(currDir, "dev/prepareData.jl"))

## puts the following variables into workspace
## - priceData
## - assetInfo
## - discRetsData

nObs, nAss = size(priceData)

###############################
## specify default estimator ##
###############################

defaultEstimators = [AssetMgmt.SampleMoments,
                     AssetMgmt.MovWinSampleMoments,
                     AssetMgmt.ExpWeighted]

nPics = 3
for ii=1:length(defaultEstimators)

    outp = AssetMgmt.getTimeVaryingMoments(defaultEstimators[ii],
                                         discRetsData)

    musOverTimeTd, sigmasOverTimeTd, corrOverTimeTd = outp

    p = gdfPlot(musOverTimeTd);
    draw(SVG("pics/scacap_timevar_moments-$((ii-1)*nPics+1).svg", 25cm, 15cm), p)

    p = gdfPlot(sigmasOverTimeTd);
    draw(SVG("pics/scacap_timevar_moments-$((ii-1)*nPics+2).svg", 25cm, 15cm), p)

    p = gdfPlot(corrOverTimeTd);
    draw(SVG("pics/scacap_timevar_moments-$(ii*nPics).svg", 25cm, 15cm), p)

end
