invsToAnalyze = "data/emp_gmvWgts.csv"
strategyName = :emp_gmvWgts

## load general data and packages
include("/home/chris/research/AssetMgmtAnalysis/src/setup.jl")
include("/home/chris/.julia/v0.3/AssetMgmt/src/AssetMgmt.jl")

## loaded variables:
## assetsInSector                Dict{Any,Any}
## discRet                       Timematr{Date{ISOCalendar}}
## intRates                      Timematr{Date{ISOCalendar}}
## logRet                        Timematr{Date{ISOCalendar}}
## nAss                          Int64
## nObs                          Int64
## sectDict                      Dict{Any,Any}
## sectorsStr                    348x2 DataFrame

## load current weights to be analyzed
invs = AssetMgmt.readInvestments(invsToAnalyze)

## shorten return data to dates with actual portfolio
nObsWgts = size(invs, 1)
discRetShort = discRet[(end-nObsWgts+1):end, :] # TODO: once findin
                                        # works for dates, index
                                        # entries through common dates 

## using Datetime
## a = [date(1995, 05, ii) for ii=1:11]
## b = [date(1995, 05, ii) for ii=5:31]
## findin(a, b)

## apply filter
fltInvs = AssetMgmt.regularRB(invs, discRetShort, freq=30)
pfRet = AssetMgmt.invRet(fltInvs, discRetShort, name=strategyName) 

##############################
## get benchmark portfolios ##
##############################

## get equally weighted portfolio wgts
eqWgtInvs = AssetMgmt.equWgtInvestments(discRetShort)
randInvs1 = AssetMgmt.randInvestments(discRetShort)
randInvs2 = AssetMgmt.randInvestments(discRetShort)

## get associated portfolio returns
eqWgtRet = AssetMgmt.invRet(eqWgtInvs, discRetShort,
                            name=:equallyWeighted); 
randRet1 = AssetMgmt.invRet(randInvs1, discRetShort, name=:randPort1)
randRet2 = AssetMgmt.invRet(randInvs2, discRetShort, name=:randPort2)


##################################
## plot price and return series ##
##################################

BMs = (eqWgtRet, randRet1, randRet2)
priceRetPlot = AssetMgmt.plotPriceReturnSeries(pfRet, discRetShort, 
                                               BMs...,
                                               strName = strategyName)

################################################
## plot turnover, diversification and sectors ##
################################################

AssetMgmt.plotTOverDiversification(invs,
                                   fltInvs,
                                   discRetShort,
                                   strName = strategyName)

######################################################
## plot return distribution and mu-sigma comparison ##
######################################################

AssetMgmt.plotPfDistribution(pfRet,
                             discRetShort,
                             BMs...,
                             strName = strategyName)

#########################
## sector performances ##
#########################

AssetMgmt.plotSectorAnalysis(fltInvs,
                             discRetShort,
                             assetsInSector,
                             strName = strategyName)


