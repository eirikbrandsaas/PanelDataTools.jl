# PanelDataTools

[![Build Status](https://github.com/eirikbrandsaas/PanelDataTools.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/eirikbrandsaas/PanelDataTools.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/eirikbrandsaas/PanelDataTools.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/eirikbrandsaas/PanelDataTools.jl)

## Introduction
This package aims to introduce some convenience tools for working with Panel Data in the `DataFrames.jl` world in Julia. The package currently supports lags, leads, diffs, seasonal diffs, and spell analysis.

 The package is inspired by Stata's great panel data features such as `tsspell` and lag/lead/difference operators `L.`, `F.`,`S.`, and `D.`. It relies on [`DataFrames.jl`](https://github.com/JuliaData/DataFrames.jl) and [`PanelShift.jl`](https://github.com/FuZhiyu/PanelShift.jl/blob/master/src/PanelShift.jl). The goal is to provide results that are correct and easy to obtain. 


## Workflow:
1. First set the `:id` and `:t` variables using `paneldf!(df::DataFrame, id::Symbol, t::Symbol)`
2. To find the lagged `:x` column use `lag!(df,:x)`.
   - If you don't want to store metadata you can pass the `id` and `t` column names directly: `lag!(df,:id,:t,:a))`
3. See below for examples of lags, leads, and diffs (where you can specify multiple colomns or time gaps), how to find spells (e.g., unemployment spells), how to fill time gaps, and giving names to new columns
### Examples working with Dates/Time:
The default time gap ("Delta") is 1 oneunit as determined by `oneunit()`. For `Int`, `Date`, and `DateTime` this defaults to `1`, `1 day`, and `1 millisecond`, respectively. If these are not the gaps you want, you must specify the correct gaps.

For example, here we have daily data with many gaps:
```julia
using PanelDataTools,DataFrames,Dates
df = DataFrame(id=fill(1,4),
    t=[Date(2000,1,1),Date(2000,1,2),Date(2000,2,1),Date(2001,1,1)],
    a=[0,1,1,1])
paneldf!(df,:id,:t)

panel variable: id
 time variable: t
         delta: 1 day
```
Next, we create lags of a with various gaps
```julia
lag!(df,:a,Day(1),name="L(Day=1)")
lag!(df,:a,Month(1),name="L(Month=1)")
lag!(df,:a,Day(366),name="L(Day=366)") # 366 days = one year (2000 was a leap year)
lag!(df,:a,Month(12),name="L(Month=12)") # 12 months = one year
lag!(df,:a,Year(1),name="L(Year=1)")
lag!(df,:a) # Default (picks time gap of 1 day and names the column "L1a")
display(df)
```
which gives:
```julia
4×9 DataFrame
 Row │ id     t           a      L(Day=1)  L(Month=1)  L(Day=366)  L(Month=12)  L(Year=1)  L1a     
     │ Int64  Date        Int64  Int64?    Int64?      Int64?      Int64?       Int64?     Int64?  
─────┼─────────────────────────────────────────────────────────────────────────────────────────────
   1 │     1  2000-01-01      0   missing     missing     missing      missing    missing  missing 
   2 │     1  2000-01-02      1         0     missing     missing      missing    missing        0
   3 │     1  2000-02-01      1   missing           0     missing      missing    missing  missing 
   4 │     1  2001-01-01      1   missing     missing           0            0          0  missing 

```
### Shifts: Leads and Lags
Easily create leads, lags, diffs, and seasonal diffs from panels:
```julia
using PanelDataTools, DataFrames
df = DataFrame(id = [1,1,1,2,2,2], t = [1,2,3,1,2,3], a = [0,0,1,1,1,0])
paneldf!(df,:id,:t)

lag!(df,:a)
lead!(df,:a)
lead!(df,:a,2) # last argument is how many lags
display(df)
6×6 DataFrame
 Row │ id     t      a      L1a      F1a      F2a
     │ Int64  Int64  Int64  Int64?   Int64?   Int64?
─────┼────────────────────────────────────────────────
   1 │     1      1      0  missing        0        1
   2 │     1      2      0        0        1  missing
   3 │     1      3      1        0  missing  missing
   4 │     2      1      1  missing        1        0
   5 │     2      2      1        1        0  missing
   6 │     2      3      0        1  missing  missing
```
or as a one-liner specifying multiple lead lags OR multiplate variables at a specific shift:
```julia
lag!(df,:id,:t,:a,[-2,-1,1]) # -2 and -1 becomes leads of a
lead!(df,:id,:t,:a,[-1,1,2]) # -1 becomes a lag
lag!(df,:id,:t,[:a,:b,:c],2) # Find lags of a,b, and c
```

### Differences
There is also support for "seasonal" and difference operators mimicking Stata's `S.x` and `D.x` syntax:
```julia
df = DataFrame(id = [1,1,1,2,2,2], t = [1,2,3,1,2,3], a = [1,1,1,1,0,0])
paneldf!(df,:id,:t)
diff!(df,:a,1)
diff!(df,:a,2)
seasdiff!(df,:a,1)
seasdiff!(df,:a,2)
display(df)
 Row │ id     t      a      D1a      D2a      S1a      S2a
     │ Int64  Int64  Int64  Int64?   Int64?   Int64?   Int64?
─────┼─────────────────────────────────────────────────────────
   1 │     1      1      1  missing  missing  missing  missing
   2 │     1      2      1        0  missing        0  missing
   3 │     1      3      1        0        0        0        0
   4 │     2      1      1  missing  missing  missing  missing
   5 │     2      2      0       -1  missing       -1  missing
   6 │     2      3      0        0        1        0       -1
```
### Provide Names
You can also create new variable names by adding the `name="FancyName"` keyword argument:
```julia
lag!(df,:a,name="FancyName")
```
Note that this only works operating over a single column.


### Spells
or to obtain spells as in `tsspell` in Stata:
```julia
df = DataFrame(id = [1,1,1,2,2,2], t = [1,2,3,1,2,3], a = [0,0,1,1,1,0])
paneldf!(df,:id,:t)
spell!(df,:a)
display(df)
6×6 DataFrame
 Row │ id     t      a      _spell  _seq
     │ Int64  Int64  Int64  Int64   Int64
─────┼────────────────────────────────────
   1 │     1      1      0       1      1
   2 │     1      2      0       1      2
   3 │     1      3      1       2      1
   4 │     2      1      1       1      1
   5 │     2      2      1       1      2
   6 │     2      3      0       2      1
```
### Filling in gaps (`tsfill`)
`tsfill` is used to fill in gaps of the time variable. You do not need to use it to construct the correct leads, lags or differences.
```julia
df = DataFrame(id = [1,1,2,2,2], t = [1,3,1,2,3], a = [1,1,1,0,0]) # Note, missing t=2 for id=1
paneldf!(df,:id,:t)
dfn = tsfill(df) # Since tsfill extends columns in the DataFrame is does not operate inplace
6×3 DataFrame
 Row │ id     t      a
     │ Int64  Int64  Int64?
─────┼───────────────────────
   1 │     1      1        1
   2 │     1      2  missing
   3 │     1      3        1
   4 │     2      1        1
   5 │     2      2        0
   6 │     2      3        0
```
or maybe you want to fill in with time gaps of 0.5:
```julia
dfn_half = tsfill(df,0.5)
 Row │ id     t        a       
     │ Int64  Float64  Int64?  
─────┼─────────────────────────
   1 │     1      1.0        1
   2 │     1      1.5  missing 
   3 │     1      2.0  missing 
   ⋮      ⋮       ⋮        ⋮
   9 │     2      2.5  missing 
  10 │     2      3.0        0
```
## Relevant links and packages
- [`GLM.jl`](https://github.com/JuliaStats/GLM.jl)
- [`FixedEffectsModels.jl`](https://github.com/FixedEffects/FixedEffectModels.jl)
- [`Econometrics.jl`](https://github.com/Nosferican/Econometrics.jl)
- [`Douglass.jl`](https://github.com/jmboehm/Douglass.jl)
- [`PeriodicalDates.jl`](https://github.com/matthieugomez/PeriodicalDates.jl)
- [`TSx.jl`](https://github.com/xKDR/TSx.jl)
- More? Please add other packages here.

## Possible future features
- [ ] Link with `GLM` or `FixedEffectModels` so that you can specify a model with lags (`Model(y ~ x + F.a`))


