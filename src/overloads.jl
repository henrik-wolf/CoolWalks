function empty_buildings(city)
    df = DataFrame(:geometry => [], :id => [], :height => [])
    metadata!(df, "observatory", city.observatory, style=:note)
end

"""
    MinistryOfCoolWalks.correct_centerlines!(city::AbstractCityDataset, args...)

corrects the centerlines of the graph in `city`. Takes the same arguments as the methods in `MinistryOfCoolWalks`. If there are no buildings in the city,
an empty dataframe is used.
"""
MinistryOfCoolWalks.correct_centerlines!(city::AbstractCityDataset, args...) = correct_centerlines!(city.streets, city.buildings, args...)
MinistryOfCoolWalks.correct_centerlines!(city::ST_City, args...) = correct_centerlines!(city.streets, empty_buildings(city), args...)


# MARK: shadow intervals
function MinistryOfCoolWalks.add_shadow_intervals!(city::AbstractCityDataset, datetime::DateTime)
    sp = local_sunpos(datetime, city)
    add_shadow_intervals!(city, sp)
end

function MinistryOfCoolWalks.add_shadow_intervals!(city::SB_City, sunpos::AbstractVector)
    s = CompositeBuildings.cast_shadows(city.buildings, sunpos)
    add_shadow_intervals!(city.streets, s; clear_old_shadows=true)
    city.shadows = s
    return s
end

function MinistryOfCoolWalks.add_shadow_intervals!(city::ST_City, sunpos::AbstractVector)
    s = TreeLoaders.cast_shadows(city.trees, sunpos)
    add_shadow_intervals!(city.streets, s; clear_old_shadows=true)
    city.shadows = s
    return s
end

function MinistryOfCoolWalks.add_shadow_intervals!(city::SBT_City, sunpos::AbstractVector)
    s1 = CompositeBuildings.cast_shadows(city.buildings, sunpos)
    add_shadow_intervals!(city.streets, s1; clear_old_shadows=true)
    city.building_shadows = s1

    s2 = TreeLoaders.cast_shadows(city.trees, sunpos)
    add_shadow_intervals!(city.streets, s2; clear_old_shadows=false)
    city.tree_shadows = s2
    return (s1, s2)
end

# MARK: projections
function CoolWalksUtils.project_local!(city::AbstractCityDataset)
    project_local!(city.streets, city.observatory)
    project_casters_local!(city)
    return city
end

function project_casters_local!(city::SB_City)
    project_local!(city.buildings, city.observatory)
    project_local!(city.shadows, city.observatory)
end
function project_casters_local!(city::ST_City)
    project_local!(city.trees, city.observatory)
    project_local!(city.shadows, city.observatory)
end
function project_casters_local!(city::SBT_City)
    project_local!(city.buildings, city.observatory)
    project_local!(city.builing_shadows, city.observatory)
    project_local!(city.trees, city.observatory)
    project_local!(city.tree_shadows, city.observatory)
end

function CoolWalksUtils.project_back!(city::AbstractCityDataset)
    project_back!(city.streets)
    project_casters_back!(city)
    return city
end

function project_casters_back!(city::SB_City)
    project_back!(city.buildings)
    project_back!(city.shadows)
end
function project_casters_back!(city::ST_City)
    project_back!(city.trees)
    project_back!(city.shadows)
end
function project_casters_back!(city::SBT_City)
    project_back!(city.buildings)
    project_back!(city.builing_shadows)
    project_back!(city.trees)
    project_back!(city.tree_shadows)
end

"""
    CoolWalksUtils.local_sunpos(local_time::DateTime, city::AbstractCityDataset)

Calculates the sunposition in the `city`. Uses the `observatory` in `city` to determine timezone and center.

Corrects for daylight saving time.
"""
CoolWalksUtils.local_sunpos(local_time::DateTime, city::AbstractCityDataset; cartesian=true) = local_sunpos(local_time, city.observatory; cartesian=cartesian)

"""
    get_day_limits(day, city::AbstractCityDataset; min_angle=8.0)

Gets the first and last time in the `day`, where the sun is higher than `min_angle` above the horizon in local time.
"""
function get_day_limits(day, city::AbstractCityDataset; min_angle=8.0)
    day = Date(day)
    all_times = Time(0):Minute(1):Time(23, 59)
    times = [day + i for i in all_times]
    sunrise = findfirst(times) do time
        sunpos = local_sunpos(time, city; cartesian=false)
        return sunpos[1] > min_angle
    end
    sundown = findlast(times) do time
        sunpos = local_sunpos(time, city; cartesian=false)
        return sunpos[1] > min_angle
    end
    return times[sunrise], times[sundown]
end