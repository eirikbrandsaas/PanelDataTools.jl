# One lag (basic building block of all code)
function lag!(df,PID::Symbol,TID::Symbol,var::Symbol,n=oneunit(df[1, TID]-df[1, TID]);name="L$n"*String(var))
    if name=="L$n"*String(var) # Only do it passed default name
        name = prettyname(name,df[1, TID],n,var,"L")
    end
    panellag!(df,PID,TID,var,name,n)
    return nothing
end

function lag!(df,var::Symbol,n=metadata(df,"Delta");name="L$n"*String(var))
    _assert_panel(df)
    panellag!(df,metadata(df,"PID"),metadata(df,"TID"),var,name,n)
end

# Lag many columns
function lag!(df,PID::Symbol,TID::Symbol,vars::Vector{Symbol},n=oneunit(df[1, TID]))
    for var in vars
        lag!(df,PID,TID,var,name="L$n"*String(var),n)
    end
    return nothing
end

function lag!(df,vars::Vector{Symbol},n=metadata(df,"Delta"))
    _assert_panel(df)
    lag!(df,metadata(df,"PID"),metadata(df,"TID"),vars,n)
end

# Lag one column many times
function lag!(df,PID::Symbol,TID::Symbol,var::Symbol,ns::Vector)
    for n in ns[ns.>0]
        lag!(df,PID,TID,var,n)
    end
    for n in ns[ns.<0]
        lead!(df,PID,TID,var,-n)
    end
    return nothing
end

function lag!(df,var::Symbol,ns::Vector)
    _assert_panel(df)
    lag!(df,metadata(df,"PID"),metadata(df,"TID"),var,ns)
end

## Leads. Call lags when feasible
# Lead one
function lead!(df,PID::Symbol,TID::Symbol,var::Symbol,n=oneunit(df[1, TID]);name="F$n"*String(var))
    if name=="F$n"*String(var)
        name = prettyname(name,df[1, TID],n,var,"F")
    end
    panellead!(df,PID,TID,var,name,n)
    return nothing
end

function lead!(df,var::Symbol,n=metadata(df,"Delta");name="F$n"*String(var))
    _assert_panel(df)
    panellead!(df,metadata(df,"PID"),metadata(df,"TID"),var,name,n)
end

# Many column leads
function lead!(df,PID::Symbol,TID::Symbol,vars::Vector{Symbol},n=oneunit(df[1, TID]))
    for var in vars
        lead!(df,PID,TID,var,name="F$n"*String(var),n)
    end
    return nothing
end

function lead!(df,vars::Vector{Symbol},n=metadata(df,"Delta"))
    _assert_panel(df)
    lead!(df,metadata(df,"PID"),metadata(df,"TID"),vars,n)
end

# many values
function lead!(df,PID::Symbol,TID::Symbol,var::Symbol,ns::Vector)
    lag!(df,PID,TID,var,-ns)
    return nothing
end

function lead!(df,var::Symbol,ns::Vector)
    _assert_panel(df)
    lag!(df,var,-ns)
end
