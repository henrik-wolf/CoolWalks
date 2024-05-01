function to_web_mercator(geom)
    wm_crs = ArchGDAL.importEPSG(3857)
    ng = ArchGDAL.clone(geom)
    ArchGDAL.createcoordtrans(ArchGDAL.getspatialref(geom), wm_crs) do trans
        ArchGDAL.transform!(ng, trans)
    end
    return ng
end

function to_pretty_path(g, path, offset)
    edgegeoms = [to_web_mercator(get_prop(g, s, d, :sg_street_geometry)) for (s, d) in zip(path[1:end-1], path[2:end]) if has_prop(g, s, d, :sg_street_geometry)]
    edgegeoms = MinistryOfCoolWalks.offset_line.(edgegeoms, offset)

    edgegeoms_coords = map(GeoInterface.coordinates, edgegeoms)
    # build our own set of points, for pretty plotting
    points_new = [edgegeoms_coords[1][1]]
    start_index = 2
    for i in 1:length(edgegeoms)-1
        ep1 = edgegeoms_coords[i]
        ep2 = edgegeoms_coords[i+1]
        if GeoInterface.intersects(edgegeoms[i], edgegeoms[i+1])
            for j in start_index:length(ep1)
                did_intersect = false
                for k in 1:length(ep2)-1
                    if switches_side(points_new[end], ep1[j], ep2[k], ep2[k+1])
                        strech_factor = intersection_distances(points_new[end], ep1[j], ep2[k], ep2[k+1])[1]
                        if 0.0 < strech_factor < 1.0
                            push!(points_new, (1 - strech_factor) * points_new[end] + strech_factor * (ep1[j]))
                            start_index = k + 1
                            did_intersect = true
                            break
                        end
                    end
                end
                if !did_intersect
                    push!(points_new, ep1[j])
                end
            end
        else
            points_new = [points_new; ep1[start_index:end]]
            start_index = 1
        end
    end
    points_new = [points_new; edgegeoms_coords[end][start_index:end]]
    lons = mapfoldl(points -> getindex.(points, 1), vcat, edgegeoms_coords)
    lats = mapfoldl(points -> getindex.(points, 2), vcat, edgegeoms_coords)
    reinterp_crs!(ArchGDAL.createlinestring(lons, lats), ArchGDAL.importEPSG(3857))
end


function partition_on_jumps(lengths, as)
    rl = real_length.(lengths)
    fl = felt_length.(lengths)
    jumps = [0; findall(!=(0), diff(rl)); length(rl) - 1]
    rl = [[rl[a+1:b]; rl[b]] for (a, b) in partition(jumps, 2, 1)]
    fl = [fl[a+1:b+1] for (a, b) in partition(jumps, 2, 1)]
    as_jumped = [as[a+1:b+1] for (a, b) in partition(jumps, 2, 1)]
    return rl, fl, as_jumped
end


function sun_arrows!(ax, angle, center; spread=50, arrowscale=1, start_offset=Point2f(0, 0))
    suncolor = Makie.current_default_theme().palette.color[][2]
    # ax.backgroundcolor[] = colorant"orange"
    narrow = 2
    direction = Point2f(cos(deg2rad(angle)), sin(deg2rad(angle)))
    ort_dir = Point2f(direction[2], -direction[1])
    direction *= 100 * arrowscale
    is = -narrow:narrow
    base_locations = [-direction + start_offset + center + ort_dir * spread * i for i in is]
    directions = [direction * 2cos(i / 2.5) for i in is]
    arrows!(ax, base_locations, directions, lengthscale=1, color=suncolor, align=:origin, linewidth=2.5, arrowsize=10)
end

function draw_city!(ax, city, center)
    for e in filter_edges(city.streets, :sg_street_geometry)
        street_geometry = get_prop(city.streets, e, :sg_street_geometry)
        if GeoInterface.intersects(center, street_geometry)
            # lines!(ax, street_geometry, linewidth=0.1, color=:black)
        end
    end
    for s in city.shadows.geometry
        if GeoInterface.intersects(center, s)
            poly!(ax, bg(s), color=(:black, 1))
        end
    end
    for g in city.buildings.geometry
        if GeoInterface.intersects(center, g)
            poly!(ax, bg(g), color=:lightgrey, strokewidth=0.2, strokecolor=:lightgrey)
        end
    end
    ax
end

findbetween(times, a, b) = findall(t -> a <= t <= b, times)

function cross_marker(s; aspect=1)
    s = s / 2
    return BezierPath([
        MoveTo(Point(s, -s)),
        LineTo(Point(0.5, -s)),
        LineTo(Point(0.5, s)),
        LineTo(Point(s, s)),
        LineTo(Point(s, 0.5 * aspect)),
        LineTo(Point(-s, 0.5 * aspect)),
        LineTo(Point(-s, s)),
        LineTo(Point(-0.5, s)),
        LineTo(Point(-0.5, -s)),
        LineTo(Point(-s, -s)),
        LineTo(Point(-s, -0.5 * aspect)),
        LineTo(Point(s, -0.5 * aspect)),
        ClosePath()
    ])
end


function draw_city_with_heights!(axs, city, center; color_max=nothing)
    for e in filter_edges(city.streets, :sg_street_geometry)
        street_geometry = get_prop(city.streets, e, :sg_street_geometry)
        if GeoInterface.intersects(center, street_geometry)
            # lines!(ax, street_geometry, linewidth=0.1, color=:black)
        end
    end
    polys = [(bg(r.geometry), r.height) for r in eachrow(city.buildings) if GeoInterface.intersects(center, r.geometry)]
    if isnothing(color_max)
        color_max = maximum(i[2] for i in polys)
    end
    poly!(axs[1], getindex.(polys, 1), color=getindex.(polys, 2), colorrange=(0.0, color_max))
    axs[2].colorrange[] = (0.0, color_max)
    # poly!(ax, bg(ArchGDAL.buffer(g, 0.3, 1)), color=:lightgrey, strokewidth=0.0, strokecolor=:lightgrey)
    axs
end

function coords_from_box(cb, x, y)
    box = cb.layoutobservables.computedbbox[]
    vertical = cb.vertical[]
    # box = cb.layoutobservables.computedbbox[]
    data_size = box.widths[vertical ? 2 : 1]
    other_size = box.widths[vertical ? 1 : 2]
    data_coords = vertical ? y : x
    other_coords = vertical ? x : y

    limits = cb.limits[]
    @show limits
    if !isnothing(limits)
        data_coords_px = data_size / (limits[2] - limits[1]) .* (data_coords)
        other_coords_px = other_coords .* other_size
        return if vertical
            Point2f.(other_coords_px .+ box.origin[1], data_coords_px .+ box.origin[2])
        else
            Point2f.(data_coords_px .+ box.origin[1], other_coords_px .+ box.origin[2])
        end
    else
        return [Point2f(100, 0) for i in 1:length(x)]
    end
end

function scatter_on_cb!(cb, x, y; debug=true, kwargs...)
    marker_pos = Observable(coords_from_box(cb, x, y))
    debug_points = Observable([Point2f(0, 0), Point2f(0, 0)])

    scatter!(cb.blockscene, marker_pos; kwargs...)
    if debug
        scatter!(cb.blockscene, debug_points; kwargs...)
    end

    on(cb.layoutobservables.computedbbox) do box
        marker_pos[] = coords_from_box(cb, x, y)
    end
    cb
end

# MARK: Timeticks

# make makie plot times on x axis
function time_x(timestamps::AbstractArray{Time})
    times_ns = @. Dates.Nanosecond(Dates.value(timestamps))
    @. Dates.value((DateTime(0) + round(times_ns, Dates.Millisecond))) - Dates.value(DateTime(0))
end

time_x(time::Time) = time_x([time])[1]

struct TimeTicks
    to_hit::Vector{Time}
    k_min::Int
    k_max::Int
    starttime
end
TimeTicks(to_hit=[]) = TimeTicks(to_hit, 2, 4, nothing)

function Makie.get_ticks(t::TimeTicks, any_scale, ::Makie.Automatic, vmin, vmax)
    # d1 = Dates.epochms2datetime(Int64(vmin))
    # d2 = Dates.epochms2datetime(Int64(vmax))
    d1 = Dates.epochms2datetime(floor(Int, vmin))
    d1 = if isnothing(t.starttime)
        d1
    else
        Date(d1) + t.starttime
    end

    d2 = Dates.epochms2datetime(ceil(Int, vmax))
    dateticks, dateticklabels = optimize_datetime_ticks(Dates.value(d1), Dates.value(d2), k_min=t.k_min, k_max=t.k_max)

    dateticks_corrected = dateticks .- Dates.value(DateTime(0))
    to_hits_corrected = time_x(t.to_hit)

    dateticks_all = [dateticks_corrected; to_hits_corrected]

    ticktimes = Time.(Dates.epochms2datetime.(dateticks_all))
    ticktimes_str = Dates.format.(ticktimes, "HH:MM")
    return dateticks_all, ticktimes_str
end