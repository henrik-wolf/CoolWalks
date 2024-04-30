using DrWatson
@quickactivate :CoolWalks
using MinistryOfCoolWalks

experiment = FullExperiment(ShadowWeights, SUMMER_SOLSTICE, AS)

# MARK: Real cities, real and constant height
let OUTDIR = datadir("exp_pro", "real_cities")
    real_city_setups = [MANHATTAN_BIKE, MANHATTAN_WALK, BARCELONA_BIKE, BARCELONA_WALK, VALENCIA_BIKE, VALENCIA_WALK]
    for city_setup in real_city_setups
        for constant_height in [true, false]
            city = load_city(city_setup)
            if constant_height && city_setup.name == :manhattan
                set_constant_building_height!(city, 71.0)
            elseif city_setup.name in [:barcelona, :valencia]
                set_constant_building_height!(city, 20.0)
            end
            result = run_experiment_on(city, experiment)
            observatory = city.observatory

            out_data = @strdict city_setup experiment constant_height observatory result
            safesave(joinpath(OUTDIR, "$(city.name).jld2"), out_data)
        end
    end
end

# MARK: Manhattan synthetic cities
let OUTDIR = datadir("exp_pro", "synthetic_manhattan")
    synthetic_city_setups = [MANHATTAN_GRID, MANHATTAN_RANDOM]

    empirical_height_hist = height_distribution(MANHATTAN_BIKE)
    for city_setup in synthetic_city_setups
        for constant_height in [true, false]
            city = load_city(city_setup)
            if !constant_height
                resample_heights!(city, empirical_height_hist)
            end
            result = run_experiment_on(city, experiment)
            observatory = city.observatory

            out_data = @strdict city_setup experiment constant_height observatory result
            safesave(joinpath(OUTDIR, "$(city.name).jld2"), out_data)
        end
    end
end

# MARK: Barcelona synthetic cities
let OUTDIR = datadir("exp_pro", "synthetic_barcelona")
    empirical_height_hist = height_distribution(BARCELONA_BIKE)

    for city_setup in [BARCELONA_GRID]
        for constant_height in [false, true]
            city = load_city(city_setup)
            if !constant_height
                resample_heights!(city, empirical_height_hist)
            end
            result = run_experiment_on(city, experiment)
            observatory = city.observatory

            out_data = @strdict city_setup experiment constant_height observatory result
            safesave(joinpath(OUTDIR, "$(city.name).jld2"), out_data)
        end
    end
end