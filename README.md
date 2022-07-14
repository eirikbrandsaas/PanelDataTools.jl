# PanelDataTools

[![Build Status](https://github.com/eirikbrandsaas/PanelDataTools.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/eirikbrandsaas/PanelDataTools.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/eirikbrandsaas/PanelDataTools.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/eirikbrandsaas/PanelDataTools.jl)

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