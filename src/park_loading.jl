function load_parks(path, obs_name, tz)
    df = DataFrame(GeoJSON.read(path))
    poly = ArchGDAL.wkbPolygon
    multipoly = ArchGDAL.wkbMultiPolygon
    df = @chain df begin
        select!("@id" => :id, :geometry)
        filter!(:id => (id -> first(id) != 'n'), _)
        filter!(:geometry => (g -> g isa GeoJSON.Polygon || g isa GeoJSON.MultiPolygon), _)
        transform!(:geometry => ByRow(g -> GeoInterface.convert(ArchGDAL.IGeometry{g isa GeoJSON.Polygon ? poly : multipoly}, g)) => :geometry)
        transform!([:geometry, :id] => ByRow(CompositeBuildings.split_multi_poly) => [:geometry, :id])
        transform!(:geometry => ByRow(apply_wsg_84!) => :geometry)
        flatten([:geometry, :id])
        filter(:geometry => ArchGDAL.isvalid, _)
    end
    df.height .= 8.0
    set_observatory!(df, obs_name, tz; source=[:geometry])
    CompositeBuildings.check_building_dataframe_integrity(df)
    return df
end