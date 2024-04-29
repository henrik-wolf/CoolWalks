#MARK: helpers
function points2linestring(p1, p2)
    ls = ArchGDAL.createlinestring([getcoord(p1, 1), getcoord(p2, 1)], [getcoord(p1, 2), getcoord(p2, 2)])
    return apply_wsg_84!(ls)
end

function building_from_cell(cell, street_width, crs)
    p = ArchGDAL.createpolygon(Tuple.([cell; [cell[1]]]))
    p = ArchGDAL.buffer(p, -street_width)
    return reinterp_crs!(p, crs)
end

function rotate(x, y, phi)
    cp = cos(phi)
    sp = sin(phi)
    @. cp * x - sp * y, sp * x + cp * y
end

# MARK: grid city
function grid_city(setup::RectangleCitySetup)
    rng = MersenneTwister(setup.seed)

    r = setup.max_trip_length * 3

    x_c = [reverse(0:-setup.lx:-r)[1:end-1]; 0:setup.lx:r]
    y_c = [reverse(0:-setup.ly:-r)[1:end-1]; 0:setup.ly:r]

    x_coords = repeat(x_c, 1, length(y_c))
    y_coords = repeat(y_c', length(x_c))

    x_coords, y_coords = rotate(x_coords, y_coords, deg2rad(setup.angle))

    normal_dist = MvNormal([0, 0], [setup.perturbation, setup.perturbation])
    perturbations = rand(rng, normal_dist, size(x_coords)...)

    x_coords .+= getindex.(perturbations, 1)
    y_coords .+= getindex.(perturbations, 2)

    rect = Rectangle(Point2(-2r, -2r), Point2(2r, 2r))
    points = Point2.(x_coords, y_coords) |> vec

    return points_to_city(points, rect, setup)
end

# MARK: random city
function random_voronoi_city(setup::RandomCitySetup)
    rng = MersenneTwister(setup.seed)

    box_edge_length = setup.max_trip_length * 6
    num_points = ceil(Int, (box_edge_length)^2 / setup.average_area)

    x_coords = (rand(rng, num_points) .- 0.5) .* box_edge_length
    y_coords = (rand(rng, num_points) .- 0.5) .* box_edge_length
    rect = Rectangle(Point2(-box_edge_length, -box_edge_length), Point2(box_edge_length, box_edge_length))
    points = Point2.(x_coords, y_coords)

    return points_to_city(points, rect, setup)
end


# MARK: hexgrid city
function hexgrid_city(setup::HexagonCitySetup)
    rng = MersenneTwister(setup.seed)
    p = ArchGDAL.buffer(ArchGDAL.createpoint(0.0, 0.0), setup.max_trip_length * 3)
    hexes = hexagonify(p, setup.hex_radius)
    centerpoints = GeoInterface.coordinates.(MinistryOfCoolWalks.hex_center.(hexes, setup.hex_radius))
    x_coords = getindex.(centerpoints, 1)
    y_coords = getindex.(centerpoints, 2)
    x_coords, y_coords = rotate(x_coords, y_coords, deg2rad(setup.angle))

    normal_dist = MvNormal([0, 0], [setup.perturbation, setup.perturbation])
    perturbations = rand(rng, normal_dist, size(x_coords))

    x_coords .+= getindex.(perturbations, 1)
    y_coords .+= getindex.(perturbations, 2)

    r = setup.max_trip_length * 3
    rect = Rectangle(Point2(-r, -r), Point2(2r, 2r))
    points = Point2.(x_coords, y_coords) |> vec

    return points_to_city(points, rect, setup)
end



# MARK: points to city
function points_to_city(points, rect, setup)
    # get local crs
    p = ArchGDAL.createpoint(setup.center.lon, setup.center.lat) |> apply_wsg_84!
    project_local!(p, setup.center.lon, setup.center.lat)
    crs = ArchGDAL.getspatialref(p)

    # build voronoi cells
    tess = voronoicells(points, rect)
    cc = VoronoiCells.corner_coordinates(tess)
    ccp = [ArchGDAL.createpoint(p...) for p in cc]

    rt = RTree{Float64,2}(Int, eltype(ccp))
    edgestring = Int[]

    # fill edgestring with corner indices into ccp, merging close by corners
    for (i, geom) in enumerate(ccp)
        if GeoInterface.isempty(geom)
            push!(edgestring, -1)
            continue
        end
        bbox = rect_from_geom(geom; buffer=0.1)

        inters = collect(intersects_with(rt, bbox))
        if isempty(inters)
            insert!(rt, bbox, i, geom)
            push!(edgestring, i)
        elseif length(inters) == 1
            push!(edgestring, first(inters).id)
        else
            @error "more than one intersection."
        end
    end

    # map each corner geom to contiguous index in graph
    corners = sort(unique(edgestring))[2:end]
    vert_inds = Dict(c => i for (i, c) in enumerate(corners))

    # build edges in future street graph
    edges = Set{Edge}()
    for (a, b) in zip(edgestring[1:end-1], edgestring[2:end])
        a == -1 && continue
        b == -1 && continue
        a == b && continue

        # find index of a and b in corners
        s = vert_inds[a]
        d = vert_inds[b]
        push!(edges, Edge(s, d), Edge(d, s))
    end

    # create graph
    g = MetaDiGraph(length(corners), :sg_street_length, 0.0)
    obs = ShadowObservatory(string(setup.name), setup.center.lon, setup.center.lat, setup.timezone)
    set_prop!(g, :sg_observatory, obs)
    set_prop!(g, :sg_crs, crs)
    set_prop!(g, :sg_offset_dir, 1)

    for v in vertices(g)
        set_prop!(g, v, :sg_geometry, ccp[corners[v]])
    end

    # add edges with props
    for (i, e) in enumerate(edges)
        eg_new = reinterp_crs!(points2linestring(ccp[corners[src(e)]], ccp[corners[dst(e)]]), crs)

        e_data = Dict(
            :sg_osm_id => i,
            :sg_tags => Dict("highway" => "living_street", "oneway" => false),
            :sg_geometry_base => eg_new,
            :sg_street_geometry => ArchGDAL.clone(eg_new),
            :sg_street_length => ArchGDAL.geomlength(eg_new),
            :sg_parsing_direction => 1,
            :sg_helper => false
        )
        add_edge!(g, src(e), dst(e), e_data)
    end

    # create buildings
    buildings = building_from_cell.(tess.Cells, setup.street_width, Ref(crs))
    @show length(buildings)
    gens = [GeoInterface.convert(ArchGDAL, i) for i in tess.Generators]
    reinterp_crs!(gens, crs)
    df = DataFrame(:id => eachindex(buildings), :geometry => buildings, :points => gens, :height => repeat([setup.building_height], length(buildings)))
    filter!(:geometry => !ArchGDAL.isempty, df)
    metadata!(df, "observatory", obs, style=:note)
    project_back!(df)

    # set stuff that needs the graph in global projection
    project_back!(g)
    for v in vertices(g)
        pg = get_prop(g, v, :sg_geometry)
        set_props!(g, v, Dict(:sg_lon => getcoord(pg, 1), :sg_lat => getcoord(pg, 2), :sg_helper => false, :sg_osm_id => v))
    end

    ShadowGraphs.check_shadow_graph_integrity(g; strict=true)
    CompositeBuildings.check_building_dataframe_integrity(df)

    return SB_City(Symbol("tesselation_" * string(setup.name)), obs, g, df, DataFrame())
end