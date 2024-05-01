function do_clustering(data, a=1.5; outlier_dist, nclusters, seed=1)
    data_array = hcat(filter(:a => ==(a), data).coolwalkability_local...)
    clean_verts = [i for (i, r) in enumerate(eachrow(data_array)) if mapreduce(!isnan, &, r)]
    clean_data = data_array[clean_verts, :]

    outlier_clusters = dbscan(clean_data', outlier_dist)
    largest_index = argmax(outlier_clusters.counts)
    fraction_in_largest = outlier_clusters.counts[largest_index] / sum(outlier_clusters.counts)
    dropping_amount = sum(outlier_clusters.counts) - outlier_clusters.counts[largest_index]
    @info "$(round(fraction_in_largest*100, digits=2))% of all nodes are in the largest cluster. (dropping $(dropping_amount) out of $(sum(outlier_clusters.counts)))"

    inlier_indices = findall(==(largest_index), outlier_clusters.assignments)

    inlier_data = clean_data[inlier_indices, :]
    inlier_vertices = clean_verts[inlier_indices]
    rng = MersenneTwister(seed)
    inlier_vertices, kmeans(inlier_data', nclusters, rng=rng), mean(inlier_data, dims=2) |> vec, inlier_data
end


function city_to_voronoi(city)
    project_local!(city)
    points = [get_prop(city.streets, i, :sg_geometry) for i in vertices(city.streets)]
    extent = geoiter_extent(points)
    buffer = 400
    p1 = Point2f(extent.X[1] - buffer, extent.Y[1] - buffer)
    p2 = Point2f(extent.X[2] + buffer, extent.Y[2] + buffer)
    bbox = VoronoiCells.Rectangle(p1, p2)
    pointsgeom = [Point2f(GeoInterface.coordinates(p)...) for p in points]
    distarr = let arr = [norm(i - j) for i in pointsgeom, j in pointsgeom]
        for i in 1:size(arr, 1)
            arr[i, i] = 888.88
        end
        arr
    end
    close_ones = filter(a -> a[1] < a[2], findall(<(0.00001), distarr))
    @show close_ones
    new_indices = [i for i in vertices(city.streets)]
    for c in close_ones
        new_indices[c[1]] = c[2]
    end
    new_shorter = unique(new_indices)
    cells = voronoicells(pointsgeom[new_shorter], bbox)
    [cells.Cells[findfirst(==(new_indices[i]), new_shorter)] for i in vertices(city.streets)]
end

function prepare_cluster(data, city=nothing, a=1.5; outlier_dist=0.5, nclusters=4, seed=1)
    verts, clusters, coolwalkability_means, time_data = do_clustering(data, a; outlier_dist, nclusters, seed)
    clusterdf = if city == nothing
        DataFrame(vertex=verts, mean_cwb=coolwalkability_means, assignment=clusters.assignments, timeseries=eachrow(time_data))
    else
        city_cells = city_to_voronoi(city)[verts]
        DataFrame(vertex=verts, mean_cwb=coolwalkability_means, assignment=clusters.assignments, patch=city_cells, timeseries=eachrow(time_data))
    end

    clusterdf = @chain clusterdf begin
        DataFrames.groupby(:assignment)
        combine(:, :mean_cwb => mean)
    end
    means = sort(unique(clusterdf.mean_cwb_mean))
    transform!(clusterdf, :mean_cwb_mean => ByRow(m -> findfirst(==(m), means)) => :assignment)
end

function to_cwb_range(ts)
    tarr = hcat(ts...)
    mean_cwb = mean(tarr, dims=2) |> vec
    std_cwb = std(tarr, dims=2) |> vec
    extrema_cwb = extrema(tarr, dims=2) |> vec
    return [(mean_cwb, std_cwb, getindex.(extrema_cwb, 1), getindex.(extrema_cwb, 2))]
end

clusters_simplified(df) = combine(DataFrames.groupby(df, :assignment),
    :vertex => (a -> [a]) => :vertices,
    :mean_cwb => (a -> [a]) => :mean_cwbs,
    :patch => (a -> [a]) => :patches,
    :mean_cwb_mean => first => :mean_cwb_mean,
    :timeseries => to_cwb_range => [:mean_cwb_time, :std_cwb_time, :min_cwb_time, :max_cwb_time]
)

