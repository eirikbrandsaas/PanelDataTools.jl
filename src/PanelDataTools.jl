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

    @assert any(ismissing.(df.t))==false "Currently does not support missing time observations"
    gdf = groupby(df,PID)
    T = [nrow(gdf[i]) for i = 1:gdf.ngroups]
    for ig=1:gdf.ngroups
        # @assert nrow(gdf[1])==nrow(gdf[ig])
    end

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

function lead!(df,PID::Symbol,TID::Symbol,var::Symbol)
    panellead!(df,PID,TID,var,"F1"*String(var),1)
    return nothing
end

function lead!(df,PID::Symbol,TID::Symbol,var::Symbol,n)
    panellead!(df,PID,TID,var,"F$n"*String(var),n)
    return nothing
end

function lag!(df,PID::Symbol,TID::Symbol,var::Symbol)
    panellag!(df,PID,TID,var,"L1"*String(var),1)
    return nothing
end

function lag!(df,PID::Symbol,TID::Symbol,var::Symbol,n)
    panellag!(df,PID,TID,var,"L$n"*String(var),n)
    return nothing
end


export spell!, lead!, lag!
export _lag, _lead

end
