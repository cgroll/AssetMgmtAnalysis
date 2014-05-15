#############################################
## get returns, sectors and interest rates ##
#############################################

include("/home/chris/research/julia/EconDatasets/src/EconDatasets.jl")
logRet = EconDatasets.dataset("SP500")
sectorsStr = EconDatasets.dataset("Sectors")
intRates = EconDatasets.dataset("FEDrate")

#########################
## process return data ##
#########################

## transform to discrete non-percentage returns
discRet = exp(logRet/100).-1

#########################
## process sector data ##
#########################

(nObs, nAss) = size(discRet)

## transform sector entries into symbols
sectDict = {symbol(sectorsStr[ii, 1]) =>
            symbol(sectorsStr[ii, 2]) for ii=1:nAss} 

## invert sector dictionary
assetsInSector = AssetMgmt.invertDict(sectDict)
