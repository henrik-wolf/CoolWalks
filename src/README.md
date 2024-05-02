# CoolWalks
This package compiles utility functions and types to make working with street,
building and tree data much easier.

Here we give a brief overview of the contents within each file to help you integrate your own data into the project.

## `CoolWalks.jl`
This file defines the package. Here we combine all other files into a single
module.

It `export`s the public functions and types defined in the other files,
as well as `@reexport`s some packages which are needed in just about every script.

## Data preparation and setup
### `city_setup_types.jl`
This defines types used as a lightweight representation for different cities, both for real world datasets and synthetic ones.
They specify all information needed to load and prepare a dataset for analysis.

### `city_types.jl`
Here, we specify the types which hold the loaded data for a city.

### `city_loading.jl`
defines the functions which load a city from a city setup type. This is especially interesting if you want to load your own data into the project, mainly via the `load_city` function. Some helpers for post-processing the loaded raw data live here as well.

### `synthetic_cities.jl`
In this file we define the functions which load a synthetic city from a `<:AbstractSyntheticCity` type. (Rectangle, Hexagon, Voronoi, etc.)

## Data analysis
### `example_city_setups.jl`
This file defines the city setups which specify the cities used in the project.

### `preprocess_city.jl`
This file defines some functions to preprocess loaded cities. It is mostly to do with applying either a constant height to empirical cities and fitting the a histogram to empirical cities as well as sampling heights from these distributions.

### `experiments.jl`
This file defines an `AbstractExperiment` type which can be subtyped to run specific experiments on a city. Currently, we only define `FullExperiment`.

### `full_experiment_runner.jl`
This file defines the main workload to be done during the data analysis.

## Postprocessing
### `measures.jl`
This file defines the CoolWalkability and shadow fraction.

### `full_experiment_loader.jl`
This file defines the function which loads the results of an analysis run from disk and prepares them for plotting.

### `spatial_clustering.jl`
This file defines the functions used to do the spatial clustering analysis needed for figure 5.


## Plotting
### `paper_theme.jl`
This file defines a custom `Makie.jl` theme for the plots used in the paper.

### `simple_city.jl`
This file defines the simple city shown in figure 1.

### `plotting_utils.jl`
This file defines many plotting utilities used to generate the figures. They have probably not much utility beyond this project.

## Utilities
### `overloads.jl`
This file overloads functions from `MinistryOfCoolWalks` and `CoolWalksUtils` to work with the `City` type.