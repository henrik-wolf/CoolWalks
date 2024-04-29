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
