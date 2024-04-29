module CoolWalks

using DrWatson
using Reexport
using Graphs, MetaGraphs
using TimeZones
using ShadowGraphs
using CompositeBuildings
using GeoInterfaceMakie
using ArchGDAL
using CoolWalksUtils
using MinistryOfCoolWalks
using Random
using Distributions
using GeometryBasics
using VoronoiCells
using SpatialIndexing
using GeoInterface

@reexport using DataFrames

GeoInterfaceMakie.@enable ArchGDAL.IGeometry

include("city_types.jl")
export SB_City

include("overloads.jl")

include("city_setup_types.jl")
export RealCitySetup, HexagonCitySetup, RectangleCitySetup, RandomCitySetup

include("synthetic_cities.jl")

include("city_loading.jl")
export MANHATTAN_CENTER, BARCELONA_CENTER, VALENCIA_CENTER
export load_city

include("example_city_setups.jl")
export MANHATTAN_BIKE, MANHATTAN_WALK
export BARCELONA_BIKE, BARCELONA_WALK
export VALENCIA_BIKE, VALENCIA_WALK
export MANHATTAN_GRID, MANHATTAN_RANDOM, BARCELONA_GRID

end
