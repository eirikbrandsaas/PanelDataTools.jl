function spell!(df,PID::Symbol,TID::Symbol,var::Symbol)
    for var in ["_end", "_seq", "_spell"]
        if "$var" ∈ Set(names(df))
            throw(ArgumentError("$var already exists"))
        end
    end

    @assert any(ismissing.(df[!,TID]))==false "Currently does not support missing time observations"
    gdf = groupby(df,PID)
    T = [nrow(gdf[i]) for i = 1:gdf.ngroups]

    _name = Symbol("L1"*String(var))
    lag!(df,PID,TID,var,name=_name)

    df._spell = fill(1,nrow(df))
    df._seq = fill(1,nrow(df))

     # Find spells and sequence
     for i = 1:gdf.ngroups # Just loop over each sub-dataframe:
        for t = 2:T[i]
            if isequal(gdf[i][t,var], gdf[i][t,_name])
                gdf[i][t,:_spell] = gdf[i][t-1,:_spell]
                gdf[i][t,:_seq] = gdf[i][t-1,:_seq]+1
            else
                gdf[i][t,:_spell] = gdf[i][t-1,:_spell] + 1
                gdf[i][t,:_seq] = 1
            end
        end
    end

    select!(df, Not(_name))


    return nothing
end

function spell!(df,var::Symbol)
    _assert_panel(df)
    spell!(df,metadata(df,"PID"),metadata(df,"TID"),var)
end
