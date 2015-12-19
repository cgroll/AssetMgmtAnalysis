## load some required packages
using TimeData
using DataFrames
using Econometrics
using Base.Test
using Dates
using AssetMgmt
using Gadfly

loadPlotting()

## load asset management package
## include(joinpath(homedir(),
                 ## "research/julia/AssetMgmt/src/AssetMgmt.jl"))


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

##############
## plotting ##
##############

## plot raw data
p = gdfPlot(priceData);
draw(SVG("pics/scacap_descriptive_pics-1.svg", 25cm, 15cm), p)

## calculate normed log prices
##----------------------------

# prices without metadata
prices = asArr(priceData, Float64, NaN)

# cumulate log returns
logPrices = log(prices)
logRets = logPrices[2:end, :] - logPrices[1:end-1, :]
normedLogPrices = [zeros(1, nAss); cumsum(logRets, 1)]

# add metadata again
normedLogPriceData = Timematr(normedLogPrices, names(priceData), idx(priceData))

## calculate normed discrete returns
##----------------------------------

normedDiscRetsData = exp(normedLogPriceData) .- 1

# plot 
p = gdfPlot(normedDiscRetsData);
draw(SVG("pics/scacap_descriptive_pics-2.svg", 25cm, 15cm), p)

## plot normed log prices
##-----------------------

# plot 
p = gdfPlot(normedLogPriceData);
draw(SVG("pics/scacap_descriptive_pics-3.svg", 25cm, 15cm), p)

## plot with colorized asset class
##--------------------------------

p = AssetMgmt.gdfGroupPlot(normedLogPriceData,
                           variableInfo = assetInfo,
                           joinCol = :AssetLabel,
                           colorCol = :AssetClass,
                           legendName = "Asset class")
draw(SVG("pics/scacap_descriptive_pics-4.svg", 25cm, 15cm), p)


## plot with colorized region
##---------------------------

p = AssetMgmt.gdfGroupPlot(normedLogPriceData,
                           variableInfo = assetInfo,
                           joinCol = :AssetLabel,
                           colorCol = :Region,
                           legendName = "Region")
draw(SVG("pics/scacap_descriptive_pics-5.svg", 25cm, 15cm), p)

## plot with colorized risk class
##-------------------------------

p = AssetMgmt.gdfGroupPlot(normedLogPriceData,
                           variableInfo = assetInfo,
                           joinCol = :AssetLabel,
                           colorCol = :RiskClass,
                           legendName = "Risk class")
draw(SVG("pics/scacap_descriptive_pics-6.svg", 25cm, 15cm), p)

## plot returns
##-------------

## get daily returns
discRetData = price2ret(priceData, log = false)

p1 = gdfPlot(discRetData[:eqAs_DJAPSDET_Index]);
p2 = gdfPlot(discRetData[:govEu_LEATTREU_Index]);
draw(SVG("pics/scacap_descriptive_pics-7.svg", 25cm, 20cm),
     vstack(p1, p2))

## plot returns for each series
for ii=1:nAss
    p = gdfPlot(discRetData[:, ii]);
    draw(SVG("pics/scacap_descriptive_pics-$(ii+7).svg", 25cm, 15cm),
         p)
end
