using DrWatson
@quickactivate :CoolWalks
using MinistryOfCoolWalks

experiment = FullExperiment(ShadowWeights, SUMMER_SOLSTICE, AS)
constant_heights = Dict(:manhattan => 40.0, :barcelona => 18.5, :valencia => 16.7)

function run_everything(city_setups, outdir)
    for constant_height in [false]
        for city_setup in city_setups
            city = load_city(city_setup)
            @info typeof(city)
            if constant_height
                set_constant_building_height!(city, constant_heights[city_setup.name])
            end
            result = run_experiment_on(city, experiment)
            observatory = city.observatory
            height = constant_height ? constant_heights[city_setup.name] : missing

            out_data = @strdict city_setup experiment constant_height observatory result height
            safesave(joinpath(outdir, "$(city.name).jld2"), out_data)
        end
    end
end

# MARK: Real cities, real and constant height
let OUTDIR = datadir("exp_pro", "real_cities_large", "buildings")
    # real_city_setups = [MANHATTAN_BIKE, BARCELONA_BIKE, VALENCIA_BIKE, MANHATTAN_WALK, BARCELONA_WALK, VALENCIA_WALK]
    real_city_setups = [MANHATTAN_WALK, BARCELONA_WALK, VALENCIA_WALK]
    run_everything(real_city_setups, OUTDIR)
end

let OUTDIR = datadir("exp_pro", "real_cities_large", "parks")
    @info "saving to $OUTDIR"
    # real_city_setups = [MANHATTAN_PARK_BIKE, BARCELONA_PARK_BIKE, VALENCIA_PARK_BIKE, MANHATTAN_PARK_WALK, BARCELONA_PARK_WALK, VALENCIA_PARK_WALK]
    real_city_setups = [MANHATTAN_PARK_WALK, BARCELONA_PARK_WALK, VALENCIA_PARK_WALK]
    run_everything(real_city_setups, OUTDIR)
end


if false
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
end