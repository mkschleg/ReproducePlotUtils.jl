### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# ╔═╡ 565f87b8-b04e-11eb-38ac-bfec45a98555
using Revise, ReproducePlotUtils, Plots, FileIO, StatsPlots

# ╔═╡ 321dfa1c-7cec-465c-abeb-e8d518487863
using Reproduce

# ╔═╡ 0ce48396-7229-4801-ba66-d9e1d05563c6
ic, diff_dict = 
		ReproducePlotUtils.load_data("example_data/dir_tmaze_er_rnn_rmsprop_10/")

# ╔═╡ ef1c7adc-dafe-4543-83b0-1295b31d2b10
FileIO.load(joinpath(ic[1].folder_str, "results.jld2"))["results"]

# ╔═╡ 51c42faa-c44f-47f9-b021-c4fbc3f001df
# data_col = ReproducePlotUtils.get_line_data_for(
#                ic,
#                ["numhidden", "truncation", "cell", "eta"],
#                [];
#                comp=:max,
#                get_comp_data=(x)->ReproducePlotUtils.get_AUE(x, :successes),
#                get_data=(x)->ReproducePlotUtils.get_AUE(x, :successes))

# ╔═╡ 17614876-687b-4b29-9bb2-65736f837ca3
data_col = ReproducePlotUtils.get_line_data_for(
               ic,
               ["numhidden", "truncation", "cell"],
               ["eta"];
               comp=:max,
               get_comp_data=(x)->ReproducePlotUtils.get_MUE(x, :successes),
               get_data=(x)->ReproducePlotUtils.get_rolling_mean_line(x, :successes, 300))

# ╔═╡ 4a520cfd-ed7d-4bf8-8c26-587e99e998e2
plot(data_col, Dict("numhidden"=>10, "truncation"=>12), palette=ReproducePlotUtils.custom_colorant, legend=:topleft)

# ╔═╡ 9bd94861-8f2a-4949-b5b8-14ffdc760341
data_col_sens = ReproducePlotUtils.get_line_data_for(
               ic,
               ["numhidden", "truncation", "cell", "eta"],
               [];
               comp=:max,
               get_comp_data=(x)->ReproducePlotUtils.get_MUE(x, :successes),
               get_data=(x)->ReproducePlotUtils.get_MUE(x, :successes))

# ╔═╡ e6762f85-8922-4b65-97a2-4e83b17eb89a
let
	plot(data_col_sens, 
	 	 Dict("numhidden"=>10, "truncation"=>12, "cell"=>"MAGRU"); 
		 sort_idx="eta", z=1.97, lw=2, palette=ReproducePlotUtils.custom_colorant)
	plot!(data_col_sens, 
	 	  Dict("numhidden"=>17, "truncation"=>20, "cell"=>"GRU"); 
	 	  sort_idx="eta", z=1.97, lw=2, palette=ReproducePlotUtils.custom_colorant)
    plot!(data_col_sens, 
	 	  Dict("numhidden"=>20, "truncation"=>12, "cell"=>"AAGRU"); 
	 	  sort_idx="eta", z=1.97, lw=2, palette=ReproducePlotUtils.custom_colorant)
end

# ╔═╡ ff833f3f-7feb-4f6d-a5ae-0abcc3de4c5f
data_col_eps = ReproducePlotUtils.get_line_data_for(
               ic,
               ["numhidden", "truncation", "cell"],
               ["eta"];
               comp=:max,
               get_comp_data=(x)->ReproducePlotUtils.get_MUE(x, :successes),
               get_data=(x)->ReproducePlotUtils.get_extended_line(x, :successes, :total_steps, n=500))

# ╔═╡ e5331c45-6171-45a9-a537-9e3c64c17fd6
plot(data_col_eps, Dict("numhidden"=>15, "truncation"=>20, "cell"=>"MAGRU"), palette=ReproducePlotUtils.custom_colorant, legend=:topleft, z=1.0, xscale=:log)

# ╔═╡ 3a23313d-ed57-4faa-b2b0-bec1d549c255
data_col_box = ReproducePlotUtils.get_line_data_for(
               ic,
               ["numhidden", "truncation", "cell"],
               ["eta"];
               comp=:max,
               get_comp_data=(x)->ReproducePlotUtils.get_MUE(x, :successes),
               get_data=(x)->ReproducePlotUtils.get_MUE(x, :successes))

# ╔═╡ 5e461d4b-98a5-4305-a579-78e59c4c62e7
let
	args = [
		Dict("numhidden"=>20, "truncation"=>20, "cell"=>"GRU"),
		Dict("numhidden"=>20, "truncation"=>12, "cell"=>"AAGRU"),
		Dict("numhidden"=>10, "truncation"=>12, "cell"=>"MAGRU")
		]
	boxplot(data_col_box, args; 
			label_idx="cell", 
			legend=false, 
			palette=ReproducePlotUtils.custom_colorant)
end

# ╔═╡ 78a8f6b0-6425-434b-b2be-a30df9c2df39
let
	params = Dict("numhidden"=>20, "truncation"=>20, "cell"=>"GRU")
	idx = findfirst(data_col_box.data) do ld
		all(ld.line_params[i] == params[i] for i in keys(params))
	end
	data_col_box[idx].data, data_col_box[idx].data_pms
end

# ╔═╡ 85c8a929-5c1d-4375-b2a0-a5f6f1db4e4b
let
	args = [
		Dict("numhidden"=>20, "truncation"=>12, "cell"=>"RNN"),
		Dict("numhidden"=>20, "truncation"=>12, "cell"=>"AARNN"),
		Dict("numhidden"=>10, "truncation"=>12, "cell"=>"MARNN")
		]
	boxplot(data_col_box, args; 
			label_idx="cell", 
			legend=false, 
			palette=ReproducePlotUtils.custom_colorant)
end

# ╔═╡ eb41c814-0e4b-4087-b35c-1a5626c87167
let
	get_data = (x)->ReproducePlotUtils.get_MUE(x, :successes)
	sub_ic = search(ic, Dict("numhidden"=>20, "truncation"=>20, "cell"=>"GRU", "eta"=>7.8125e-5))
	diff_dict = diff(sub_ic)
	tmp = get_data(FileIO.load(joinpath(sub_ic[1].folder_str, "results.jld2")))	
	d = typeof(tmp)[]
	pms_template = NamedTuple(Symbol(k)=>diff_dict[k][1] for k ∈ keys(diff_dict))
	pms = typeof(pms_template)[]
	for (idx, item) ∈ enumerate(sub_ic)
		push!(d, get_data(FileIO.load(joinpath(item.folder_str, "results.jld2"))))
		push!(pms, NamedTuple(Symbol(k)=>item.parsed_args[k] for k ∈ keys(diff_dict)))
	end
	d, pms
end

# ╔═╡ Cell order:
# ╠═565f87b8-b04e-11eb-38ac-bfec45a98555
# ╠═321dfa1c-7cec-465c-abeb-e8d518487863
# ╠═0ce48396-7229-4801-ba66-d9e1d05563c6
# ╠═ef1c7adc-dafe-4543-83b0-1295b31d2b10
# ╠═51c42faa-c44f-47f9-b021-c4fbc3f001df
# ╠═17614876-687b-4b29-9bb2-65736f837ca3
# ╠═4a520cfd-ed7d-4bf8-8c26-587e99e998e2
# ╠═9bd94861-8f2a-4949-b5b8-14ffdc760341
# ╠═e6762f85-8922-4b65-97a2-4e83b17eb89a
# ╠═ff833f3f-7feb-4f6d-a5ae-0abcc3de4c5f
# ╠═e5331c45-6171-45a9-a537-9e3c64c17fd6
# ╠═3a23313d-ed57-4faa-b2b0-bec1d549c255
# ╠═5e461d4b-98a5-4305-a579-78e59c4c62e7
# ╠═78a8f6b0-6425-434b-b2be-a30df9c2df39
# ╠═85c8a929-5c1d-4375-b2a0-a5f6f1db4e4b
# ╠═eb41c814-0e4b-4087-b35c-1a5626c87167
