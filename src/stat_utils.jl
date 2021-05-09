
using Statistics


function mean_uneven(d::Vector{Array{F, 1}}) where {F}
    T = typeof(mean(d[1]))
    ret = zeros(T, maximum(length.(d)))
    n = zeros(Int, maximum(length.(d)))
    for v ∈ d
        ret[1:length(v)] .+= v
        n[1:length(v)] .+= 1
    end
    ret ./ n
end

function std_uneven(d::Vector{Array{F, 1}}; z=1.0) where {F}

    m = mean_uneven(d)
    T = typeof(mean(d[1]))
    
    ret = zeros(T, maximum(length.(d)))
    n = zeros(Int, maximum(length.(d)))
    for v ∈ d
        ret[1:length(v)] .+= (v .- m[1:length(v)]).^2
        n[1:length(v)] .+= 1
    end
    z * sqrt.(ret ./ n)
end
