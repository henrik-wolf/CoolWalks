using DrWatson
@quickactivate :CoolWalks
using ShadowGraphs, MinistryOfCoolWalks
using CairoMakie
using CoolWalksUtils
using ArchGDAL

indir_real = datadir("exp_pro", "real_cities")
data_real = load_run(indir_real; exclude_locals=true)
filter!([:city_setup, :constant_height] => (cs, ch) -> cs.network_type == :bike && cs.name == :valencia && !ch, data_real)

va1, va2 = let
    city1 = load_city(data_real.city_setup[1])
    city2 = load_city(data_real.city_setup[1])
    times = let
        rise, down = get_day_limits(SUMMER_SOLSTICE, city1, min_angle=8.0)
        rise -= Minute(30)
        down += Minute(30)
        rise:Minute(15):down
    end
    s1 = add_shadow_intervals!(city1, DateTime(2023, 6, 21, 11, 30))
    s2 = add_shadow_intervals!(city2, DateTime(2023, 6, 21, 14, 20))
    project_local!(city1)
    project_local!(city2)
    city1, city2
end

begin
    f = with_theme(theme_paper_2col(heightwidthratio=0.4), figure_padding=3) do
        f = Figure()
        gridgrey = Makie.current_default_theme().palette.color[][8]
        citygreen = Makie.current_default_theme().palette.color[][3]
        ax1 = Axis(f[1, -1], xticks=TimeTicks([], 2, 5, Time(7)), ylabel="CoolWalkability C(t)", xlabel="Time of day", xminorticks=IntervalsBetween(3))
        ax2 = Axis(f[1, 0], xlabel="Shadow fraction S(t)", yticklabelsvisible=false)
        linkyaxes!(ax1, ax2)

        Label(f[1, -1, Top()], text="A", halign=:left)
        Label(f[1, 0, Top()], text="B", halign=:left)

        g = GridLayout(f[1, 1])
        ax3 = Axis(g[1, 1], autolimitaspect=1)
        ax4 = Axis(g[2, 1], autolimitaspect=1)

        hidedecorations!.([ax3, ax4])
        colsize!(f.layout, 0, Aspect(1, 1.0))
        colsize!(f.layout, 1, Aspect(1, 2.3 / 3))


        r_vis = 300
        center = Point2f(50, 200)
        for ax in [ax3, ax4]
            limits!(ax, -r_vis + center[1], r_vis + center[1], -r_vis + center[2], r_vis + center[2])
        end

        visible_circle = ArchGDAL.buffer(ArchGDAL.createpoint(center...), r_vis * 2)

        draw_city!(ax3, va1, visible_circle)
        sun_arrows!(ax3, 165.5, center; spread=140, arrowscale=3, start_offset=Point2f(380, -20))

        draw_city!(ax4, va2, visible_circle)
        sun_arrows!(ax4, 85.5, center; spread=180, arrowscale=2, start_offset=Point2f(-40, -280))

        limits!(ax2, 0, 1, 0, 1)

        ylims!(ax1, 0.25, 1.02)

        vlines!(ax1, time_x([Time(11, 30), Time(14, 20)]), color=:black, linestyle=:dot, linewidth=0.6)

        for df in DataFrames.groupby(data_real.result[1], :a)
            df.a[1] != 1.5 && continue
            between_inds = findbetween(df.time, Time(0), Time(22))
            lines!(ax1, time_x(df.time[between_inds]), df.coolwalkability_global[between_inds], color=Cycled(3), label="Valencia", linewidth=1)
            lines!(ax2, df.shadow_fraction_global[between_inds], df.coolwalkability_global[between_inds], color=Cycled(3), label="Valencia", linewidth=1)
        end

        ax1.xminorticks[] = time_x(Time(6):Hour(1):Time(21, 10))
        xlims!(ax1, time_x(Time(6, 50)), time_x(Time(21, 10)))

        labels = ["VH1", "VH2"]

        for (i, label) in enumerate(labels)
            Label(g[i, 1, Left()], text=label, padding=(0, 0, 0, 0), rotation=π / 2, font=:regular)
        end
        for (i, (color, label)) in enumerate(zip([citygreen, gridgrey], ["Valencia"]))
            Label(g[1, i, Top()], text=label, padding=(0, 0, 0, 0), color=color, rotation=0, font=:regular)
        end
        Label(f[1, 1, TopLeft()], text="C", rotation=0)


        pos_ax1 = [
            (time_x(Time(11, 24)), 0.1),
            (time_x(Time(14, 14)), 0.1)
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

        sfs = ([133, 133] .- 2 * 9) ./ (133 + 133)
        cwbs = [133, 133] .* ([133, 133] .- 2 * 9) ./ (2 * 133 * 133)

        f
    end
end

save(plotsdir("fig3_sup_valcencia_analytical.pdf"), f, pt_per_unit=1)