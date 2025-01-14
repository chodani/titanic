module titanic

using CSV, DataFrames, MethodChains, Missings

export readtitanic

"""
    readtitanic(inputpath, gdptype)

Read in titanic data and return clean dataframe
"""
function readtitanic(inputpath)
    df = CSV.read(inputpath, DataFrame)
    transform!(df, [:age, :fare] .=> ByRow(num -> num == "NA" ? missing : parse(Float32, num)), renamecols = false)
    transform!(df, [:sibsp, :parch] .=> ByRow(num -> num == "NA" ? missing : parse(Int, num)), renamecols = false)
    return df
end


end # module titanic
