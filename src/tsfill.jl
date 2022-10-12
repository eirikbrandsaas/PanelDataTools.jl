function tsfill(dfi,PID::Symbol,TID::Symbol,n=oneunit(df[1, TID]))
    mint = minimum(dfi[!,TID])
    maxt = maximum(dfi[!,TID])
    t = collect(mint:n:maxt)
    T = length(t)
    ids = unique(dfi[!,PID])

    df = DataFrame()
    df[!,PID] = sort!(repeat(ids,T))
    df[!,TID] = repeat(t,length(ids))
    dfi = rightjoin(dfi,df,on=[PID,TID])
    sort!(dfi,[PID,TID])


    return dfi
end

function tsfill(df,n=metadata(df,"Delta"))
   tsfill(df,metadata(df,"PID"),metadata(df,"TID"),n)
end
