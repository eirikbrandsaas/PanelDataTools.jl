## Metadata
"""
    paneldf!(df,PID::Symbol,TID::Symbol; delta=oneunit(df[1,TID]-df[1,TID]), verbose=false)

Attaches `:PID` and `:TID` to `df` so that one doesn't have to pass those all the times.

`delta` sets the default time gap used by `lag!`, `diff!`, etc. when no gap is
given; it defaults to one unit of the time variable but can be overridden, e.g.
`paneldf!(df, :id, :t; delta=Year(2))`.

Pass `verbose=true` to print the inferred panel variable, time variable, and
delta along with whether the panel is balanced and has time gaps (see
[`checkpanel`](@ref)).

# Examples
```jldoctest
df = DataFrame(id = [1,1,2,2],t = [1,2,1,2],x=[0,1,1,0])
paneldf!(df,:id,:t)
lag!(df,:x) # No need to specify panel (:id) and time (:t) columns
4×4 DataFrame
 Row │ id     t      x      L1x
     │ Int64  Int64  Int64  Int64?
─────┼──────────────────────────────
   1 │     1      1      0  missing
   2 │     1      2      1        0
   3 │     2      1      1  missing
   4 │     2      2      0        1
```
"""
function paneldf!(df,PID::Symbol,TID::Symbol; delta=nothing, verbose=false)
    @assert (String(PID) in names(df)) == true String(PID)*" (panel variable) does not exist in df"
    @assert (String(TID) in names(df)) == true String(TID)*" (time variable) does not exist in df"
    # Resolve the default here (not in the signature): it reads df[1,TID], which
    # must only happen after TID is confirmed to exist.
    delta = isnothing(delta) ? oneunit(df[1,TID]-df[1, TID]) : delta
    @assert delta > zero(delta) "delta (default time gap) must be positive"

    metadata!(df, "PID", PID, style=:note)
    metadata!(df, "TID", TID, style=:note)
    metadata!(df, "Delta", delta, style=:note)

    if verbose
        println("panel variable: "*String(metadata(df,"PID")))
        println(" time variable: "*String(metadata(df,"TID")))
        println("         delta: "*string(metadata(df,"Delta")))
        checkpanel(df, PID, TID, delta) # reports structure and warns on duplicates
    end
    return nothing
end


function _assert_panel(df)
    @assert ("PID" in metadatakeys(df))==true "Table-level metadata key 'PID' does not exist. See `?paneldf!()`"
    @assert ("TID" in metadatakeys(df))==true "Table-level metadata key 'TID' does not exist. See `?paneldf!()`"
    @assert ("Delta" in metadatakeys(df))==true "Metadata field 'Delta' does not exist. See `?paneldf!()`"
end


## Small functions
function prettyname(name,t,n,var,prefix)
    if isa(t,TimeType)==true
        name=prefix*"$(n.value)"*String(var)
    end
    return name
end
