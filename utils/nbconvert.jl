########################
## test ijulia tutorials
########################

ijuliaFileNames = ["scacap_data_inspection"]

println(" Converting ijulia notebooks\n")
println("--------------------------------")
println("--------------------------------\n")

println("Warning: make sure that the following directories exist:\n")
println(" * nbconvert_html\n")
println(" * nbconvert_jl\n")

ipythonInstalled = true
try
    for f in ijuliaFileNames
        run(`ipython nbconvert notebooks/$(f).ipynb --to html`)
        run(`mv $(f).html nbconvert_html/$(f).html`)
        run(`ipython nbconvert notebooks/$(f).ipynb --to python`)
        run(`mv $(f).py nbconvert_jl/$(f).jl`)
    end
catch
    println("no ipython installed")
    ipythonInstalled = false
end
