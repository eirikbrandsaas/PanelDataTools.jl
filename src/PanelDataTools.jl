module PanelDataTools

# Write your package code here.
using DataFrames
using ShiftedArrays
using PanelShift
using Dates


## Spell analysis
function spell!(df,PID::Symbol,TID::Symbol,var::Symbol)
    for var in ["_end", "_seq", "_spell"]
        if "$var" ∈ Set(names(df))
            throw(ArgumentError("$var already exists"))
        end
    end

    @assert any(ismissing.(df[!,TID]))==false "Currently does not support missing time observations"
    gdf = groupby(df,PID)
    T = [nrow(gdf[i]) for i = 1:gdf.ngroups]

    L1var = Symbol("L1"*String(var))
    lag!(df,PID,TID,var)

    df._spell = fill(1,nrow(df))
    df._seq = fill(1,nrow(df))

     # Find spells and sequence
     for i = 1:gdf.ngroups # Just loop over each sub-dataframe:
        for t = 2:T[i]
            if isequal(gdf[i][t,var], gdf[i][t,L1var])
                gdf[i][t,:_spell] = gdf[i][t-1,:_spell]
                gdf[i][t,:_seq] = gdf[i][t-1,:_seq]+1
            else
                gdf[i][t,:_spell] = gdf[i][t-1,:_spell] + 1
                gdf[i][t,:_seq] = 1
            end
        end
    end

    select!(df, Not(L1var))


    return nothing
end

function spell!(df,var::Symbol)
    PID = metadata(df,"PID")
    TID = metadata(df,"TID")
    spell!(df,PID,TID,var)
end

## Lags
function lag!(df,PID::Symbol,TID::Symbol,var::Symbol,n=oneunit(df[1, TID]-df[1, TID]);name="L$n"*String(var))
    if name=="L$n"*String(var) # Only do it passed default name
        name = prettyname(name,df[1, TID],n,var,"L")
    end
    panellag!(df,PID,TID,var,name,n)
    return nothing
end

function lag!(df,var::Symbol,n=metadata(df,"Delta");name="L$n"*String(var))
    PID = metadata(df,"PID")
    TID = metadata(df,"TID")

    if name=="L$n"*String(var) # Only do it passed default name
        name = prettyname(name,df[1, TID],n,var,"L")
    end
    panellag!(df,PID,TID,var,name,n)
    return nothing
end

function lag!(df,PID::Symbol,TID::Symbol,vars::Vector{Symbol},n=oneunit(df[1, TID]))
    for var in vars
        lag!(df,PID,TID,var,name="L$n"*String(var),n)
    end
    return nothing
end

function lag!(df,PID::Symbol,TID::Symbol,var::Symbol,ns::Vector)
    for n in ns[ns.>0]
        lag!(df,PID,TID,var,n)
    end
    for n in ns[ns.<0]
        lead!(df,PID,TID,var,-n)
    end
    return nothing
end

## Leads. Call lags when feasible
function lead!(df,PID::Symbol,TID::Symbol,var::Symbol,n=oneunit(df[1, TID]);name="F$n"*String(var))
    if name=="F$n"*String(var)
        name = prettyname(name,df[1, TID],n,var,"F")
    end
    panellead!(df,PID,TID,var,name,n)
    return nothing
end

function lead!(df,PID::Symbol,TID::Symbol,vars::Vector{Symbol},n=oneunit(df[1, TID]))
    for var in vars
        lead!(df,PID,TID,var,name="F$n"*String(var),n)
    end
    return nothing
end

function lead!(df,PID::Symbol,TID::Symbol,var::Symbol,ns::Vector)
    lag!(df,PID,TID,var,-ns)
    return nothing
end

## Seasonal Diffs.
function seasdiff!(df,PID::Symbol,TID::Symbol,var::Symbol,n=oneunit(df[1, TID]);name = "S$n"*String(var))
    @assert n>0 "n (time shift) must be positive"

    lag!(df,PID,TID,var,n;name=name)
    df[!,name] = df[!,var] - df[!,name]
    return nothing
end

function seasdiff!(df,PID::Symbol,TID::Symbol,var::Symbol,ns::Vector)
    for n in ns
        seasdiff!(df,PID,TID,var,n)
    end
    return nothing
end

## Diffs.
function diff!(df,PID::Symbol,TID::Symbol,var::Symbol,n=oneunit(df[1, TID]);name = "D$n"*String(var))
    @assert n>0 "n (time shift) must be positive"
    if n == 1
        lag!(df,PID,TID,var,n;name=name)
        df[!,name] = df[!,var] - df[!,name]
    elseif n > 1
        tmp_name = "___tmpD$n" # Need a temporary variable
        @assert (tmp_name ∈ names(df)) == false "Variable $(tmp_name) already exists"

        diff!(df,PID,TID,var,n-1;name=tmp_name)
        lag!(df,PID,TID,Symbol(tmp_name),1;name=name)

        df[!,name] = df[!,tmp_name]-df[!,name]
        select!(df,Not(tmp_name))
    end
    return nothing
end

##
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

## Metadata
"""
    paneldf!(df,PID::Symbol,TID:Symbol)

Attaches `:PID` and `:TID` to `df` so that one doesn't have to pass those all the times.

# Examples
```julia-repl
display(write this)
```
"""
function paneldf!(df,PID::Symbol,TID::Symbol)
    metadata!(df, "PID", PID, style=:note)
    metadata!(df, "TID", TID, style=:note)
    metadata!(df, "Delta", oneunit(df[1,TID]-df[1, TID]),style=:note)

    println("panel variable: "*String(metadata(df,"PID")))
    println(" time variable: "*String(metadata(df,"TID")))
    println("         delta: "*string(metadata(df,"Delta")))
end

## Utilities
function prettyname(name,t,n,var,prefix)
    if isa(t,TimeType)==true
        name=prefix*"$(n.value)"*String(var)
    end
    return name
end


export spell!, lead!, lag!, seasdiff!, diff!
export tsfill
export paneldf!
end
