function build_simple_city_path(p1, p2, height, base_shift, pim)
    x1, y1 = getcoord(p1)
    x2, y2 = getcoord(p2)
    ps = bezier([x1; range(x1, x2, pim); x2], [y1 + base_shift; repeat([height + base_shift], pim); y2 + base_shift])
    ps = ([x1; ps[1]; x2], [y1; ps[2]; y2])
    reinterp_crs!(ArchGDAL.createlinestring(ps...), ArchGDAL.getspatialref(p1))
end

function build_rect(x, y, dx, dy)
    x = [x - dx, x + dx, x + dx, x - dx, x - dx]
    y = [y - dy, y - dy, y + dy, y + dy, y - dy]
    return ArchGDAL.createpolygon(x, y)
end

function build_simple_city()
    vertex_props = Dict{Symbol,Any}[
        Dict(:sg_lon => 12.001787950562413, :sg_osm_id => 1, :sg_helper => false, :sg_lat => 54.999999986863614)
        Dict(:sg_lon => 11.998212049437589, :sg_osm_id => 2, :sg_helper => false, :sg_lat => 54.999999986863614)
        Dict(:sg_lon => 11.998212049437589, :sg_osm_id => 3, :sg_helper => true, :sg_lat => 54.999999986863614)
        Dict(:sg_lon => 12.001787950562413, :sg_osm_id => 4, :sg_helper => true, :sg_lat => 54.999999986863614)
        Dict(:sg_lon => 11.998212049437589, :sg_osm_id => 5, :sg_helper => true, :sg_lat => 54.999999986863614)
        Dict(:sg_lon => 12.001787950562413, :sg_osm_id => 6, :sg_helper => true, :sg_lat => 54.999999986863614)
    ]
    for i in vertex_props
        i[:sg_geometry] = apply_wsg_84!(ArchGDAL.createpoint(i[:sg_lon], i[:sg_lat]))
    end

    edge_props = Dict((1, 2) => Dict(
            :sg_street_geometry => "LINESTRING (12.0017879505624 54.9999999868636,11.9982120494376 54.9999999868636)",
            :sg_osm_id => 0,
            :sg_street_length => 228.836679,
            :sg_tags => Dict{String,Any}("oneway" => false, "highway" => "living_street"),
            :sg_helper => false,
            :sg_parsing_direction => 1,
            :sg_geometry_base => "LINESTRING (12.0017879505624 54.9999999868636,11.9982120494376 54.9999999868636)",
        ),
        (1, 3) => Dict(
            :sg_street_geometry => "LINESTRING (12.0017879505624 54.9999999868636,12.0017754843481 55.0007733741941,11.9982269844748 55.0007697829144,11.9982120494376 54.9999999868636)",
            :sg_osm_id => 2,
            :sg_street_length => 398.88081193048345,
            :sg_tags => Dict{String,Any}("oneway" => false, "highway" => "living_street"),
            :sg_helper => false,
            :sg_parsing_direction => 1,
            :sg_geometry_base => "LINESTRING (12.0017879505624 54.9999999868636,12.0017754843481 55.0007733741941,11.9982269844748 55.0007697829144,11.9982120494376 54.9999999868636)",
        ),
        (1, 5) => Dict(
            :sg_street_geometry => "LINESTRING (12.0017879505624 54.9999999868636,12.0017756916508 55.0016246581476,11.998225818619 55.0016290863697,11.9982120494376 54.9999999868636)",
            :sg_osm_id => 6,
            :sg_street_length => 589.3875182138285,
            :sg_tags => Dict{String,Any}("oneway" => false, "highway" => "living_street"),
            :sg_helper => false,
            :sg_parsing_direction => 1,
            :sg_geometry_base => "LINESTRING (12.0017879505624 54.9999999868636,12.0017756916508 55.0016246581476,11.998225818619 55.0016290863697,11.9982120494376 54.9999999868636)",
        ),
        (2, 1) => Dict(
            :sg_street_geometry => "LINESTRING (11.9982120494376 54.9999999868636,12.0017879505624 54.9999999868636)",
            :sg_osm_id => 1,
            :sg_street_length => 228.836679,
            :sg_tags => Dict{String,Any}("oneway" => false, "highway" => "living_street"),
            :sg_helper => false,
            :sg_parsing_direction => 1,
            :sg_geometry_base => "LINESTRING (11.9982120494376 54.9999999868636,12.0017879505624 54.9999999868636)",
        ),
        (2, 4) => Dict(
            :sg_street_geometry => "LINESTRING (11.9982120494376 54.9999999868636,11.9982269844748 55.0007697829144,12.0017754843481 55.0007733741941,12.0017879505624 54.9999999868636)",
            :sg_osm_id => 4,
            :sg_street_length => 398.88081193048345,
            :sg_tags => Dict{String,Any}("oneway" => false, "highway" => "living_street"),
            :sg_helper => false,
            :sg_parsing_direction => 1,
            :sg_geometry_base => "LINESTRING (11.9982120494376 54.9999999868636,11.9982269844748 55.0007697829144,12.0017754843481 55.0007733741941,12.0017879505624 54.9999999868636)",
        ),
        (2, 6) => Dict(
            :sg_street_geometry => "LINESTRING (11.9982120494376 54.9999999868636,11.998225818619 55.0016290863697,12.0017756916508 55.0016246581476,12.0017879505624 54.9999999868636)",
            :sg_osm_id => 8,
            :sg_street_length => 589.3875182138285,
            :sg_tags => Dict{String,Any}("oneway" => false, "highway" => "living_street"),
            :sg_helper => false,
            :sg_parsing_direction => 1,
            :sg_geometry_base => "LINESTRING (11.9982120494376 54.9999999868636,11.998225818619 55.0016290863697,12.0017756916508 55.0016246581476,12.0017879505624 54.9999999868636)",
        ),
        (3, 2) => Dict(:sg_helper => true),
        (4, 1) => Dict(:sg_helper => true),
        (5, 2) => Dict(:sg_helper => true),
        (6, 1) => Dict(:sg_helper => true)
    )
    for (e, p) in edge_props
        for (k, v) in p
            if k == :sg_street_geometry || k == :sg_geometry_base
                p[k] = apply_wsg_84!(ArchGDAL.fromWKT(v))
            end
        end
    end

    # create graph with correct number of nodes
    g = MetaDiGraph(0, :sg_street_length, 0.0)
    for v in vertex_props
        add_vertex!(g, v)
    end

    for (e, p) in edge_props
        add_edge!(g, e[1], e[2], p)
    end

    set_prop!(g, :sg_crs, ArchGDAL.getspatialref(vertex_props[1][:sg_geometry]))
    set_prop!(g, :sg_offset_dir, 1.0)
    obs = ShadowObservatory("testobs", 12.0, 55.0, tz"Europe/Berlin")
    set_prop!(g, :sg_observatory, obs)

    # create city with nice shapes
    city = SB_City(:example_city, obs, g, DataFrame(), DataFrame())
    project_local!(city.streets, city.observatory)
    project_local!(city.buildings, city.observatory)

    # make edges smooth
    ml = [get_prop(city.streets, e, :sg_street_length) for e in filter_edges(city.streets, :sg_street_length)] |> maximum

    for e in filter_edges(city.streets, :sg_helper, false)
        ngeom(get_prop(city.streets, e, :sg_street_geometry)) == 2 && continue
        h = get_prop(city.streets, e, :sg_street_length) / ml
        eg = build_simple_city_path(get_prop(city.streets, src(e), :sg_geometry), get_prop(city.streets, dst(e), :sg_geometry), h == 1 ? 90 : 74, h == 1 ? 30 : 0, floor(Int, 7h^1.5))
        set_prop!(city.streets, e, :sg_geometry_base, eg)
        set_prop!(city.streets, e, :sg_street_geometry, ArchGDAL.clone(eg))
        set_prop!(city.streets, e, :sg_street_length, ArchGDAL.geomlength(eg))
    end

    # add buildings
    buildings = map([
        (-67, 26, 21, 14),
        (-1, 30, 15, 19),
        (51, 37, 19, 13),
        (-50, 92, 13, 13),
        (-7, 91, 13, 15),
        (29, 90, 14, 13),
        (68, 90, 14, 12),
        (136, 29, 14, 15),
    ]) do args
        reinterp_crs!(build_rect(args...), get_prop(city.streets, :sg_crs))
    end
    heights = [46, 17, 9, 19, 13, 19, 11, 30]

    for i in 1:length(buildings)
        push!(city.buildings, (id=i, geometry=buildings[i], height=heights[i]))
    end
    metadata!(city.buildings, "observatory", obs, style=:note)

    project_back!(city.streets)
    project_back!(city.buildings)
    return city
end