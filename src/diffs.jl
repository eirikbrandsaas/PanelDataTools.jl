## Seasonal Diffs.
function _seasdiff!(df,PID::Symbol,TID::Symbol,var::Symbol,n=oneunit(df[1, TID]-df[1, TID]);name = "S$n"*String(var))
    @assert n>zero(n) "n (time shift) must be positive"

    lag!(df,PID,TID,var,n;name=name)
    df[!,name] = df[!,var] - df[!,name]
    return nothing
end

function seasdiff!(df,var::Symbol,n=metadata(df,"Delta");name = "S$n"*String(var))
    _assert_panel(df)
    _seasdiff!(df,metadata(df,"PID"),metadata(df,"TID"),var,n;name=name)
end

function _seasdiff!(df,PID::Symbol,TID::Symbol,var::Symbol,ns::Vector)
    for n in ns
        _seasdiff!(df,PID,TID,var,n)
    end
    return nothing
end

function seasdiff!(df,var::Symbol,ns::Vector)
    _assert_panel(df)
    _seasdiff!(df,metadata(df,"PID"),metadata(df,"TID"),var,ns)
end


## Diffs.
function diff!(df,PID::Symbol,TID::Symbol,var::Symbol,n=oneunit(df[1, TID]);name = "D$n"*String(var))
    @assert n > zero(n) "n (time shift) must be positive"
    if n == oneunit(df[1, TID])
        lag!(df,PID,TID,var,n;name=name)
        df[!,name] = df[!,var] - df[!,name]
    else
        tmp_name = "___tmpD$n" # Need a temporary variable
        @assert (tmp_name ∈ names(df)) == false "Variable $(tmp_name) already exists"

        diff!(df,PID,TID,var,n-oneunit(df[1, TID]);name=tmp_name)
        lag!(df,PID,TID,Symbol(tmp_name),oneunit(df[1, TID]);name=name)

        df[!,name] = df[!,tmp_name]-df[!,name]
        select!(df,Not(tmp_name))
    end
    return nothing
end

function diff!(df,var::Symbol,n=metadata(df,"Delta");name = "D$n"*String(var))
    _assert_panel(df)
   diff!(df,metadata(df,"PID"),metadata(df,"TID"),var,n,name=name)
end
