abstract type AbstractCityDataset end
mutable struct SB_City <: AbstractCityDataset
    name::Symbol
    streets::MetaGraphs.MetaDiGraph
    buildings::DataFrame
    shadows::DataFrame
end
mutable struct ST_City <: AbstractCityDataset
    name::Symbol
    streets::MetaGraphs.MetaDiGraph
    trees::DataFrame
    shadows::DataFrame
end
mutable struct SBT_City <: AbstractCityDataset
    name::Symbol
    streets::MetaGraphs.MetaDiGraph
    buildings::DataFrame
    trees::DataFrame
    building_shadows::DataFrame
    tree_shadows::DataFrame
end