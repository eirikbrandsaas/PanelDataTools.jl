# PanelDataTools

[![Build Status](https://github.com/eirikbrandsaas/PanelDataTools.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/eirikbrandsaas/PanelDataTools.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/eirikbrandsaas/PanelDataTools.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/eirikbrandsaas/PanelDataTools.jl)

## Quick Start
Easily create leads, lags, and spells from a panel that is balanced, constant time gaps, *and* with non-missing time and id:
```julia
using PanelDataTools, DataFrames
df = DataFrame(id = [1,1,1,2,2,2], t = [1,2,3,1,2,3], a = [0,0,1,1,1,0])

lag!(df,:id,:t,:a)
lead!(df,:id,:t,:a)
lead!(df,:id,:t,:a,2) # last argument is how many lags
df
```
will give you
```julia
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

or to obtain spells as in `tsspell` in Stata:
```julia
df = DataFrame(id = [1,1,1,2,2,2], t = [1,2,3,1,2,3], a = [0,0,1,1,1,0])
spell!(df,:id,:t,:a)
```
will give you
```julia
6×6 DataFrame
 Row │ id     t      a      _spell  _seq   _end  
     │ Int64  Int64  Int64  Int64   Int64  Bool  
─────┼───────────────────────────────────────────
   1 │     1      1      0       1      1  false
   2 │     1      2      0       1      2   true
   3 │     1      3      1       2      1   true
   4 │     2      1      1       1      1  false
   5 │     2      2      1       1      2   true
   6 │     2      3      0       2      1   true
```
## Introduction
This package aims to introduce some convenience tools for working with Panel Data in the `DataFrames.jl` world in Julia.  In particular, it is inspired by some of Stata's great panel data packages such as `tsspell` and lag/lead/difference operators `L.`, `F.`, and `D.`. It relies on [`DataFrame.jl`](https://github.com/JuliaData/DataFrames.jl) and [`PanelShift.jl`](https://github.com/FuZhiyu/PanelShift.jl/blob/master/src/PanelShift.jl)

From the original announcement of the `tsspell` package:
> One underlying theme recurs frequently on Statalist: there's a direct solution to the problem making use of Stata's features. However, if you do this kind of thing a lot, you might also want a convenience program which encapsulates some of the basic tricks in the neighbourhood.
>
> [*Nick Cox on StataList*](https://www.stata.com/statalist/archive/2002-08/msg00279.html)

## Planned Stages
### **Done:** ~~First goals (lead, lag, spells):~~
For a single id `:pid` and time variable `:t` in a DataFrame (`df`) which contains a 1) balanced panel 2) with a constant time spacing (delta), 3) without missing time periods for any `:id`
- Easy syntax for creating *new* columns with lags and lads
  - `lag!(df,:id,:t,:var)`
  - `lead!(df,:id,:t,:var)`
  - Allow optional argument `;length=::Int` that sets the number of periods for the lag/lead operation
- Functionality that replicates the `tsspell` package (`spell!(df,:id,:t,:var)`)
  - Creates three new columsn in `df`:
    1. `_spell` for indicating distinct spells
    2. `_seq` for indicating the sequence *within* a spell
    3. `_end` which indicates if this is the end of a spell

### Secondary Goals (assertions, new type)
- Add checks for whether the panel satisfies assumed structures
- Add a new type `PanelDataFrame` (`PanelDataFrame`)that contains that, and also contains info on time gap (delta), length (T), individuals (N), name of the id and time variables. 
  - Preferably this on also has a trigger for if the dataset is modified so that it is no longer sorted.
  - For all functions allow passing this object instead of a `DataFrame` so that the user doesn't have to specify the `:id` and the `:t` variables all the time. This should also turn of sorting checks and would allow for some optimizations?


### Later goals
- Make the `spell` function faster
- Allow for less stringent panels (i.e., with missing time, unequal length, and so on)
- More functionality?

