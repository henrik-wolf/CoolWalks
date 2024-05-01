using DrWatson
@quickactivate :CoolWalks
using CairoMakie
using Graphs, MetaGraphs
using GeoInterface
using ArchGDAL
using IterTools
using CoolWalksUtils, MinistryOfCoolWalks

# using Colors
# using Clustering
# using Random
# using VoronoiCells
# using CoolWalksUtils
# using Setfield

indir_real = datadir("exp_pro", "real_cities")
data_real = load_run(indir_real; exclude_locals=true)
filter!(:constant_height => !, data_real)
transform!(data_real, :city_setup => ByRow(load_city) => :city)
transform!(data_real, :city_setup => ByRow(cs -> string(cs.name)) => :name)
transform!(data_real, :city => ByRow(project_local!) => :city)


function draw_city!(ax, city, center)
    for e in filter_edges(city.streets, :sg_street_geometry)
        street_geometry = get_prop(city.streets, e, :sg_street_geometry)
        if GeoInterface.intersects(center, street_geometry)
            lines!(ax, street_geometry, linewidth=0.6, color=:black)
        end
    end
    polys = [(r.geometry, r.height) for r in eachrow(city.buildings) if GeoInterface.intersects(center, r.geometry)]
    color_max = maximum(i[2] for i in polys)

    for (p, _) in polys
        g = bg(ArchGDAL.buffer(p, 0.3, 1))
        b = poly!(ax, g, color=:grey92, strokewidth=0.0)
        translate!(b, 0, 0, 10)
    end
    ax
end

function draw_shadows!(ax, shadows, center, alpha)
    polys = [bg(r.geometry) for r in eachrow(shadows) if GeoInterface.intersects(center, r.geometry)]
    poly!(ax, polys, color=(:black, alpha))
end

function draw_path!(ax, city, path; color)
    ms = 3.5
    for (v1, v2) in partition(path, 2, 1)
        if has_prop(city.streets, v1, v2, :sg_street_geometry)
            street_geometry = get_prop(city.streets, v1, v2, :sg_street_geometry)
            l = lines!(ax, street_geometry, color=color, linewidth=ms)
            scatter!(ax, get_prop(city.streets, v1, :sg_geometry), markersize=ms, marker=Circle, color=color)
            scatter!(ax, get_prop(city.streets, v2, :sg_geometry), markersize=ms, marker=Circle, color=color)
        end
    end
    ax
end

city_walk = data_real.city[1]
city_bike = data_real.city[2]

begin
    let city = city_walk
        rise, down = get_day_limits(SUMMER_SOLSTICE, city, min_angle=8.0)
        s = add_shadow_intervals!(city, rise + Hour(7) + Minute(30))
        project_local!(city)
    end
    alpha_example = 4.0
    sps_walk = dijkstra_shortest_paths(city_walk.streets, 1543, ShadowWeights(city_walk.streets, alpha_example))
    path_walk = enumerate_paths(sps_walk, 10498)

    let city = city_bike
        rise, down = get_day_limits(SUMMER_SOLSTICE, city, min_angle=8.0)
        s = add_shadow_intervals!(city, rise + Hour(7) + Minute(30))
        project_local!(city)
        project_local!(s)
    end
    sps_bike = dijkstra_shortest_paths(city_bike.streets, 796, ShadowWeights(city_bike.streets, alpha_example))
    path_bike = enumerate_paths(sps_bike, 1530)
end

f = with_theme(theme_paper_2col(heightwidthratio=0.5), figure_padding=(2, 2, 1, 1)) do
    f = Figure()

    Label(f[0, 1:2], "Bicycle network", font=:regular)
    Label(f[0, 4:5], "Sidewalk network", font=:regular)
    Box(f[0:3, 3], width=0)
    # Box(f[3, 3, Bottom()], width=0)

    axs = [Axis(f[i, j], xlabel="Time of day", ylabel="C(t)", xticks=TimeTicks([], 2, 4, nothing), xminorticks=IntervalsBetween(3)) for i in 1:3, j in (4, 2)]
    for (i, df) in enumerate(DataFrames.groupby(data_real, :name))
        for r in eachrow(df)
            j = rownumber(r)
            for df2 in DataFrames.groupby(r.result, :a)
                times = time_x(df2.time)
                lines!(axs[i, j], times, df2.coolwalkability_global, label="α=$(df2.a[1])", color=SEQ_COL[df2.a[1]])
            end
        end
    end
    hidexdecorations!.(axs[1:2, :], ticks=false, minorticks=false)
    xlims!.(axs, time_x([Time(7), Time(19, 55)])...)
    ylims!.(axs, 0, 1)


    # example city axes
    r_vis = 80
    center = Point2f(-160, 620)
    axs_city = [Axis(f[1:3, i], autolimitaspect=1.0) for i in (1, 5)]
    offset_x = 120
    offset_y = 20
    for ax in axs_city
        limits!(ax, -r_vis + center[1] + offset_x, r_vis + center[1] + offset_x, -r_vis + center[2] + offset_y, r_vis + center[2] + offset_y)
        hidedecorations!(ax)
    end
    center_geom = ArchGDAL.buffer(ArchGDAL.createpoint(center...), 2.3r_vis)

    draw_shadows!(axs_city[1], city_bike.shadows, center_geom, 0.3)
    s = draw_shadows!(axs_city[1], city_bike.shadows, center_geom, 0.2)
    translate!(s, 0, 0, 5)
    draw_shadows!(axs_city[2], city_walk.shadows, center_geom, 0.3)
    s = draw_shadows!(axs_city[2], city_walk.shadows, center_geom, 0.2)
    translate!(s, 0, 0, 5)

    draw_city!(axs_city[1], city_bike, center_geom)
    draw_city!(axs_city[2], city_walk, center_geom)

    color = SEQ_COL[alpha_example]
    draw_path!(axs_city[1], city_bike, path_bike; color)
    draw_path!(axs_city[2], city_walk, path_walk; color)

    draw_path!(axs_city[1], city_bike, [344, 796]; color)
    draw_path!(axs_city[2], city_walk, [1543, 3261]; color)

    rotate!(axs_city[1].scene, -deg2rad(10))
    rotate!(axs_city[2].scene, -deg2rad(10))

    # reset some labels
    for (i, l) in enumerate(axs[1, 1].scene.plots)
        if i > 3
            l.label[] = nothing
        end
    end
    for (i, l) in enumerate(axs[1, 2].scene.plots)
        if i <= 3
            l.label[] = nothing
        end
    end

    leggap = 4
    Box(f[3, 1, Bottom()], alignmode=Mixed(top=leggap), color=:white)
    Box(f[3, 5, Bottom()], alignmode=Mixed(top=leggap), color=:white)

    Legend(
        f[3, 1, Bottom()],
        axs[1, 1],
        orientation=:horizontal,
        nbanks=2,
        framecolor=:black,
        padding=(6, 6, -5, -5),
        margin=(0, 0, 0, leggap),
    )

    Legend(
        f[3, 5, Bottom()],
        axs[1, 2],
        orientation=:horizontal,
        nbanks=2,
        framecolor=:black,
        padding=(6, 6, -5, -5),
        margin=(0, 0, 0, leggap),
    )

    textpositions = [
        (time_x(Time(19, 40)), 0.06),
        (time_x(Time(19, 40)), 0.06),
        (time_x(Time(19, 40)), 0.06),
    ]
    for (pos, (i, df)) in zip(textpositions, enumerate(DataFrames.groupby(data_real, :name)))
        for r in eachrow(df)
            j = rownumber(r)
            text!(axs[i, j], pos..., text=uppercasefirst(r.name), fontsize=8, align=(:right, :bottom))
        end
    end

    f
end

save(plotsdir("fig6_network_geometry_matters.pdf"), f)