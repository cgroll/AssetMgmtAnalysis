invsToAnalyze = "data/emp_gmvWgts.csv"

## load general data and packages
include("/home/chris/research/AssetMgmtAnalysis/src/setup.jl")

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

## apply filter
fltWgts = AssetMgmt.regularRB(invs, discRet, freq=30)
