function load_run(location; exclude_locals=true)
    df = collect_results(
        location;
        black_list=["result"],
        special_list=[:result => data -> postprocess_result(data["result"]; exclude_locals=exclude_locals)]
    )
end

function postprocess_result(data; exclude_locals)
    if exclude_locals
        select!(data, Not(:way_lengths))
    end
    a1 = filter(:a => ==(1.0), data)[1, :]
    @chain data begin
        filter!(:a => >(1.0), _)
        transform!([:a, :all_way_length] => ByRow((a, len_a) -> coolwalkability(a, len_a, a1.all_way_length)) => :coolwalkability_global)
        transform!(:daytime => ByRow(d -> [Date(d), Time(d)]) => [:date, :time])
        transform!(:all_edge_length => ByRow(shadow_fraction) => :shadow_fraction_global)
    end
    if !exclude_locals
        transform!(data, [:a, :way_lengths] => ByRow((a, len_a) -> coolwalkability.(a, len_a, a1.way_lengths)) => :coolwalkability_local)
    end
    return data
end