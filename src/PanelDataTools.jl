module PanelDataTools

# Write your package code here.
using DataFrames
using ShiftedArrays
using PanelShift


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

## Lags (fundamental)
function lag!(df,PID::Symbol,TID::Symbol,var::Symbol,n=oneunit(df[1, TID]))
    panellag!(df,PID,TID,var,"L$n"*String(var),n)
    return nothing
end

function lag!(df,PID::Symbol,TID::Symbol,vars::Vector{Symbol},n=oneunit(df[1, TID]))
    for var in vars
        panellag!(df,PID,TID,var,"L$n"*String(var),n)
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
function lead!(df,PID::Symbol,TID::Symbol,var::Symbol,n=oneunit(df[1, TID]))
    panellead!(df,PID,TID,var,"F$n"*String(var),n)
    return nothing
end

function lead!(df,PID::Symbol,TID::Symbol,vars::Vector{Symbol},n=oneunit(df[1, TID]))
    for var in vars
        panellead!(df,PID,TID,var,"F$n"*String(var),n)
    end
    return nothing
end

function lead!(df,PID::Symbol,TID::Symbol,var::Symbol,ns::Vector)
    lag!(df,PID,TID,var,-ns)
    return nothing
end

## Seasonal Diffs.
function seasdiff!(df,PID::Symbol,TID::Symbol,var::Symbol,n=oneunit(df[1, TID]))
    @assert n>0 "n (time shift) must be positive"
    panellag!(df,PID,TID,var,"S$n"*String(var),n)
    df[!,"S$(n)"*String(var)] = df[!,var] - df[!,"S$(n)"*String(var)]
    return nothing
end

function seasdiff!(df,PID::Symbol,TID::Symbol,var::Symbol,ns::Vector)
    for n in ns
        seasdiff!(df,PID,TID,var,n)
    end
    return nothing
end

## Diffs.
function diff!(df,PID::Symbol,TID::Symbol,var::Symbol,n=oneunit(df[1, TID]))
    @assert n>0 "n (time shift) must be positive"
    @assert n<=1 "diff! currently only supports first diff"
    if n == 1
        panellag!(df,PID,TID,var,"D$n"*String(var),n)
        df[!,"D$(n)"*String(var)] = df[!,var] - df[!,"D$(n)"*String(var)]
    else
        throw("order $n differencs not supported")
    end
    return nothing
end


export spell!, lead!, lag!, seasdiff!, diff!
end
