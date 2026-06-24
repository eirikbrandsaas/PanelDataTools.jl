## Panel structure checks

# Strongly balanced: every id is observed at the same set of time points.
function isbalanced(df,PID::Symbol,TID::Symbol)
    g = groupby(df,PID)
    ref = sort(g[1][!,TID])
    return all(sort(sub[!,TID]) == ref for sub in g)
end

function isbalanced(df)
    _assert_panel(df)
    isbalanced(df,metadata(df,"PID"),metadata(df,"TID"))
end

# Gaps: any id whose consecutive (sorted, unique) time points are not exactly one
# `delta` apart. Checking successive differences avoids materializing the full
# min:delta:max grid, which can be astronomically large (e.g. milliseconds over
# years).
function hasgaps(df,PID::Symbol,TID::Symbol,delta=oneunit(df[1,TID]-df[1, TID]))
    for sub in groupby(df,PID)
        t = sort(unique(sub[!,TID]))
        if any(d -> d != delta, diff(t))
            return true
        end
    end
    return false
end

function hasgaps(df)
    _assert_panel(df)
    hasgaps(df,metadata(df,"PID"),metadata(df,"TID"),metadata(df,"Delta"))
end

# Duplicate (id,t) pairs break the panel structure (lags/diffs/spells become
# unreliable), so they are always worth flagging.
function hasduplicates(df,PID::Symbol,TID::Symbol)
    return nrow(unique(df,[PID,TID])) != nrow(df)
end

function hasduplicates(df)
    _assert_panel(df)
    hasduplicates(df,metadata(df,"PID"),metadata(df,"TID"))
end

"""
    checkpanel(df,PID::Symbol,TID::Symbol,delta=oneunit(df[1,TID]-df[1,TID]))
    checkpanel(df)

Report the structure of a panel: whether it is balanced, has time gaps within an
id, or has duplicate `(PID,TID)` pairs. Always prints the summary and emits a
warning when duplicates are found. Returns a NamedTuple `(balanced, gaps,
duplicates)`.
"""
function checkpanel(df,PID::Symbol,TID::Symbol,delta=oneunit(df[1,TID]-df[1, TID]))
    bal = isbalanced(df,PID,TID)
    gap = hasgaps(df,PID,TID,delta)
    dup = hasduplicates(df,PID,TID)
    println("      balanced: $bal")
    println("          gaps: $gap")
    println("    duplicates: $dup")
    dup && @warn "Panel has duplicate ($PID, $TID) pairs; lags/diffs/spells will be unreliable"
    return (balanced=bal, gaps=gap, duplicates=dup)
end

function checkpanel(df)
    _assert_panel(df)
    checkpanel(df,metadata(df,"PID"),metadata(df,"TID"),metadata(df,"Delta"))
end
