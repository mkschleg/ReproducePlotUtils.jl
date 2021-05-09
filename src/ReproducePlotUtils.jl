module ReproducePlotUtils

using Reproduce, Plots, RollingFunctions, Statistics, FileIO

include("stat_utils.jl")

function get_agg(agg, ddict, key)
    agg(ddict["results"][key])
end

get_MEAN(ddict, key) = get_agg(mean, ddict, key)
get_AUC(ddict, key) = get_agg(sum, ddict, key)
get_AUE(ddict, key, perc=0.1) = get_agg(ddict, key) do x
    sum(x[end-max(1, Int(floor(length(x)*perc))):end])
end

get_MUE(ddict, key, perc=0.1) = get_agg(ddict, key) do x
    mean(x[end-max(1, Int(floor(length(x)*perc))):end])
end

function get_rolling_mean_line(ddict, key, n)
    if n > length(ddict["results"][key])
        n = length(ddict["results"][key])
    end
    rollmean(ddict["results"][key], n)
end

function get_extended_line(ddict, key1, key2; n=0)
    ret = zeros(eltype(ddict["results"][key1]), sum(ddict["results"][key2]))
    cur_idx = 1
    for i in 1:length(ddict["results"][key1])
        ret[cur_idx:(cur_idx + ddict["results"][key2][i] - 1)] .= ddict["results"][key1][i]
        cur_idx += ddict["results"][key2][i]
    end

    if n == 0
        ret
    else
        rollmean(ret, n)[1:n:end]
    end
end

function load_data(loc)
    ic = ItemCollection(loc)
    ic, diff(ic)
end

include("data.jl")
include("recipes.jl")


end
