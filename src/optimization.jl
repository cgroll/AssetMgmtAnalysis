include("/home/chris/research/AssetMgmtAnalysis/src/setup.jl")

covMatr = cov(discRet)
covMatrArr = array(covMatr)

mus = mean(discRet, 1)
musArr = array(mus)


gmvWgts = AssetMgmt.gmv(musArr, covMatrArr)

## using JuMP
using Gurobi

function gmvNoSS(mus::Array{Float64, 2}, covMatr::Array{Float64, 2})
    ## numerical calculation of gmv without shortselling
    nAss = length(mus)
    env = Gurobi.Env()
    setparams!(env; IterationLimit=100, Method=1)
    minVarModel = gurobi_model(env;
                               name = "minimumVariance",
                               H = covMatr,
                               f = zeros(nAss),
                               Aeq = ones(1, nAss),
                               beq = [1.],
                               lb = zeros(nAss),
                               ub = ones(nAss))
    optimize(minVarModel)
    wgts = get_solution(minVarModel)
    return wgts'
end

wgts = gmvNoSS(musArr, covMatrArr)

