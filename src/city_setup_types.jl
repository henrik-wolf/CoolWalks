abstract type AbstractCitySetup end
abstract type AbstractSyntheticCitySetup <: AbstractCitySetup end

const CenterType = @NamedTuple{lon::Float64, lat::Float64}

struct RealCitySetup <: AbstractCitySetup
    # loader args
    name::Symbol
    network_type::Symbol
    city_type::Type{<:AbstractCityDataset}
    center::CenterType

    # postprocessing args
    max_trip_length::Float64
    pedestrianize::Bool
    correct_centerlines::Bool
end

struct RectangleCitySetup <: AbstractSyntheticCitySetup
    name::Symbol
    # generator args
    lx::Float64
    ly::Float64
    angle::Float64
    street_width::Float64
    building_height::Float64
    center::CenterType
    timezone::VariableTimeZone
    perturbation::Float64
    seed::Int

    # postprocessing (ish)
    max_trip_length::Float64
    correct_centerlines::Bool
end

struct RandomCitySetup <: AbstractSyntheticCitySetup
    name::Symbol
    # generator args
    average_area::Float64
    street_width::Float64
    building_height::Float64
    center::CenterType
    timezone::VariableTimeZone
    seed::Int

    # postprocessing (ish)
    max_trip_length::Float64
    correct_centerlines::Bool
end

struct HexagonCitySetup <: AbstractSyntheticCitySetup
    name::Symbol
    # generator args
    hex_radius::Float64
    angle::Float64
    street_width::Float64
    building_height::Float64
    center::CenterType
    timezone::VariableTimeZone
    perturbation::Float64
    seed::Int

    # postprocessing (ish)
    max_trip_length::Float64
    correct_centerlines::Bool
end