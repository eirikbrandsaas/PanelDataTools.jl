module PanelDataTools

# Write your package code here.
using DataFrames
using PanelShift
using Dates


include("spell.jl")
include("laglead.jl")
include("diffs.jl")
include("utilities.jl")
include("tsfill.jl")
include("checks.jl")


export spell!, lead!, lag!, seasdiff!, diff!
export tsfill
export paneldf!
export isbalanced, hasgaps, hasduplicates, checkpanel
end
