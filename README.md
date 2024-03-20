# CoolWalks

This code base is using the [Julia Language](https://julialang.org/) and [DrWatson](https://juliadynamics.github.io/DrWatson.jl/stable/) to make a reproducible scientific project named

> CoolWalks

## Installation
To (locally) reproduce this project, do the following:

0. (Install Julia if you haven't already. The prefered way of doing so is via [juliaup](https://github.com/JuliaLang/juliaup)).
1. Download this code base.
2. Open a Julia console and do:
   ```julia
   julia> using Pkg

   julia> Pkg.add("DrWatson") # install globally, for using `quickactivate`

   # add the registry which distributes the CoolWalks packages
   julia> Pkg.Registry.add(RegistrySpec(url="https://github.com/SuperGrobi/CoolWalksRegistry"))

   julia> Pkg.activate("path/to/this/project")

   julia> Pkg.instantiate()
   ```

   This will install all necessary packages for you to be able to run the scripts and
everything should work out of the box, including correctly finding local paths.

3. Download the raw datasets used in the paper by running in the root of the project:
   ```console
   julia scripts/0_prepare_datasets.jl
   ```

## Next steps
### Reproduce the paper
- run scripts for data gen
- run scripts for data analysis
- run notebook(s) for plots(?)

### Run your own data
- take a look at `intro to data loading notebook` for an explanation on how we specify datasets in this project
- dive into the source for this package (see [Source README](./src/README.md))
- as well as into the other `CoolWalks` packages this whole analysis depends on

## Notes
You may notice that most scripts start with the commands:
```julia
using DrWatson
@quickactivate :CoolWalks
```
which auto-activates the project and imports (`uses`) the `CoolWalks` package defined in `/src/`. This enables DrWatson to correctly handle local paths and to ensure that the scripts always run in the correct environment.