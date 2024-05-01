using DrWatson
@quickactivate :CoolWalks
using ShadowGraphs, MinistryOfCoolWalks
using CairoMakie
using CoolWalksUtils
using ArchGDAL

indir_real = datadir("exp_pro", "real_cities")
data_real = load_run(indir_real; exclude_locals=true)
filter!([:city_setup, :constant_height] => (cs, ch) -> cs.network_type == :bike && cs.name == :manhattan && !ch, data_real)

indir_grid = datadir("exp_pro", "synthetic_manhattan")
data_grid = load_run(indir_grid; exclude_locals=true)
filter!([:city_setup, :constant_height] => (cs, ch) -> cs isa RectangleCitySetup && ch, data_grid)

mh1, mh2 = let
    city1 = load_city(data_real.city_setup[1])
    city2 = load_city(data_real.city_setup[1])
    times = let
        rise, down = get_day_limits(SUMMER_SOLSTICE, city1, min_angle=8.0)
        rise -= Minute(30)
        down += Minute(30)
        rise:Minute(15):down
    end
    s1 = add_shadow_intervals!(city1, times[22] + Minute(7))
    s2 = add_shadow_intervals!(city2, times[32] + Minute(5))
    project_local!(city1)
    project_local!(city2)
    city1, city2
end

grid1, grid2 = let
    city1 = load_city(data_grid.city_setup[1])
    city2 = load_city(data_grid.city_setup[1])
    times = let
        rise, down = get_day_limits(SUMMER_SOLSTICE, city1, min_angle=8.0)
        rise -= Minute(30)
        down += Minute(30)
        rise:Minute(15):down
    end
    s1 = add_shadow_intervals!(city1, times[22] + Minute(7))
    s2 = add_shadow_intervals!(city2, times[32] + Minute(5))
    project_local!(city1)
    project_local!(city2)
    city1, city2
end

begin
    f = with_theme(theme_paper_2col(heightwidthratio=0.4), figure_padding=3) do
        f = Figure()
        gridgrey = Makie.current_default_theme().palette.color[][8]
        citygreen = Makie.current_default_theme().palette.color[][3]
        ax1 = Axis(f[1, -1], xticks=TimeTicks([], 2, 4, Time(7)), xlabel="Time of day", ylabel="CoolWalkability C(t)")
        ax2 = Axis(f[1, 0], xlabel="Shadow fraction S(t)", yticklabelsvisible=false)
        linkyaxes!(ax1, ax2)

        Label(f[1, -1, Top()], text="A", halign=:left)
        Label(f[1, 0, Top()], text="B", halign=:left)

        g = GridLayout(f[1, 1])
        ax3 = Axis(g[1, 1], autolimitaspect=1)
        ax4 = Axis(g[2, 1], autolimitaspect=1)

        ax5 = Axis(g[1, 2], autolimitaspect=1)
        ax6 = Axis(g[2, 2], autolimitaspect=1)

        hidedecorations!.([ax3, ax4, ax5, ax6])
        colsize!(f.layout, 0, Aspect(1, 1.0))
        colsize!(f.layout, 1, Aspect(1, 2.3 / 3))


        r_vis = 400
        center = Point2f(250, 360)
        for ax in [ax3, ax4, ax5, ax6]
            limits!(ax, -r_vis + center[1], r_vis + center[1], -r_vis + center[2], r_vis + center[2])
        end

        visible_circle = ArchGDAL.buffer(ArchGDAL.createpoint(center...), r_vis * 2)


        draw_city!(ax3, mh1, visible_circle)
        sun_arrows!(ax3, 61.0 + 90.0, center; spread=160, arrowscale=2.5, start_offset=Point2f(265, -240))

        draw_city!(ax4, mh2, visible_circle)
        sun_arrows!(ax4, 61.0, center; spread=270, arrowscale=3.5, start_offset=Point2f(-260, -260))

        draw_city!(ax5, grid1, visible_circle)
        sun_arrows!(ax5, 61.0 + 90.0, center; spread=160, arrowscale=2.5, start_offset=Point2f(265, -235))

        draw_city!(ax6, grid2, visible_circle)
        sun_arrows!(ax6, 61.0, center; spread=270, arrowscale=3.5, start_offset=Point2f(-80, -320))

        limits!(ax2, 0, 1, 0, 1)

        ylims!(ax1, 0.25, 1.02)

        vlines!(ax1, time_x([Time(11, 15), Time(13, 34)]), color=:black, linestyle=:dot, linewidth=0.6)

        for df in DataFrames.groupby(data_real.result[1], :a)
            df.a[1] != 1.5 && continue
            between_inds = findbetween(df.time, Time(0), Time(19))
            lines!(ax1, time_x(df.time[between_inds]), df.coolwalkability_global[between_inds], color=Cycled(3), label="Manhattan", linewidth=1)
            lines!(ax2, df.shadow_fraction_global[between_inds], df.coolwalkability_global[between_inds], color=Cycled(3), label="Manhattan", linewidth=1)
        end
        for df in DataFrames.groupby(data_grid.result[1], :a)
            df.a[1] != 1.5 && continue
            between_inds = findbetween(df.time, Time(0), Time(19))
            p = scatterlines!(ax1, time_x(df.time[between_inds]), df.coolwalkability_global[between_inds], color=Cycled(8), markersize=4, label="Grid", marker=:rect, linewidth=1)
            scatterlines!(ax2, df.shadow_fraction_global[between_inds], df.coolwalkability_global[between_inds], color=Cycled(8), markersize=4, label="Grid", marker=:rect, linewidth=1)
        end

        ax1.xminorticks[] = time_x(Time(6):Hour(1):Time(19))
        xlims!(ax1, time_x(Time(6)), time_x(Time(18, 59)))


        labels = ["MH1", "MH2"]

        for (i, label) in enumerate(labels)
            Label(g[i, 1, Left()], text=label, padding=(0, 0, 0, 0), rotation=π / 2, font=:regular)
        end
        for (i, (color, label)) in enumerate(zip([citygreen, gridgrey], ["Manhattan", "Grid"]))
            Label(g[1, i, Top()], text=label, padding=(0, 0, 0, 0), color=color, rotation=0, font=:regular)
        end
        Label(f[1, 1, TopLeft()], text="C", rotation=0)


        pos_ax1 = [
            (time_x(Time(11, 5)), 0.1),
            (time_x(Time(13, 24)), 0.1)
        ]
        for (t, pos) in zip(labels, pos_ax1)
            text!(ax1, pos..., text=t, align=(:right, :center), fontsize=8)
        end

        pos_ax2 = [[
                (0.14, 0.24, citygreen),
                (0.10, 0.46, gridgrey)
            ],
            [
                (0.39, 0.29, citygreen),
                (0.75, 0.37, gridgrey)
            ]]
        for (t, poss) in zip(labels, pos_ax2)
            for pos in poss
                text!(ax2, pos[1], pos[2], text=t, align=(:center, :center), color=pos[3], fontsize=8)
            end
        end

        sfs = ([80, 270] .- 2 * 11.5) ./ (80 + 270)
        cwbs = [270, 80] .* ([80, 270] .- 2 * 11.5) ./ (2 * 80 * 270)

        scatter!(ax2, sfs, cwbs, marker=cross_marker(0.04, aspect=1), color=:black, markersize=15, label="Analytical")
        Legend(f[1, -1], ax1, framevisible=true, tellwidth=false, tellheight=false, valign=:bottom, halign=:right, margin=(3, 3, 10, 3))
        Legend(f[1, 0], ax2, framevisible=true, tellwidth=false, tellheight=false, valign=:bottom, halign=:right, margin=(3, 3, 6, 3))
        f
    end
end

save(plotsdir("fig3_manhattan_analytical.pdf"), f, pt_per_unit=1)