using DrWatson
@quickactivate :CoolWalks
using ShadowGraphs, MinistryOfCoolWalks
using CairoMakie
using CoolWalksUtils
using ArchGDAL
# TimeZones, Graphs, MetaGraphs, GeoInterface, ArchGDAL
# using Random

indir_real = datadir("exp_pro", "real_cities")
data_real = load_run(indir_real; exclude_locals=true)
filter!(:city_setup => cs -> cs.network_type == :bike && cs.name == :manhattan, data_real)

indir_grid = datadir("exp_pro", "synthetic_manhattan")
data_grid = load_run(indir_grid; exclude_locals=true)
filter!(:city_setup => cs -> cs isa RectangleCitySetup, data_grid)


mh_city = load_city(data_real.city_setup[1]) |> project_local!
g_city = load_city(data_grid.city_setup[1]) |> project_local!

hist = height_distribution(mh_city)

g_city_samp = let city = load_city(data_grid.city_setup[1])
    resample_heights!(city, hist)
    project_local!(city)
end

mh_city_const = let city = load_city(data_real.city_setup[1])
    set_constant_building_height!(city, first(g_city.buildings.height))
    project_local!(city)
end


function setup_city_axis(f, x, y; flip=false)
    ax_buildings = Axis(f[x, y], autolimitaspect=1.0)
    cbar = Colorbar(f[x+1, y], colorrange=(0.0, 1.0), vertical=false, flipaxis=false)
    colsize!(f.layout, y, Aspect(x + 1, 7))
    return [ax_buildings, cbar]
end

function setup_line_axis(f, x, y)
    ax_lines = Axis(f[x:x+1, y], xticks=TimeTicks([], 2, 4, Time(7)), xminorticks=IntervalsBetween(3))
    xlims!(ax_lines, time_x(Time(6)), time_x(Time(18, 59)))
    return ax_lines
end

function timecut_plot!(ax, times, y; kwargs...)
    between_inds = findbetween(times, Time(0), Time(19))
    scatterlines!(ax, time_x(times)[between_inds], y[between_inds]; kwargs...)
end

f = with_theme(theme_paper_2col(heightwidthratio=0.55), colgap=8, rowgap=8, figure_padding=(2, 7, 2, 2)) do
    f = Figure()
    gridgrey = Makie.current_default_theme().palette.color[][8]
    citygreen = Makie.current_default_theme().palette.color[][3]

    Label(f[0, 1:4][1, 1], text="Manhattan", tellwidth=false, font=:regular, color=citygreen)
    Label(f[0, 1:4][1, 2], text="Grid", tellwidth=false, font=:regular, color=gridgrey)

    Label(f[1:2, 0], text="  Empirical heights", rotation=π / 2, tellheight=false, font=:regular, color=citygreen)
    Label(f[3:4, 0], text="Constant heights", rotation=π / 2, tellheight=false, font=:regular, color=gridgrey)


    Box(f[1:2, 1:2, Makie.GridLayoutBase.Outer()], color=(citygreen, 0.2), strokevisible=false, alignmode=Outside(-4, -2, -6, -1))

    Box(f[3:4, 3:4, Makie.GridLayoutBase.Outer()], color=(gridgrey, 0.25), strokevisible=false, alignmode=Outside(-2, -8, -4, -1))

    Box(f[3:4, 1:2, Makie.GridLayoutBase.Outer()], color=(gridgrey, 0.15), strokevisible=false, alignmode=Outside(-4, -2, -4, -1))
    Box(f[3:4, 1:2, Makie.GridLayoutBase.Outer()], color=(citygreen, 0.1), strokevisible=false, alignmode=Outside(-4, -2, -4, -1))

    Box(f[1:2, 3:4, Makie.GridLayoutBase.Outer()], color=(gridgrey, 0.15), strokevisible=false, alignmode=Outside(-2, -8, -6, -1))
    Box(f[1:2, 3:4, Makie.GridLayoutBase.Outer()], color=(citygreen, 0.1), strokevisible=false, alignmode=Outside(-2, -8, -6, -1))

    rowgap!(f.layout, 3, 11)

    ax1 = setup_city_axis(f, 1, 1)
    ax2 = setup_city_axis(f, 3, 1)
    ax3 = setup_city_axis(f, 1, 4)
    ax4 = setup_city_axis(f, 3, 4)
    caxs = [ax1, ax2, ax3, ax4]


    tax1 = setup_line_axis(f, 1, 2)
    tax2 = setup_line_axis(f, 3, 2)
    tax3 = setup_line_axis(f, 1, 3)
    tax4 = setup_line_axis(f, 3, 3)
    taxs = [tax1, tax2, tax3, tax4]

    Label(f[1, 1, TopLeft()], text="A")
    Label(f[3, 1, TopLeft()], text="B")
    Label(f[1, 3, TopLeft()], text="C")
    Label(f[3, 3, TopLeft()], text="D")

    linkaxes!(taxs...)
    [ax.xticklabelsvisible[] = false for ax in [taxs[1], taxs[3]]]
    [ax.yticklabelsvisible[] = false for ax in [taxs[3], taxs[4]]]
    [ax.ticklabelsvisible[] = false for ax in [ax1[2], ax3[2]]]
    [ax.label[] = "Height [m]" for ax in [ax2[2], ax4[2]]]
    [ax.xlabel[] = "Time of day" for ax in [taxs[2], taxs[4]]]
    [ax.ylabel[] = "CoolWalkability C(t)" for ax in [taxs[1], taxs[2]]]

    r_vis = 500
    center = Point2f(100, 200)
    for ax in getindex.(caxs, 1)
        limits!(ax, -r_vis + center[1], r_vis + center[1], -r_vis + center[2], r_vis + center[2])
        hidedecorations!(ax)
    end

    draw_city_with_heights!(ax1, mh_city, ArchGDAL.buffer(ArchGDAL.createpoint(center...), 2r_vis); color_max=300.0)
    draw_city_with_heights!(ax2, mh_city_const, ArchGDAL.buffer(ArchGDAL.createpoint(center...), 2r_vis), color_max=300.0)

    draw_city_with_heights!(ax3, g_city_samp, ArchGDAL.buffer(ArchGDAL.createpoint(center...), 2r_vis); color_max=300.0)
    draw_city_with_heights!(ax4, g_city, ArchGDAL.buffer(ArchGDAL.createpoint(center...), 2r_vis); color_max=300.0)

    for ax in taxs
        vlines!(ax, time_x([Time(11, 15), Time(13, 34)]), color=:black, linestyle=:dot, linewidth=0.6)
    end

    settings = (markersize=1,)
    let gdf = DataFrames.groupby(filter(:constant_height => !, data_real).result[1], :a)
        for df in gdf
            c = SEQ_COL[df.a[1]]
            timecut_plot!(taxs[1], df.time, df.coolwalkability_global; settings..., color=c, label="α=$(df.a[1])")
        end
    end
    let gdf = DataFrames.groupby(filter(:constant_height => !!, data_real).result[1], :a)
        for df in gdf
            c = SEQ_COL[df.a[1]]
            timecut_plot!(taxs[2], df.time, df.coolwalkability_global; settings..., color=c)
        end
    end
    let gdf = DataFrames.groupby(filter(:constant_height => !, data_grid).result[1], :a)
        for df in gdf
            c = SEQ_COL[df.a[1]]
            timecut_plot!(taxs[3], df.time, df.coolwalkability_global; settings..., color=c)
        end
    end
    let gdf = DataFrames.groupby(filter(:constant_height => !!, data_grid).result[1], :a)
        for df in gdf
            c = SEQ_COL[df.a[1]]
            timecut_plot!(taxs[4], df.time, df.coolwalkability_global; settings..., color=c)
        end
    end

    for ax in taxs
        ylims!(ax, 0.25, 1)
    end

    scatter!(ax2[2].blockscene, [Point2f(45.5, 64.5)], color=:white, marker=:dtriangle, markersize=5)
    scatter!(ax4[2].blockscene, [Point2f(436.4, 64.5)], color=:white, marker=:dtriangle, markersize=5)

    # scatter_on_cb!(ax2[2], g_city.buildings.height[[1]], [0.8], debug=false, color=:red, marker=:dtriangle, markersize=5)
    # scatter_on_cb!(ax4[2], g_city.buildings.height[[1]], [0.8], debug=false, color=:white, marker=:dtriangle, markersize=5)
    Legend(f[5, 2:3], taxs[1], orientation=:horizontal, framecolor=:black, framevisible=true)
    f
end

save(plotsdir("fig4_building_height_distribution_impact.pdf"), f, pt_per_unit=1)
