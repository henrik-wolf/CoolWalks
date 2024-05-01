using DrWatson
@quickactivate :CoolWalks
using CairoMakie
using MinistryOfCoolWalks
using Graphs, MetaGraphs
# using TileProviders, Tyler, MapTiles
using ArchGDAL, Extents, GeoInterface
using CoolWalksUtils
using Setfield

function paths_and_lengths(g, as, v_start, v_end)
    path_states = map(as) do a
        dijkstra_shortest_paths(g, v_start, ShadowWeights(g, a))
    end
    path_lengths = [path_state.dists[v_end] for path_state in path_states]
    unique_indices = [findfirst(l -> real_length(l) == rl, path_lengths) for rl in unique(real_length.(path_lengths))]
    paths = [enumerate_paths(path_state, v_end) for path_state in path_states[unique_indices]]
    paths, path_lengths
end

simple = let city = build_simple_city()
    max_trip_length = 800.0
    s = add_shadow_intervals!(city, [0.8, -1.3, 0.7])
    project_local!(city)
    city
end

valencia = let
    city = load_city(@set VALENCIA_BIKE.pedestrianize = false)
    times = let
        rise, down = get_day_limits(SUMMER_SOLSTICE, city, min_angle=8.0)
        rise -= Minute(30)
        down += Minute(30)
        rise:Minute(15):down
    end
    s = add_shadow_intervals!(city, times[20])
    city
end

as = 1:0.1:6
v_start_osm = 4579851920
v_end_osm = 7596340263
v_start = first(filter_vertices(valencia.streets, :sg_osm_id, v_start_osm))
v_end = first(filter_vertices(valencia.streets, :sg_osm_id, v_end_osm))

paths, lengths = paths_and_lengths(valencia.streets, as, v_start, v_end)

function draw_simple!(ax1, ax2)
    hidedecorations!(ax1)

    streets = []
    edges = []
    lengths = []
    sw = 2.0

    # edges
    for e in filter_edges(simple.streets, :sg_helper, false)
        length(edges) >= 3 && continue
        sg = ArchGDAL.buffer(get_prop(simple.streets, e, :sg_street_geometry), sw)
        push!(streets, sg)
        push!(edges, e)
        push!(lengths, ArchGDAL.geomarea(sg))
    end
    order = sortperm(lengths, rev=true)
    for (i, sg) in zip(order, streets[order])
        poly!(ax1, sg, color=Cycled(i))
    end

    # shadows
    for s in simple.shadows.geometry
        poly!(ax1, bg(s), color=(:black, 0.4))
    end

    all_shadows = reduce(ArchGDAL.union, simple.shadows.geometry)
    for street in streets
        shadowgeom = ArchGDAL.intersection(all_shadows, street)
        if !ArchGDAL.isempty(shadowgeom)
            # poly!(ax1, bg(ArchGDAL.buffer(shadowgeom, 0.1sw)), color=(:black, 0.3), strokewidth=0)
        end
    end

    # vertices
    for v in filter_vertices(simple.streets, :sg_helper, false)
        scatter!(ax1, get_prop(simple.streets, v, :sg_geometry), markersize=12, color=Cycled(4))
    end

    # buildings
    for b in simple.buildings.geometry
        poly!(ax1, bg(b), color=:lightgrey)
    end

    labels = ["1", "2", "3"]
    positions = [
        (83, -28),
        (79, 16),
        (86, 105)
    ]
    for (t, pos) in zip(labels, positions)
        text!(ax1, pos..., text=t)
    end

    # ######### ax2 #######
    amax = 6.0
    as = 1:0.03:amax
    simple_paths, simple_lengths = paths_and_lengths(simple.streets, as, 1, 2)
    jump_data = partition_on_jumps(simple_lengths, as)
    jump_data = (jump_data[1] / 1000, jump_data[2] / 1000, jump_data[3])

    sw_1 = ShadowWeights(simple.streets, 1.0)
    sw_max = ShadowWeights(simple.streets, amax)

    sws_1 = [sw_1[src(e), dst(e)] for e in edges]
    sws_max = [sw_max[src(e), dst(e)] for e in edges[1:3]]
    i1 = (sws_1[1].shade - sws_1[2].shade) / (sws_1[2].sun - sws_1[1].sun)
    i2 = (sws_1[2].shade - sws_1[3].shade) / (sws_1[3].sun - sws_1[2].sun)
    lows = [1, i1, i2]
    highs = [i1, i2, amax]

    colors = [(i, 0.2) for i in Makie.current_default_theme().palette.patchcolor[]]


    max_experienced = maximum(vcat(jump_data[2]...))

    vspan!(ax2, lows, highs, color=colors[1:3])
    for (t, rl, fl, x) in zip(labels, jump_data[1], jump_data[2], (lows .+ highs) ./ 2)
        text!(ax2, x, max_experienced, text=t, align=(:center, :top))
    end

    v_off = 0.02
    text!(ax2, lows[2] / 2 + highs[2] / 2, v_off + mean(jump_data[2][2]), text="Experienced", rotation=16.5 * pi / 100, align=(:center, :bottom))
    text!(ax2, lows[2] / 2 + highs[2] / 2, v_off + mean(jump_data[1][2]), text="Physical", align=(:center, :bottom))

    for (rl, fl, as, label) in zip(jump_data..., labels)
        rl_line = lines!(ax2, as, rl, label=label, linestyle=:dash)
        lines!(ax2, as, fl, color=rl_line.color)
    end
    xlims!(ax2, 1, amax)
end

function draw_valencia!(ax1, ax2)
    hidedecorations!(ax1)

    for (i, path) in enumerate(paths)
        pathgeom = to_pretty_path(valencia.streets, path, [0.0, 7, 0, -7, 14][i])
        line_p = lines!(ax1, pathgeom, label=string(i))
        translate!(line_p, 0, 0, 1)
    end
    axislegend(ax1, framevisible=true)
    Makie.reset_limits!(ax1)
    limits!(ax1, ax1.finallimits[])

    viewext = ax1.finallimits[] |> Extents.extent

    b_visible = filter(:geometry => g -> Extents.intersects(GeoInterface.extent(g |> to_web_mercator), viewext), valencia.buildings)
    s_visible = filter(:geometry => g -> Extents.intersects(GeoInterface.extent(g |> to_web_mercator), viewext), valencia.shadows)
    for s in s_visible.geometry
        poly!(ax1, bg(to_web_mercator(s)), color=(:black, 0.4)).rasterize = 2
    end
    for b in b_visible.geometry
        poly!(ax1, to_web_mercator(b), color=:lightgrey).rasterize = 2
    end

    for v in paths[1][[1, end]]
        p = scatter!(ax1, to_web_mercator(get_prop(valencia.streets, v, :sg_geometry)), color=Cycled(length(paths) + 1), markersize=10)
        translate!(p, 0, 0, 2)
    end

    data_ax2 = partition_on_jumps(lengths, as)
    data_ax2 = (data_ax2[1] / 1000.0, data_ax2[2] / 1000.0, data_ax2[3])
    as_jump = last(data_ax2)

    max_experienced = maximum(vcat(data_ax2[2]...))

    # colors = [(i, 0.15) for i in Makie.current_default_theme().palette.patchcolor[]]

    lows = [i[1] for i in as_jump]
    highs = [i[end] for i in as_jump]

    for (l, h) in zip(lows, highs)
        bg = vspan!(ax2, [l], [h])
        bg.color[] = (bg.color[], 0.13)
    end
    for (i, (rl, fl, y)) in enumerate(zip(data_ax2[1], data_ax2[2], (lows .+ highs) ./ 2))
        text!(ax2, y, max_experienced .- 0.08, text=string(i), align=(:center, :top))
    end

    v_off = 0.06
    n = 3
    text!(ax2, lows[n] / 2 + highs[n] / 2, v_off + mean(data_ax2[2][n]), text="Experienced", rotation=15 * pi / 100, align=(:center, :bottom))
    text!(ax2, lows[n] / 2 + highs[n] / 2, v_off + mean(data_ax2[1][n]), text="Physical", align=(:center, :bottom))

    for (i, (rl, fl, as)) in enumerate(zip(data_ax2...))
        rl_line = lines!(ax2, as, rl, linestyle=:dash, color=Cycled(i))
        lines!(ax2, as, fl, color=Cycled(i), label=string(i))
    end
    # axislegend(ax2, position=:lt, framevisible=true)
    xlims!(ax2, extrema(as)...)
    ylims!(ax2, nothing, 3.9)
end


f = with_theme(theme_paper_2col(heightwidthratio=0.7), figure_padding=(1, 3, 1, 0)) do
    f = Figure()
    ax1 = Axis(f[1, 1], autolimitaspect=1.0)
    ax2 = Axis(f[1, 2], ylabel="Length [km]", xlabel="α")
    ax3 = Axis(f[2, 1], autolimitaspect=1.0)
    ax4 = Axis(f[2, 2], ylabel="Length [km]", xlabel="α", ytickformat="{:.1f}")

    hidexdecorations!(ax2)
    linkxaxes!(ax2, ax4)

    draw_simple!(ax1, ax2)
    draw_valencia!(ax3, ax4)

    # Label(f[1, 1, TopLeft()], text="A", padding=(0, 10, 0, 0))
    padtup = (0, 0, 0, 0)
    Label(f[1, 1, TopLeft()], text="A")#, valign=:top, padding=padtup)
    Label(f[1, 2, TopLeft()], text="B")#, valign=:top, padding=padtup)
    Label(f[2, 1, TopLeft()], text="C")#, valign=:top, padding=padtup)
    Label(f[2, 2, TopLeft()], text="D")#, valign=:top, padding=padtup)
    f
end

save(plotsdir("fig1_alpha_changes_paths.png"), f, px_per_unit=5)