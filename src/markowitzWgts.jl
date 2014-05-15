## load general data and packages
include("/home/chris/research/AssetMgmtAnalysis/src/setup.jl")
include("/home/chris/.julia/v0.3/AssetMgmt/src/AssetMgmt.jl")

########################
## specify parameters ##
########################

## choose starting point to pick subsample, maximum 4607
cutoff = 1

## choose mu-sigma-estimator and parameters
muSigmaEstimator = AssetMgmt.empiricalEstimator
minObs = 400
rollingWindow = false

## choose response strategy
responseFunc = AssetMgmt.gmv

t = Task(() -> AssetMgmt.produceMoments(discRet,
                                        muSigmaEstimator,
                                        (),
                                        minObs=minObs,
                                        rolling=rollingWindow))

############################
## get associated weights ##
############################

wgts = NaN*ones(size(discRet))
dates = rep(false, nObs)
for x in t
    (mus, covMatr, index) = x
    println(index)
    dates[index] = true
    wgts[index, :] = responseFunc(mus, covMatr)
end

wgtsDf = AssetMgmt.composeDataFrame(wgts[dates, :], names(discRet))
invs = AssetMgmt.Investments(wgtsDf, idx(discRet)[dates])

## save weights to disc
AssetMgmt.writeInvestments("data/emp_gmvWgts.csv", invs)
