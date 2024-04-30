abstract type AbstractExperiment end

struct FullExperiment <: AbstractExperiment
    weight_type::Type{<:AbstractMatrix{ShadowWeight}}
    day::Date
    sun_aversions::Vector{Float64}
end

# add simpler/other experiments here
