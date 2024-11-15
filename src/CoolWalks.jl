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
using Bezier
using MakiePublication
using Colors
using Makie
using CairoMakie
using IterTools
using ProgressBars
using LinearAlgebra
using PlotUtils
using Clustering
using GeoJSON

@reexport using DataFrames
@reexport using Dates
@reexport using StatsBase
@reexport using Chain

GeoInterfaceMakie.@enable ArchGDAL.IGeometry
bg(g) = GeoInterface.convert(GeometryBasics, g)
export bg

const AS = [1.0, 1.1, 1.25, 1.5, 2, 4, 10]
const WINTER_SOLSTICE = Date(2023, 12, 21)
const SUMMER_SOLSTICE = Date(2023, 6, 21)
export AS, WINTER_SOLSTICE, SUMMER_SOLSTICE

function __init__()
    CairoMakie.enable_only_mime!("image/png")
    Makie.set_theme!(CairoMakie=(px_per_unit=5.0,))
end

include("city_types.jl")
export SB_City

include("overloads.jl")
export get_day_limits

include("city_setup_types.jl")
export RealCitySetup, HexagonCitySetup, RectangleCitySetup, RandomCitySetup

include("synthetic_cities.jl")

include("park_loading.jl")

include("city_loading.jl")
export MANHATTAN_CENTER, BARCELONA_CENTER, VALENCIA_CENTER
export load_city

include("example_city_setups.jl")
export MANHATTAN_BIKE, MANHATTAN_WALK, MANHATTAN_PARK_BIKE, MANHATTAN_PARK_WALK
export BARCELONA_BIKE, BARCELONA_WALK, BARCELONA_PARK_BIKE, BARCELONA_PARK_WALK
export VALENCIA_BIKE, VALENCIA_WALK, VALENCIA_PARK_BIKE, VALENCIA_PARK_WALK
export MANHATTAN_GRID, MANHATTAN_RANDOM, BARCELONA_GRID

include("simple_city.jl")
export build_simple_city

include("preprocess_city.jl")
export set_constant_building_height!, height_distribution, resample_heights!

include("experiments.jl")
export FullExperiment, run_experiment_on

include("full_experiment_runner.jl")

include("measures.jl")
export coolwalkability, shadow_fraction

include("full_experiment_loader.jl")
export load_run

include("spatial_clustering.jl")
export prepare_cluster, clusters_simplified

include("paper_theme.jl")
export theme_paper, theme_paper_2col, SEQ_COL

include("plotting_utils.jl")
export partition_on_jumps, to_web_mercator, to_pretty_path, sun_arrows!, draw_city!
export findbetween, cross_marker, draw_city_with_heights!, scatter_on_cb!, circle_mask
export current_colors
export TimeTicks, time_x
export resample_lines_as_points, shade_points, normalize_shaded_arrays

end
