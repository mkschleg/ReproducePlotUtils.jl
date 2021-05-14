using RecipesBase

custom_colorant = [
    colorant"#44AA99",
    colorant"#332288",
    colorant"#DDCC77",
    colorant"#CC6677",
    colorant"#AA4499",
    colorant"#DDDDDD",
    colorant"#117733",
    colorant"#882255",
    colorant"#999933",	
    colorant"#88CCEE",
]

# create various plot types:
# Sensitivity
# Performance Curves
# HeatMap Sensitivity
stats_plot_types = [:violin, :boxplot, :dotplot, :density, :histogram, :histogram2d, :groupedhist]

@recipe function f(dc::DataCollection, params::Dict)
    idx = findall(dc.data) do ld
        all([params[i] == ld.line_params[i] for i in keys(params)])
    end
    if length(idx) == 1
        dc[idx[1]]
    else
        dc[idx]
    end
end

@recipe function f(dc::DataCollection, params::AbstractVector)
    for arg in params
        @series begin
            dc, arg
        end
    end
end

@recipe function f(func::Function, dc::DataCollection)
    idx = findall(func, dc.data)
    dc[idx]
end

@recipe function f(dc::DataCollection; color_func=nothing)

    legendtitle --> "$(join(sort(collect(keys(dc[1].line_params))), ' '))"
    for d ∈ dc.data
        @series begin
            if !(color_func isa Nothing)
                color --> color_func(d)
            end
            d
        end
    end
end

@recipe function f(ld_vec::DataCollection{LD}; sort_idx=nothing, z=1.0) where {F<:Number, LD<:LineData{Vector{F}}}

    ld_sorted = if sort_idx isa Nothing
        ld_vec.data
    else
        sf = (ld1::LineData, ld2::LineData) -> isless(ld1.line_params[sort_idx], ld2.line_params[sort_idx])
        sort(ld_vec.data, lt=sf)
    end

    st = get(plotattributes, :seriestype, :path)
    if st ∈ stats_plot_types
        for ld in ld_sorted
            @series begin
                label_idx --> sort_idx
                ld
            end
        end
    else
        x = [ld.line_params[sort_idx] for ld in ld_sorted]
        y = [mean(ld.data) for ld in ld_sorted]
        yerror := [z*sqrt(var(ld.data))/length(ld.data) for ld in ld_sorted]

        (x, y)
    end
end

@recipe function f(ld::LineData{Vector{F}}; label_idx=1, z=1.0) where F<:Number
    st = get(plotattributes, :seriestype, :boxplot)
    if st ∈ stats_plot_types
        y = ld.data
        x = [ld.line_params[label_idx]]
        (x, y)
    else
        error("$(typeof(ld)) not supported for series type: $(st).")
    end
end

@recipe function f(ld::LineData{Vector{Vector{F}}}; z=1.0, color_dict=nothing) where F<:Number
    
    if :label ∈ keys(plotattributes)
	label := "$(plotattributes[:label]), $(ld.swept_params))"
    else
        ks = sort(collect(keys(ld.line_params)))
        lbl = prod(string(ld.line_params[k]) * " " for k in ks)
	label := "$(lbl), $(ld.swept_params)"
    end

    if !(color_dict isa Nothing)
        color --> color_dict[ld.line_params]
    end

    st = get(plotattributes, :seriestype, :path)
    if st ∈ stats_plot_types
        y = vcat(transpose.(ld.data)...)
        if :x ∈ keys(plotattributes)
            (plotattributes[:x], y)
        else
            (1:length(ld.data[1]), y)
        end
    else
        ribbon := std_uneven(ld.data; z=z)
        μ = mean_uneven(ld.data)
        y = μ
        x --> 1:length(μ)
 
        (plotattributes[:x], y)
    end

end

