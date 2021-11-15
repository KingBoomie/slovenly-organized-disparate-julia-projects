### A Pluto.jl notebook ###
# v0.16.1

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 8a2604ac-1f9b-11ec-30a2-0998ea216cac
begin
    import Pkg
    Pkg.activate("/tmp/timeseriespkg/")
    Pkg.add([
        Pkg.PackageSpec(name="FluxArchitectures"),
        Pkg.PackageSpec(name="Plots", version="1"),
        Pkg.PackageSpec(name="DataFrames", version="1"),
        Pkg.PackageSpec(name="CSV", version="0.9"),
    ])
	Pkg.add(["PlutoUI"])
    using FluxArchitectures, Random, Plots, DataFrames, Dates, CSV, PlutoUI
end

# ╔═╡ e9e23536-7553-4d61-bfa9-e3a76c6d6737
begin
	df = CSV.read("/home/kris/Downloads/opendata_covid19_tests_total.csv.1", DataFrame, )
	dropmissing!(df)
end

# ╔═╡ aeedcfe8-1e98-49af-8ea1-55864638f6bf
cases = df[:, [:DailyCases, :TotalCases, :PerPopulation]] |> Matrix{Float32}

# ╔═╡ 3085780c-1977-4683-80e9-c1151b2d804a
begin
	poollength = 21; horizon = 14; datalength = 550;
	#input, target = get_data(:traffic, poollength, datalength, horizon)
	input, target = prepare_data(cases, poollength, datalength, horizon)
end

# ╔═╡ 2c9e7f3a-a913-4c3e-a70b-4e5b676bdcfa
input;

# ╔═╡ be7755f1-cfb2-4d42-940c-fe522390ad87
begin
	inputsize = size(input, 1)
	convlayersize = 4
	recurlayersize = 6
	skiplength = 120

	model = LSTnet(inputsize, convlayersize, recurlayersize, poollength, skiplength,
        init=Flux.zeros32, initW=Flux.zeros32)
end

# ╔═╡ bc612d5c-9092-489e-ab79-f62f0a814ae1
loss(x, y) = Flux.mse(model(x), y')

# ╔═╡ 7d37133c-b84f-4087-ae2b-3af5203cd028
cbb = function ()
    Flux.reset!(model)
    pred = model(input)' |> cpu
    Flux.reset!(model)
	# @show losss = Flux.mse(pred, target)
    p1 = plot(pred, label="Predict")
    p1 = plot!(target, label="Data", title="Loss $(loss(input, target))")
    display(plot(p1))
end

# ╔═╡ 6bbf14b9-c88f-44ab-ad8f-8de25174b998
begin
	@show start_loss = loss(input, target)
	for _ = 1:20
		Flux.train!(loss, Flux.params(model),Iterators.repeated((input, target), 20), ADAM(0.01))
	end
	@show final_loss = loss(input, target)
end

# ╔═╡ fbd02e0b-c2de-4a39-9896-84346e5f12f8
Threads.nthreads()

# ╔═╡ 7958c8df-79fa-44ef-b27b-0859ee47be08
loss(input, target)

# ╔═╡ 06f33530-06bb-4a75-954c-a48115e07bb4
@bind range_i Slider(1:500, show_value=true)

# ╔═╡ 648d121f-d8f7-4b7f-b416-5450976c2861
prediction = model(input)[range_i:end]

# ╔═╡ 56a5241b-4b0d-4f76-9e0c-180e1823c1f3
truth = target[range_i:end]

# ╔═╡ dd097505-8353-4dfd-8cef-63a7c59473af
plot([prediction, truth], labels=["prediction" "target"])

# ╔═╡ 3a48bb35-baf3-4583-bc1c-4da64eb7dd6e
plot(cases[:,1])

# ╔═╡ Cell order:
# ╠═8a2604ac-1f9b-11ec-30a2-0998ea216cac
# ╠═e9e23536-7553-4d61-bfa9-e3a76c6d6737
# ╠═aeedcfe8-1e98-49af-8ea1-55864638f6bf
# ╠═3085780c-1977-4683-80e9-c1151b2d804a
# ╠═2c9e7f3a-a913-4c3e-a70b-4e5b676bdcfa
# ╠═be7755f1-cfb2-4d42-940c-fe522390ad87
# ╠═bc612d5c-9092-489e-ab79-f62f0a814ae1
# ╠═7d37133c-b84f-4087-ae2b-3af5203cd028
# ╠═6bbf14b9-c88f-44ab-ad8f-8de25174b998
# ╠═fbd02e0b-c2de-4a39-9896-84346e5f12f8
# ╠═7958c8df-79fa-44ef-b27b-0859ee47be08
# ╠═06f33530-06bb-4a75-954c-a48115e07bb4
# ╠═648d121f-d8f7-4b7f-b416-5450976c2861
# ╠═56a5241b-4b0d-4f76-9e0c-180e1823c1f3
# ╠═dd097505-8353-4dfd-8cef-63a7c59473af
# ╠═3a48bb35-baf3-4583-bc1c-4da64eb7dd6e
