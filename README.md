# JuliaCon 2021

[![Build Status](https://github.com/JuliaCon/JuliaCon.jl/workflows/CI/badge.svg)](https://github.com/JuliaCon/JuliaCon.jl/actions)
[![Coverage](https://codecov.io/gh/JuliaCon/JuliaCon.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaCon/JuliaCon.jl)

## Live schedule

```julia
using JuliaCon

JuliaCon.now()

JuliaCon.today()
```

## T-Shirt code

This package makes the code on the JuliaCon 2021 [T-shirt](#t-shirt) work! Of course, you should [buy one here](https://www.bonfire.com/juliacon-repl/)!

To make the `@everywhere` do something you need to start Julia with multiple worker processes: `julia -p 4`.

<!-- <img width="588" alt="Screenshot 2021-05-31 at 22 28 07" src="https://user-images.githubusercontent.com/187980/120239846-7c6afc80-c25f-11eb-892b-dd52be136f36.png"> -->

```julia
using JuliaCon, Distributed

@everywhere juliacon2021()
```

<img width="700" alt="Screenshot 2021-05-31 at 22 34 12" src="https://user-images.githubusercontent.com/187980/120240233-5a25ae80-c260-11eb-89a5-74f02c1dd475.png">
