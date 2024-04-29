const MANHATTAN_CENTER = (lon=-73.98453935498527, lat=40.755912592117085)
const BARCELONA_CENTER = (lon=2.1666650831781715, lat=41.3995633881266)
const VALENCIA_CENTER = (lon=-0.37411289866087866, lat=39.47024475773071)

function load_city(setup::RealCitySetup)
    city = load_real_city(setup, setup.name, setup.network_type, setup.city_type)
    return postprocess_city!(city, setup)
end

function load_city(setup::AbstractSyntheticCitySetup)
    city = load_synthetic_city(setup)
    return postprocess_city!(city, setup)
end

load_real_city(setup, name::Symbol, network_type::Symbol, city_type::Type{<:AbstractCityDataset}) = load_real_city(setup, Val(name), Val(network_type), city_type)

# MARK: example data loading
function load_real_city(setup, name::Val{:manhattan}, network_type::Val{T}, city_type::Type{SB_City}) where {T}
    graph_path = datadir("exp_raw", "manhattan", "network_$(T).json")
    g = shadow_graph_from_file(graph_path, network_type=T, timezone=tz"America/New_York")

    building_path = datadir("exp_raw", "manhattan", "buildings", "manhattan.shp")
    b = load_new_york_shapefiles(building_path, extent=nothing)
    obs = ShadowObservatory("manhattan", setup.center.lon, setup.center.lat, tz"America/New_York")
    return SB_City(:manhattan, obs, g, b, DataFrame())
end

function load_real_city(setup, name::Val{:barcelona}, network_type::Val{T}, city_type::Type{SB_City}) where {T}
    graph_path = datadir("exp_raw", "barcelona", "network_$(T).json")
    g = shadow_graph_from_file(graph_path, network_type=T, timezone=tz"Europe/Madrid")

    building_path = datadir("exp_raw", "barcelona")
    b = load_spain_processed_buildings(building_path)
    obs = ShadowObservatory("barcelona", setup.center.lon, setup.center.lat, tz"Europe/Madrid")
    return SB_City(:barcelona, obs, g, b, DataFrame())
end

function load_real_city(setup, name::Val{:valencia}, network_type::Val{T}, city_type::Type{SB_City}) where {T}
    graph_path = datadir("exp_raw", "valencia", "network_$(T).json")
    g = shadow_graph_from_file(graph_path, network_type=T, timezone=tz"Europe/Madrid")

    building_path = datadir("exp_raw", "valencia")
    b = load_spain_processed_buildings(building_path)
    obs = ShadowObservatory("valencia", setup.center.lon, setup.center.lat, tz"Europe/Madrid")
    return SB_City(:valencia, obs, g, b, DataFrame())
end

# MARK: load synthetic cities
load_synthetic_city(setup::RectangleCitySetup) = grid_city(setup)
load_synthetic_city(setup::RandomCitySetup) = random_voronoi_city(setup)
load_synthetic_city(setup::HexagonCitySetup) = hexgrid_city(setup)


# MARK: Postprocessing
function postprocess_city!(city, setup::T) where {T<:AbstractCitySetup}
    cut_and_tag!(city, max_trip_length=setup.max_trip_length)

    if hasfield(T, :pedestrianize) && setup.pedestrianize
        pedestrianize!(city.streets)
    end
    if setup.correct_centerlines
        correct_centerlines!(city)
    end
    return city
end

function cut_and_tag!(city; max_trip_length)
    @info "$(filter_vertices(city.streets, :inside, true) |> collect |> length) inside of circle"
    cut_around!(city, max_trip_length * 2)
    tag_inside!(city, max_trip_length)
    set_prop!(city.streets, :max_trip_length, max_trip_length)
    @info "$(filter_vertices(city.streets, :inside, true) |> collect |> length) inside of circle"
    return city
end

# MARK: cut to circle
function cut_around!(city::AbstractCityDataset, distance)
    project_local!(city.streets, city.observatory)
    center = ArchGDAL.createpoint(0, 0)
    vids = filter(reverse(vertices(city.streets))) do v
        ArchGDAL.distance(get_prop(city.streets, v, :sg_geometry), center) > distance
    end
    # vids are ordered from highest index to lowest to not run into problems with graph indices
    foreach(i -> rem_vertex!(city.streets, i), vids)
    components = connected_components(city.streets)
    largest = argmax(length, components)
    for v in reverse(vertices(city.streets))
        v in largest && continue
        rem_vertex!(city.streets, v)
    end

    project_back!(city.streets)

    set_prop!(city.streets, :sg_observatory, city.observatory)

    cut_around_casters!(city, distance)
    return city
end

cut_around_casters!(city::SB_City, distance) = cut_around_casters!(city.buildings, city.observatory, distance)
cut_around_casters!(city::ST_City, distance) = cut_around_casters!(city.trees, city.observatory, distance)

function cut_around_casters!(city, distance)
    cut_around_casters!(city.buildings, city.observatory, distance)
    cut_around_casters!(city.trees, city.observatory, distance)
end

function cut_around_casters!(geometry_df, observatory, distance)
    center = ArchGDAL.createpoint(0, 0)

    project_local!(geometry_df, observatory)
    filter!(:geometry => g -> ArchGDAL.distance(g, center) <= distance, geometry_df)
    project_back!(geometry_df)

    metadata!(geometry_df, "observatory", observatory, style=:note)
end

# MARK: tag inside circle
function tag_inside!(city, max_trip_length)
    center = ArchGDAL.createpoint(0, 0)
    project_local!(city.streets, city.observatory)
    for v in vertices(city.streets)
        set_prop!(city.streets, v, :inside, ArchGDAL.distance(center, get_prop(city.streets, v, :sg_geometry)) <= max_trip_length)
    end
    project_back!(city.streets)
end