# PanelDataTools

[![Build Status](https://github.com/eirikbrandsaas/PanelDataTools.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/eirikbrandsaas/PanelDataTools.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/eirikbrandsaas/PanelDataTools.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/eirikbrandsaas/PanelDataTools.jl)

## Introduction
This package aims to introduce some convenience tools for working with Panel Data in the `DataFrames.jl` world in Julia.  In particular, it is inspired by some of Stata's great panel data packages such as `tsspell` and lag/lead/difference operators `L.`, `F.`, and `D.`. It relies on [`DataFrame.jl`](https://github.com/JuliaData/DataFrames.jl) and [`PanelShift.jl`](https://github.com/FuZhiyu/PanelShift.jl/blob/master/src/PanelShift.jl)

From the original announcement of the `tsspell` package:
> One underlying theme recurs frequently on Statalist: there's a direct solution to the problem making use of Stata's features. However, if you do this kind of thing a lot, you might also want a convenience program which encapsulates some of the basic tricks in the neighbourhood.
>
> [*Nick Cox on StataList*](https://www.stata.com/statalist/archive/2002-08/msg00279.html)

## Quick Start
Easily create leads, lags, and spells from panels:
```julia
using PanelDataTools, DataFrames
df = DataFrame(id = [1,1,1,2,2,2], t = [1,2,3,1,2,3], a = [0,0,1,1,1,0])

lag!(df,:id,:t,:a)
lead!(df,:id,:t,:a)
lead!(df,:id,:t,:a,2) # last argument is how many lags
df
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
df
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

## Next steps
- Allow the user to specify names of new columns
- Add a new type `PanelDataFrame` (`PanelDataFrame`)that contains that, and also contains info on time gap (delta), length (T), individuals (N), name of the id and time variables. 
  - Preferably this on also has a trigger for if the dataset is modified so that it is no longer sorted.
  - For all functions allow passing this object instead of a `DataFrame` so that the user doesn't have to specify the `:id` and the `:t` variables all the time. This should also turn of sorting checks and would allow for some optimizations?

### Later goals
- Make the `spell` function faster
- Allow for less stringent panels (i.e., with missing time, unequal length, and so on)
- More functionality?

