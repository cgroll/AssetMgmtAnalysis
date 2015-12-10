## load general data and packages
include("/home/chris/research/AssetMgmtAnalysis/src/setup.jl")
include("/home/chris/.julia/v0.3/AssetMgmt/src/AssetMgmt.jl")

intRatesArr = core(intRates)

responses = {"gmv" => AssetMgmt.gmv,
             "maxSR" => AssetMgmt.maxSharpeRatio,
             "gmvNoSS" => AssetMgmt.gmvNoSS}
responses = {"gmv" => AssetMgmt.gmv}

rollingAlternatives = {"RO" => true,
                       "NO" => false}

estimators = {"emp" => AssetMgmt.empiricalEstimator}

minObsAlternatives = [100, 250, 500]

## auxEstimationDataRequired = 

for muSigmaEstimator in estimators
    
    for responseFuncVals in responses
        
        for rollingWindow in rollingAlternatives
            
            for minObs in minObsAlternatives

                ###################################
                ## set up moments estimator task ##
                ###################################

                ## choose response strategy
                t = Task(() -> AssetMgmt.produceMoments(discRet,
                                                        muSigmaEstimator[2],
                                                        (),
                                                        minObs=minObs,
                                                        rolling=rollingWindow[2]))

                responseFunc = responseFuncVals[2]
                
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
                    ## wgts[index, :] = responseFunc(mus, covMatr, intRatesArr[index-1])
                end

                wgtsDf = AssetMgmt.composeDataFrame(wgts[dates, :], names(discRet))
                invs = AssetMgmt.Investments(wgtsDf, idx(discRet)[dates])

                ## save weights to disc
                wgtsName = string("data/",
                                  muSigmaEstimator[1], "_",
                                  responseFuncVals[1], "_",
                                  rollingWindow[1], "_",
                                  minObs, ".csv")

                print(wgtsName, "\n")
                                  
                AssetMgmt.writeInvestments(wgtsName, invs)
            end
        end
    end
end
