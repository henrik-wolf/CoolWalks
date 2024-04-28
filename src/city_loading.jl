const MANHATTAN_CENTER = (lon=-73.98453935498527, lat=40.755912592117085)
const BARCELONA_CENTER = (lon=2.1666650831781715, lat=41.3995633881266)
const VALENCIA_CENTER = (lon=-0.37411289866087866, lat=39.47024475773071)

function load_city(setup::RealCitySetup)
    c = load_real_city(setup, setup.name, setup.network_type, setup.city_type)
    return c
end

load_real_city(setup, name::Symbol, network_type::Symbol, city_type::Type{AbstractCityType}) = load_real_city(setup, Val(name), Val(network_type), city_type)

function load_real_city(setup, name::Val{:manhattan}, network_type, city_type::SB_City)
    graph_path = datadir("exp_raw", "manhattan", "network_$(network_type).json")
    g = shadow_graph_from_file(full_path, network_type=network_type, timezone=tz"America/New_York")

    building_path = datadir("exp_raw", "manhattan", "buildings", "manhattan.shp")
    b = load_new_york_shapefiles(file, extent=nothing)
    return SB_City(name, g, b, DataFrame())
end