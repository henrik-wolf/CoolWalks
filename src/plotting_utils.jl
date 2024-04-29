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