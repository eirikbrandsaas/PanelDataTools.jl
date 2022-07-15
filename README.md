# PanelDataTools

[![Build Status](https://github.com/eirikbrandsaas/PanelDataTools.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/eirikbrandsaas/PanelDataTools.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/eirikbrandsaas/PanelDataTools.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/eirikbrandsaas/PanelDataTools.jl)

## Quick Start
Easily create leads, lags, and spells from a balanced, uniform, no-missing Panel:
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
This package aims to introduce some convenience tools for working with Panel Data in the `DataFrames.jl` world in Julia.  In particular, it is inspired by some of Stata's great panel data packages such as `tsspell` and lag/lead/difference operators `L.`, `F.`, and `D.`.

From the original announcement of the `tsspell` package:
> One underlying theme recurs frequently on Statalist: there's a direct solution to the problem making use of Stata's features. However, if you do this kind of thing a lot, you might also want a convenience program which encapsulates some of the basic tricks in the neighbourhood.
>
> [*Nick Cox on StataList*](https://www.stata.com/statalist/archive/2002-08/msg00279.html)

## First goals:
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

## Secondary Goals
...

## Things to think about
- Implement a new struct that is a `PanelDataFrame` which is just a `GroupedDataFrame` but which also stores the time variable, it's steps, and so on? 
  - This way we don't have to always tell the program the time variable =)