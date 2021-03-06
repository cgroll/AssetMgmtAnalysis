function prepareData(relPath::String)
    
    ## load scacap data
    priceDataRaw = readTimedata("$relPath/scacap_universeE6.csv")
    assetInfoRaw = readtable("$relPath/scacap_E6AssetInfo.csv")

    ## remove MIMUJPNN (DE000A0YBR53)
    ##-------------------------------
    
    tobeRemovedName = "eqJp_MIMUJPNN_Index"
    
    ## remove from asset info:
    dontRemove = assetInfoRaw[:, :AssetLabel] .!= tobeRemovedName
    assetInfo = assetInfoRaw[dontRemove, :]
    
    ## remove from data:
    dontRemove = names(priceDataRaw) .!= symbol(tobeRemovedName)
    priceData = priceDataRaw[:, dontRemove]

    ## get short names
    ##----------------

    ## in price data
    nAss = size(priceData, 2)
    shortNames = String[string(names(priceData)[ii]) for ii=1:nAss] |>
    	x -> Symbol[split(x[ii], "_")[1] for ii=1:nAss]

    names!(priceData.vals, shortNames)

    ## in asset info
    for ii=1:size(assetInfo, 1)
        currLabel = assetInfo[ii, :AssetLabel]
        assetInfo[ii, :AssetLabel] = split(currLabel, "_")[1]
    end

    ## define risk mapping
    ##--------------------
    
    riskClassMapping = Dict([("cash", 1.), ("covered bonds", 2), 
                             ("government bonds", 3), ("corporate bonds", 4),
                             ("commodities", 7), ("real estate", 6), ("equities", 5)])
    
    ## add risk mapping to asset info table
    nRows = size(assetInfo, 1)
    riskClasses = zeros(Float64, nRows)
    for ii=1:nRows
        thisClass = assetInfo[ii, :AssetClass]
        riskClasses[ii] = riskClassMapping[thisClass]
    end
    
    assetInfo[:RiskClass] = riskClasses
    assetInfo
    
    ## get discrete returns on aggregated basis
    ##-----------------------------------------
    
    ## define level of aggregation
    nAggrDays = 5
    
    ## get dates for aggregation
    nPrices = size(priceData, 1)
    aggrEndDates = flipud([nPrices:-nAggrDays:1][:])
    
    ## get prices at aggregated level
    aggrPriceData = priceData[aggrEndDates, :]
    
    ## calculate discrete returns
    aggrDiscRetsData = price2ret(aggrPriceData, log = false)

    return priceData, assetInfo, aggrDiscRetsData
end

