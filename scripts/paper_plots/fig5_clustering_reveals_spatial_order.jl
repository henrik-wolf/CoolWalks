using DrWatson
@quickactivate :CoolWalks
using CairoMakie, Makie
using ShadowGraphs
using Graphs, MetaGraphs

function prepare_data!(df)
    @chain df begin
        transform!(:city_setup => ByRow(load_city) => :city)
        transform!([:result, :city] => ByRow((r, c) -> prepare_cluster(r, c; nclusters=4)) => :clusters)
        transform!(:clusters => ByRow(clusters_simplified) => :clusters_simplified)
    end
    df
end

mask = circle_mask(0, 0, 790.0)

indir_real = datadir("exp_pro", "real_cities")
data_real = load_run(indir_real; exclude_locals=false)
filter!(:city_setup => c -> c.network_type == :bike, data_real)
prepare_data!(data_real)

indir_grid = datadir("exp_pro", "synthetic_manhattan")
data_grid = load_run(indir_grid; exclude_locals=false)
prepare_data!(data_grid)

function draw_row!(f, ax_array, rn, r, labels, rastersize; cityname=uppercasefirst(string(r.city_setup.name)))
    times = time_x(filter(:a => ==(1.5), r.result).time)

    Label(f[rn, -1], cityname, tellheight=false, rotation=π / 2, font=:regular)

    ax = Axis(f[rn, 1], xticks=TimeTicks([], 2, 4, nothing), xlabel="Time of day", ylabel="C(t)", xminorticks=IntervalsBetween(3))
    Label(f[rn, 0, Top()], text=labels[1, rn], halign=:left)
    Label(f[rn, 1, Top()], text=labels[2, rn], halign=:left)
    Label(f[rn, 2, Top()], text=labels[3, rn], halign=:left)
    ax_array[rn, 1] = ax

    # datashader for points in background
    scatterpoints = Dict([df2.assignment[1] => resample_lines_as_points(df2.timeseries, 800000, pert=0.003) for df2 in DataFrames.groupby(r.clusters, :assignment)])
    cs = current_colors()
    pixels = Dict([k => shade_points(v, resolution=(1200, 800)) for (k, v) in scatterpoints])
    normalize_shaded_arrays(pixels)
    for (k, (px, bb)) in pixels
        cmap = [(cs[k], 0.0), (cs[k], 1.0)]
        x_range = extrema(times)
        y_range = (bb.origin[2], bb.origin[2] + bb.widths[2])
        image!(ax, x_range, y_range, px, colorrange=[0.0, 1.0], colormap=cmap)
    end
    for r2 in eachrow(r.clusters_simplified)
        lines!(ax, times, r2.mean_cwb_time, color=Cycled(r2.assignment))
    end

    # draw clusters
    ax2 = Axis(f[rn, 2], xlabel="cluster")
    ax_array[rn, 2] = ax2
    for df in DataFrames.groupby(r.clusters, :assignment)
        bins = floor(Int, sqrt(nrow(df)))
        hist!(ax2, df.mean_cwb, color=current_colors()[df.assignment[1]], offset=df.assignment[1], direction=:x, bins=bins, normalization=:pdf, scale_to=0.7)
        vlines!(ax2, df.assignment[[1]], color=:black, linewidth=0.5, linestyle=:dash)
    end

    # draw city oberviews
    ax3 = Axis(f[rn, 0], autolimitaspect=1.0)
    ax_array[rn, 3] = ax3
    xlims!(ax3, (-800, 800))
    ylims!(ax3, (-800, 800))
    hidedecorations!(ax3)
    for r2 in eachrow(r.clusters_simplified)
        poly!(ax3, r2.patches, color=Cycled(r2.assignment), markersize=3, rasterize=rastersize)
    end
    for r2 in eachrow(r.clusters)
        for e in outedges(r.city.streets, r2.vertex)
            if has_prop(r.city.streets, e, :sg_street_geometry)
                g = get_prop(r.city.streets, e, :sg_street_geometry)
                p = lines!(ax3, g, linewidth=0.3, color=:black)
                translate!(p, 0, 0, 1)
            end
        end
    end
    p = poly!(ax3, mask, color=:white)
    translate!(p, 0, 0, 2)
end

draw_plot(data_real, data_grid) =
    with_theme(theme_paper_2col(heightwidthratio=0.7), figure_padding=(0, 1, 2, 1), resolution=(340, 360)) do
        rastersize = 10

        f = Figure()
        ax_array = Array{Any}(undef, 4, 3)
        labels = reshape(["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L"], 3, 4)
        for r in eachrow(data_real)
            rn = [2, 1, 3][rownumber(r)]
            draw_row!(f, ax_array, rn, r, labels, rastersize)
        end

        draw_row!(f, ax_array, 4, first(eachrow(data_grid)), labels, rastersize; cityname="Random")

        ylims!.(ax_array[:, 1:2], 0, 1)
        xlims!.(ax_array[:, 1], time_x(Time(7)), time_x(Time(19, 55)))

        xlims!.(ax_array[:, 2], 0.7, 4.99)

        hidexdecorations!.(ax_array[1:3, 1:3], ticks=false, grid=false, minorticks=false)
        hideydecorations!.(ax_array[1:4, 2:3], ticks=false, grid=false, minorticks=false)
        hidexdecorations!.(ax_array[:, 2], ticks=false, grid=false, minorticks=true, ticklabels=false, label=false)
        colsize!(f.layout, 0, Aspect(1, 1.0))
        colsize!(f.layout, 2, Aspect(1, 1.0))
        f
    end

f = draw_plot(
    filter(:constant_height => !, data_real),
    filter([:constant_height, :city_setup] => (ch, cs) -> !ch && cs isa RandomCitySetup, data_grid)
)
save(plotsdir("fig5_clustering_reveals_spatial_order_real_height.pdf"), f)


f = draw_plot(
    filter(:constant_height => identity, data_real),
    filter([:constant_height, :city_setup] => (ch, cs) -> ch && cs isa RandomCitySetup, data_grid)
)
save(plotsdir("fig5_sup_clustering_reveals_spatial_order_constant_height.pdf"), f)


f = let data_real = load_run(indir_real; exclude_locals=false)
    filter!(:city_setup => c -> c.network_type == :walk, data_real)
    prepare_data!(data_real)
    draw_plot(
        filter(:constant_height => !, data_real),
        filter([:constant_height, :city_setup] => (ch, cs) -> !ch && cs isa RandomCitySetup, data_grid)
    )
end
save(plotsdir("fig5_sup_clustering_reveals_spatial_order_walk_networks.pdf"), f)
