using DrWatson
@quickactivate :CoolWalks
using CairoMakie
using Graphs, MetaGraphs
using MinistryOfCoolWalks

manhattan = load_city(MANHATTAN_BIKE)
experiment = FullExperiment(ShadowWeights, SUMMER_SOLSTICE, AS)

reachability, _ = CoolWalks.calculate_base_values(manhattan, experiment)

f = with_theme(theme_paper(heightwidthratio=1)) do
    f = Figure()
    ax = Axis(f[1, 1], autolimitaspect=1.0, spinewidth=0)
    hidedecorations!(ax)
    for e in filter_edges(manhattan.streets, :sg_geometry_base)
        lines!(ax, get_prop(manhattan.streets, e, :sg_geometry_base) |> to_web_mercator, color=:black, linewidth=1)
    end
    ms = 4.5
    ms2 = 5.0
    sw = 1.5
    insides = filter_vertices(manhattan.streets, :inside, true) |> collect
    for v in insides
        c = :orange
        p = scatter!(ax, get_prop(manhattan.streets, v, :sg_geometry) |> to_web_mercator, color=Cycled(2), markersize=ms, label=L"V_{src}")
        translate!(p, 0, 0, 1)
    end
    for v in vertices(manhattan.streets)
        v in insides && continue
        c = :grey
        p = scatter!(ax, get_prop(manhattan.streets, v, :sg_geometry) |> to_web_mercator, color=Cycled(8), markersize=ms, label=L"V \setminus \! V_{src}")
        translate!(p, 0, 0, 1)
    end

    # circles
    n = 110
    p = scatter!(ax, get_prop(manhattan.streets, insides[n], :sg_geometry) |> to_web_mercator, color=Cycled(4), markersize=8, label=L"i")
    translate!(p, 0, 0, 1)
    for v in findall(reachability[insides[n], :])
        p = scatter!(ax, get_prop(manhattan.streets, v, :sg_geometry) |> to_web_mercator, color=Cycled(1), markersize=ms2 + sw, strokewidth=sw, label=L"V_{dst}(i)")
        p.strokecolor[] = p.color[]
        p.color[] = (:white, 0.0)
    end
    a = axislegend(ax, merge=true, framevisible=true, position=:lb)
    f
end
save(plotsdir("fig2_sum_setup.pdf"), f, pt_per_unit=1)