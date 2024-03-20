# CoolWalks
This package compiles utility functions and types to make working with street,
building and tree data much easier.

Here we give a brief overview of the contents within each file to help you integrate your own data into the project.

## `CoolWalks.jl`
This file defines the package. Here we combine all other files into a single
module.

It `export`s the public functions and types defined in the other files,
as well as `@reexport`s some packages which are needed in just about every script.

## `city_setup_types.jl`
This defines types used as a lightweight representation for different cities.
They specify all information needed to load and prepare a dataset for analysis.

## `city_loading.jl`
This file specifies the functions which load a city from a city setup type. This
is especially interesting if you want to load your own data into the project.

## `synthetic_cities.jl`
Code to generate various synthetic cities based on voronoi-diagrams.

## `paper_theme.jl`
This file defines the custom theme for the plots used in the paper.