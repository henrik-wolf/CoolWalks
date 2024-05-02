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
   julia> Pkg.Registry.add(RegistrySpec(url="https://github.com/henrik-wolf/CoolWalksRegistry"))

   julia> Pkg.activate("path/to/this/project")

   julia> Pkg.instantiate()
   ```

   This will install all necessary packages for you to be able to run the scripts and
everything should work out of the box, including correctly finding local paths.

3. Download the datasets for the experiments from [zenodo](https://doi.org/10.5281/zenodo.11103149) and place them in the `data/` folder.
4. Check if the files are in the right place by running
   ```console
   julia scripts/0_check_datasets.jl
   ```

## Next steps
### Reproduce the paper
The datasets include the final, processed datasets from our analysis. You can reproduce the figures from the paper by running the corresponding scripts in `scripts/paper_plots/*`.

If you want to rerun the experiments for the paper, you can do so by running the script `1_run_analysis.jl`.

### Run your own data
In order to run your own datasets, you need two things: a network as specified by [ShadowGraphs.jl](https://github.com/henrik-wolf/ShadowGraphs.jl) and buildings as specified by [CompositeBuildings.jl](https://github.com/henrik-wolf/CompositeBuildings.jl).

Every empirical dataset works of the `RealCitySetup` type, which is a full description of the dataset you want to run an `Experiment` on. We load and prepare the dataset by calling `load_city` on the `setup`. Which then dispatches on the name of the city `setup.name`, the network type `setup.network_type` and the city type `city_type` of your specific dataset. To integrate your datasets into this project, you thus need to overload the function
```julia
function load_real_city(setup, name::Val{:your_city_name}, network_type::Val{:your_network_type}, city_type::Type{SB_City})
streets = # load your streets
buildings = # load your buildings
return SB_City(...)
end
```
Take a look at `src/city_loading.jl` for the dispatches for the examle datasets. Additionally, look into `src/example_city_setups.jl` for some example definitions of `CitySetup`s.

### Dive into the code
Take a look at the source code in `src/*` for this package. (See [Source README](./src/README.md) for a brief overview of the contents of each file.)
Additionally, you can look into the source code of the other packages this project depends on at [MinistryOfCoolWalks.jl](https://github.com/henrik-wolf/MinistryOfCoolWalks.jl)

## Notes
You may notice that most scripts start with the commands:
```julia
using DrWatson
@quickactivate :CoolWalks
```
which auto-activates the project and imports (`uses`) the `CoolWalks` package defined in `/src/`. This enables DrWatson to correctly handle local paths and to ensure that the scripts always run in the correct environment.
