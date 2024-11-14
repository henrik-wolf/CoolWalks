function set_constant_building_height!(city)
    project_local!(city)
    mean_height = mean(city.buildings.height, StatsBase.weights(ArchGDAL.geomarea(city.buildings.geometry)))
    set_constant_building_height!(city, mean_height)
    project_back!(city)
    return city
end
function set_constant_building_height!(city, height)
    city.buildings.height .= height
    return city
end

height_distribution(city_setup::AbstractCitySetup) = height_distribution(load_city(city_setup))
function height_distribution(city)
    weights = Weights(ArchGDAL.geomarea(city.buildings.geometry))
    nbins = floor(Int, sqrt(nrow(city.buildings)))
    fit(Histogram, city.buildings.height, weights, nbins=nbins)
end

function resample_heights!(city, height_hist; seed=1)
    @info "resampling heights with seed $seed."
    rng = MersenneTwister(seed)
    hist = normalize(height_hist, mode=:pdf)
    bw = hist.edges[1][2:end] .- hist.edges[1][1:end-1]  # edges is a 1-tuple
    cdf = cumsum(hist.weights .* bw)

    new_samples = rand(rng, nrow(city.buildings))
    bin_ids = [searchsortedfirst(cdf, i) for i in new_samples]
    new_heights = [hist.edges[1][i] + rand(rng) * bw[i] for i in bin_ids]
    city.buildings.height = new_heights
    city
end