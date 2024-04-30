abstract type AbstractExperiment end

function run_experiment_on end

struct FullExperiment <: AbstractExperiment
    weight_type::Type{<:AbstractMatrix{ShadowWeight}}
    day::Date
    sun_aversions::Vector{Float64}
end

# add simpler/other experiments here
