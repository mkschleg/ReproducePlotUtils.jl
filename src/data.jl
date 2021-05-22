
struct LineData{D, C, LP, SP, DP}
    line_params::LP
    swept_params::SP
    data::D
    data_pms::DP
    c::C
end

Base.show(io::IO, ld::LineData) =
    print(io, "LineData(", ld.line_params, ", ", ld.swept_params, ", ", ld.c, ")")

struct DataCollection{LD}
    data::Vector{LD}
end

Base.keys(dc::DataCollection) = keys(dc.data)

Base.show(io::IO, ld::DataCollection) =
    print(io, "DataCollection(LineParams: $(keys(ld[1].line_params)), SweptParams: $(keys(ld[1].swept_params)))")

Base.getindex(dc::DataCollection, idx) = if idx isa AbstractArray
    DataCollection(dc.data[idx])
else
    dc.data[idx]
end

Base.eltype(dc::DataCollection) = eltype(dc.data)

function load_runs(ic, get_data)
    tmp = get_data(FileIO.load(joinpath(ic[1].folder_str, "results.jld2")))
    d = Array{typeof(tmp), 1}(undef, length(ic))

    diff_dict = diff(ic)
    # pms_template = NamedTuple(Symbol(k)=>diff_dict[k][1] for k ∈ keys(diff_dict))
    pms_template = @static if VERSION <= v"1.5"
        (; Symbol(k)=>diff_dict[k][1] for k ∈ keys(diff_dict))
    else
        NamedTuple(Symbol(k)=>diff_dict[k][1] for k ∈ keys(diff_dict))
    end
    pms = typeof(pms_template)[]
    
    for (idx, item) ∈ enumerate(ic)
        push!(d, get_data(FileIO.load(joinpath(item.folder_str, "results.jld2"))))
        @static if VERSION <= v"1.5"
            push!(pms, (; Symbol(k)=>item.parsed_args[k] for k ∈ keys(diff_dict)))
        else
            push!(pms, NamedTuple(Symbol(k)=>item.parsed_args[k] for k ∈ keys(diff_dict)))
        end
    end
    d, pms
end

function get_comp_function(comp::Symbol)
    if comp == :max
        findmax
    elseif comp == :min
        findmin
    end
end

function get_data_function(get_data_sym::Symbol)
end

function find_best_params(ic,
	                  param_keys,
		          comp,
		          get_comp_data,
		          get_data=get_comp_data)

    if comp isa Symbol
        comp = get_comp_function(comp)
    end
    
    ic_diff = diff(ic)
    params = if param_keys isa String
        ic_diff[param_keys]
    else
        collect(Iterators.product([ic_diff[k] for k ∈ param_keys]...))
    end
    
    s = zeros(length(params))
    for (p_idx, p) ∈ enumerate(params)
        sub_ic = if param_keys isa String
            search(ic, Dict(param_keys=>p))
        else
            search(ic, Dict(param_keys[i]=>p[i] for i ∈ 1:length(p)))
        end

        s[p_idx] = mean(load_runs(sub_ic, get_comp_data)[1])
    end

    v, idx = comp(s)

    best_ic = if param_keys isa String
	search(
	    ic,
	    Dict(param_keys=>params[idx]))
    else
	search(
	    ic,
	    Dict(param_keys[i]=>params[idx][i] for i ∈ 1:length(params[idx])))

    end

    data, data_pms = load_runs(best_ic, get_data)
    
    data, data_pms, v, params[idx]
end

function get_line_data_for(
    ic::ItemCollection,
    line_keys,
    param_keys;
    comp,
    get_comp_data,
    get_data)
    
    ic_diff = diff(ic)
    params = if line_keys isa String
        ic_diff[line_keys]
    else
        collect(Iterators.product([ic_diff[k] for k ∈ line_keys]...))
    end

    strg = Vector{LineData}(undef, length(params))

    for p_idx ∈ 1:length(params)
	p = params[p_idx]

	sub_ic = if line_keys isa String
            search(ic, Dict(line_keys=>p))
        else
            search(ic, Dict(line_keys[i]=>p[i] for i ∈ 1:length(p)))
        end
        
        if !isempty(sub_ic)
	    d, dp, c, ps = find_best_params(
	        sub_ic,
	        param_keys,
                comp,
	        get_comp_data,
	        get_data)
            
            if line_keys isa String
                strg[p_idx] =
                    LineData(Dict(line_keys=>params[p_idx]), ps, d, dp, c)
            else
                strg[p_idx] =
                    LineData(Dict(line_keys[i]=>params[p_idx][i] for i in 1:length(line_keys)), ps, d, dp, c)
            end

        end
    end
    DataCollection(convert(Vector{typeof(strg[1])}, strg))
end



# function get_data_frame_for(
#     ic::ItemCollection,
#     line_keys,
#     param_keys;
#     comp,
#     get_comp_data,
#     get_data)
    
#     ic_diff = diff(ic)
#     params = if line_keys isa String
#         ic_diff[line_keys]
#     else
#         collect(Iterators.product([ic_diff[k] for k ∈ line_keys]...))
#     end

#     strg = LineData[]

#     Threads.@threads for p_idx ∈ 1:length(params)
# 	p = params[p_idx]

# 	sub_ic = if line_keys isa String
#             search(ic, Dict(line_keys=>p))
#         else
#             search(ic, Dict(line_keys[i]=>p[i] for i ∈ 1:length(p)))
#         end
        
#         if !isempty(sub_ic)
# 	    d, dp, c, ps = find_best_params(
# 	        sub_ic,
# 	        param_keys,
#                 comp,
# 	        get_comp_data,
# 	        get_data)
            
#             if line_keys isa String
#                 push!(strg, LineData(Dict(line_keys=>params[p_idx]), ps, d, dp, c))
#             else
#                 push!(strg, LineData(Dict(line_keys[i]=>params[p_idx][i] for i in 1:length(line_keys)), ps, d, dp, c))
#             end

#         end
#     end
#     DataCollection(convert(Vector{typeof(strg[1])}, strg))
# end

