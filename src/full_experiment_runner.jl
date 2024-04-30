function run_experiment_on(city, experiment::FullExperiment)
    result = DataFrame()

    reachability, distance_dict = calculate_base_values(city, experiment)
    push!(result, merge(distance_dict, Dict("a" => 1.0)), cols=:union)

    day = experiment.day
    @info "starting $day"
    rise, down = get_day_limits(day, city, min_angle=8.0)
    rise -= Minute(30)
    down += Minute(30)
    times = rise:Minute(15):down

    for daytime in times
        @info "starting time $daytime"
        add_shadow_intervals!(city, daytime)
        pbar = ProgressBar(experiment.sun_aversions, printing_delay=1.0)
        set_description(pbar, "routing for time $daytime")
        for a in pbar
            param_dict = @strdict daytime a
            distance_dict = extract_data(city, a, experiment; reachability=reachability)
            push!(result, merge(distance_dict, param_dict), cols=:union)
        end
    end
    return result
end

"""
    calculate_base_values(city, experiment::FullExperiment)

calculates all the values needed to call `extract_data` on `city`.

# Arguments
- `city`: City on which to run the calculations.
- `experiment`: experiment we want to run on the city.

assumes that the `city.streets` has as `prop` called `max_trip_length` (usually set by `cut_and_tag!`),
uses only the vertices with `prop` of `:inside==true`.

# Returns
Tuple with:
- `reachability`: Boolean matrix where `A[i,j]` states if `j` is reachable from `i` while staying below `max_trip_length`.
- `extracted_data`: result of calling `extract_data` with the above values.
"""
function calculate_base_values(city, experiment::FullExperiment)
    verts = filter_vertices(city.streets, :inside, true)
    base_weights = experiment.weight_type(city.streets, 1.0)

    max_trip_length = get_prop(city.streets, :max_trip_length)
    max_shadow_length = ShadowWeight(1.0, 0.0, max_trip_length)
    simple_g = MinistryOfCoolWalks.to_SimpleWeightedDiGraph(city.streets, base_weights)

    base_paths = johnson_shortest_paths(city.streets, base_weights; max_length=max_shadow_length)
    reachability = base_paths.dists .< max_shadow_length

    extracted_data = extract_data(city, 1.0, experiment; reachability=reachability)

    return reachability, extracted_data
end

"""
    extract_data(city, a, experiment; reachability)

takes a city and calculates the relevant data for it.

# Arguments
- `city`: city to calculate values on, assumed to have shadows added already.
- `a`: sun avoidance for weights.
- `experiment`: experiment we want to run on the city (does not use the `sun_aversions` field).
- `reachability`: Boolean matrix where `A[i,j]` states if `j` is reachable from `i` while staying below `max_trip_length`

assumes that the `city.streets` has as `prop` called `max_trip_length` (usually set by `cut_and_tag!`),
uses only the vertices with `prop` of `:inside==true`.

# Returns
A dictionary with the following (String) keys:
- `way_lengths`: Vector of `ShadowWeight`s. Each entry is the sum of the lengths of all shortest paths starting at the entry with destinations reachable according to `reachability`.
- `all_way_length`: sum over `way_lengths`.
- `all_edge_length`: total length of all edges (`ShadowWeight`) (uses `ShadowWeights`, rather than `SymmetricShadowWeights`, no matter the setting in `experiment`).
"""
function extract_data(city, a, experiment; reachability)
    way_lengths = zeros(ShadowWeight, nv(city.streets))  # total length of shortest path with current weights (needed for CoolWalkability)

    max_trip_length = get_prop(city.streets, :max_trip_length)
    w = experiment.weight_type(city.streets, a)
    max_shadow_length = ShadowWeight(a, 0.0, max_trip_length)
    simple_g = MinistryOfCoolWalks.to_SimpleWeightedDiGraph(city.streets, w)

    verts = filter_vertices(city.streets, :inside, true)
    Threads.@threads for n in collect(verts)
        state = early_stopping_dijkstra(simple_g, n; max_length=max_shadow_length)
        way_lengths[n] = mapreduce(*, +, state.dists, @view(reachability[n, :]))
    end
    all_way_length = sum(way_lengths)

    all_edge_length = if w isa ShadowWeights
        sum(Graphs.weights(simple_g))
    elseif experiment.w isa SymmetricShadowWeights
        w_s = ShadowWeights(city.streets, a)
        # not sure if this is strictly necessary, given that non-existent edges should have weight zero(ShadowWeight)
        simple_g_for_shade = MinistryOfCoolWalks.to_SimpleWeightedDiGraph(city.streets, w_s)
        sum(Graphs.weights(simple_g_for_shade))
    end

    return @strdict way_lengths all_way_length all_edge_length
end