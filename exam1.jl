### A Pluto.jl notebook ###
# v0.16.4

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

# ╔═╡ bb6cae46-4108-11eb-2309-3d11f13a19fa
begin
	using Pkg
	Pkg.activate()
	Pkg.add([
			"Plots", 
			"PlutoUI", 
			"StatsBase", 
			"DataStructures", 
			"Unitful", 
			"PhysicalConstants", 
			"UnitfulEquivalences", 
			"DataFrames", 
			"CSV", 
			"Dates", 
			"TimeZones", 
			"StatsPlots", 
			"ImageFiltering", 
			"OffsetArrays", 
			"Chain", 
			"FluxArchitectures",
			"LsqFit",
			])
end

# ╔═╡ 0b484dcf-b479-46d7-8c86-d96a43ff458d
begin
	Pkg.develop("TSAnalysis")
	using LinearAlgebra, Optim, Measures;
	using TSAnalysis;
end

# ╔═╡ d8b334ae-4108-11eb-2546-99e75efc18d6
begin
	using Plots
	plotly()
	using PlutoUI
	using StatsBase
	using DataStructures
	using DataFrames
	using CSV
	using TimeZones
	using Dates
	using StatsPlots
	using ImageFiltering
	using OffsetArrays
	using Chain
	using FluxArchitectures
	using Statistics
	using LsqFit
	TableOfContents()
end

# ╔═╡ e6b122ce-5548-11eb-3980-53dfd8e5897c
begin
	frmt = dateformat"yyyy-mm-dd HH:MM:SS"
	column_types = Dict(:ResultTime=>DateTime, :AnalysisInsertTime=>DateTime)
end

# ╔═╡ 7f15b8d8-17d9-4b89-aedb-99ff090a91ea
begin
	page_url = "https://opendata.digilugu.ee/"
	download_path = "/home/kris/Downloads/"
	filenames = (
		"opendata_covid19_hospitalization_profile.csv",
		"opendata_covid19_test_results.csv", 
		"covid19/vaccination/v2/opendata_covid19_vaccination_location_county_agegroup_gender.csv",
		"opendata_covid19_tests_total.csv",
		)
	
	if true
		for filename = filenames
			download(string(page_url, filename), string(download_path, filename))
		end
	end
	
	hosp = CSV.read(string(download_path, filenames[1]), DataFrame)
	df = CSV.read(string(download_path, filenames[2]), DataFrame, types=column_types, dateformat=frmt)
	dropmissing!(df)
	vac = CSV.read(string(download_path, filenames[3]), DataFrame)
	df_total = CSV.read(string(download_path, filenames[4]), DataFrame)
	dropmissing!(df_total)
end

# ╔═╡ eaab22ca-5b2c-11eb-1eb6-cf73054ee98e
begin
	inimarv_raw = CSV.read("/home/kris/Downloads/RV0222U_20012021163956877.csv", DataFrame)
	ages_csv = CSV.read("/home/kris/Downloads/RV021_30092021210733436.csv", DataFrame)
	inimarv = Dict(eachrow(inimarv_raw[!, [:Maakond, :Value]]));
end

# ╔═╡ 6fcdea12-35f3-4648-8ba0-cfd6e89547ef
counties = collect(setdiff(keys(inimarv), ["..Tallinn", "..Tartu linn", "Maakond teadmata"]))

# ╔═╡ 2a795f4a-6bca-11eb-2b3f-b385b41d4759
@bind selectedCounty MultiSelect(counties)

# ╔═╡ 710d2e87-12df-4fdd-be2e-8826c691a86c
md"## Testing"

# ╔═╡ ed6d5c68-5b1f-11eb-134b-57fcc502469c
positive = filter(x -> x.County ∈ selectedCounty && x.ResultValue == "P", df)

# ╔═╡ 7b2f2674-5b22-11eb-225c-cbd01d9b1058
begin
	smooth_range = -7:0
	n = size(smooth_range)[1]
	kernel = OffsetArray(fill(1/n, n), smooth_range)
end;

# ╔═╡ baf09934-5b20-11eb-3283-d9b7bdfb5a90
allSelected = @chain positive begin 
	groupby([:StatisticsDate])
	combine(nrow => :count)
	transform(:count => (arr -> imfilter(arr, kernel)) => :smooth_count)
end;

# ╔═╡ dc1fdc56-6bcd-11eb-32c7-f3515450573c
dates = allSelected[!, :StatisticsDate];

# ╔═╡ f9b7501b-abb7-4998-bf5a-787cba8355d6
begin
	@df allSelected plot(:StatisticsDate, [:count], ticks=:native, legend=:topleft, label="daily count")
	@df allSelected plot!(:StatisticsDate, [:smooth_count], label="7-day smooth", linewidth=2)
end

# ╔═╡ 74295a2c-6bc9-11eb-1474-9befdff2e2bf
next = @chain positive begin
	groupby([:StatisticsDate, :County])
	combine(nrow => :count)
	groupby([:County])
	transform((arr -> imfilter(arr.count, kernel) / inimarv[arr[1,:County]] * 100000))
end;

# ╔═╡ 080ecf02-5549-11eb-06cd-b10c7ed4e1e4
groups = groupby(df, [:ResultValue]);

# ╔═╡ 742c4eaa-7fe5-11eb-37e5-b96d6d7d86cd
@df next plot(:StatisticsDate, [:x1], group=:County, title="New infections per 100000", legend=:topleft, ticks=:native)

# ╔═╡ e580107b-963f-4e0b-967a-539e0e0a544d
md"""
Sidenote for all the following graphs with weeks in the x-axis. Technically what I currently count as a week is just the result of `floor(day_of_year/7)`. I used actual calendar weeks at first, but this ran into the nasty problem 2021 starting with week 52 for the first few days, which causes all sorts of problems. 

Also data from the very last week is inherently not complete.  
"""

# ╔═╡ 46368bc1-2079-4ad0-aa1d-677ce6dbd250
weekday_count = @chain allSelected begin
	transform(:StatisticsDate => ByRow(dayofweek) => :day)
	select([:day, :count])
	groupby(:day)
	combine(:count => sum)
end;

# ╔═╡ 29030d24-50b1-4c5b-83b1-75695910def1
weekday_completion = cumsum(weekday_count.count_sum) ./ sum(weekday_count.count_sum)

# ╔═╡ 12989f47-8e87-40df-a993-61d9f96516dd
lastdate = positive.StatisticsDate[end]

# ╔═╡ 9dcb4ec0-dc17-428f-9e7d-b6fddad8c9c4
last_week_day_count = (dayofyear(lastdate) % 7 + 1)

# ╔═╡ f15da4cb-fc03-47b4-98d6-45f3edf158f6
last_week_multiplier = 1/weekday_completion[last_week_day_count]

# ╔═╡ d49f6f5e-5cb5-11eb-14e1-45d31ab53e89
function week_multi(week_p)
	week_multiplier = zeros(size(week_p)[1])
	for i = 2:size(week_p)[1]
		prev = week_p[i-1, :count_in_week]
		current = week_p[i, :count_in_week]
		week_multiplier[i] = current/prev
	end
	week_multiplier[end] *= last_week_multiplier # add an estimate for the currently ongoing week
	week_multiplier
end;

# ╔═╡ ef39fc56-554b-11eb-3082-77349ed217d4
counts = combine(groups, nrow => :count)

# ╔═╡ c85e156e-554a-11eb-218b-df5eabe2d8ab
@df counts bar(:ResultValue, :count)

# ╔═╡ 53fd6066-4515-4641-8a7d-adc4a8e780a7
md"""
## Vaccinations
"""

# ╔═╡ 77ead592-c4a1-4821-83c1-1b311362622b
long_vac = @chain vac begin 
	groupby([:StatisticsDate, :MeasurementType])
	combine([:DailyCount => sum => :DailyCount])
	unstack(_, :StatisticsDate, :MeasurementType, :DailyCount)
	rename!(["StatisticsDate", "Total?", "Completed", "InProgress"])
end

# ╔═╡ 51dbbbb2-65b2-4b30-a628-6f49fe606cdc
 hm = @chain vac begin 
	groupby([:StatisticsDate, :MeasurementType])
	combine([:DailyCount => sum => :DailyCount])
	unstack(_, :StatisticsDate, :MeasurementType, :DailyCount)
	transform(Not(:StatisticsDate) => ((doses, fully, half) -> doses-fully-half) => :confusion)
end

# ╔═╡ 0fe1a173-4e9a-4b6c-9ea1-3647adc1c73e
sum(hm.confusion)

# ╔═╡ 4e5614af-8cf2-46c8-86ee-54b8e9e790d5
@df long_vac plot(:StatisticsDate, [:InProgress, :Completed], ticks=:native, label=["1st dose" "completed dose"])

# ╔═╡ 147e2cf8-5bfc-4e52-9105-e6ccd8b466da
hosp

# ╔═╡ bf9dfb10-9fe3-48d3-a299-0e8c9744ac29
merge_agegroup = Dict(
	"0-4" => "0-17",
	"5-9" => "0-17",
	"10-14" => "0-17",
	"15-19" => "0-17",
	"20-24" => "18-29",
	"25-29" => "18-29",
	"30-34" => "30-39",
	"35-39" => "30-39",
	"40-44" => "40-49",
	"45-49" => "40-49",
	"50-54" => "50-59",
	"55-59" => "50-59",
	"60-64" => "60-69",
	"65-69" => "60-69",
	"70-74" => "70-79",
	"75-79" => "70-79",
	"80-84" => "80+",
	"üle 85"=> "80+",
)

# ╔═╡ 4486854d-f57c-4c7d-9866-a50d3f31d1cd
merge_agegroup1 = Dict(
	"1-4" => "0-17",
	"0" => "0-17",
	"5-9" => "0-17",
	"10-14" => "0-17",
	"15-19" => "0-17",
	"20-24" => "18-29",
	"25-29" => "18-29",
	"30-34" => "30-39",
	"35-39" => "30-39",
	"40-44" => "40-49",
	"45-49" => "40-49",
	"50-54" => "50-59",
	"55-59" => "50-59",
	"60-64" => "60-69",
	"65-69" => "60-69",
	"70-74" => "70-79",
	"75-79" => "70-79",
	"80-84" => "80+",
	"85 ja vanemad" => "80+",
)

# ╔═╡ ff202e82-e45e-410d-9158-37f7b5de1fbc
merge_agegroup2 = Dict(
	"0-11" => "0-17",
	"12-15" => "0-17",
	"16-17" => "0-17",
	"18-29" => "18-29",
	"30-39" => "30-39",
	"40-49" => "40-49",
	"50-59" => "50-59",
	"60-69" => "60-69",
	"70-79" => "70-79",
	"80+" => "80+",
)

# ╔═╡ 83dad0ff-128d-4ca4-a9d4-447088cb577b
merge_keys = Set(keys(merge_agegroup1));

# ╔═╡ bc94dcb4-7f2a-422c-8e36-a23b1fc47fa9
@chain vac begin
	subset(:StatisticsDate => ByRow(==(Date("2021-11-10"))), :MeasurementType => ByRow(==("FullyVaccinated")))
	groupby(:AgeGroup)
	combine(:TotalCount => sum)
end

# ╔═╡ 2e6ade2d-52d4-42cc-b7ee-332b4bcf4634
md"ignored vaccinated people for missing agegroup: $(sum(vac[ismissing.(vac.AgeGroup), :].DailyCount))"

# ╔═╡ 4106d31a-8eae-40bb-9764-f3566c23d139
107316 / 112691

# ╔═╡ 6eeca282-50f6-4cb3-abbd-5c3df6c3a4e5
md"""# Predicting the future

## Vaccination Prediction
For cumulative vaccinations, I train a simple ARIMA(1,2,1) model and compare that to the goal of 70% vaccination, since that was the goal before the delta variant of covid. Right now, the 70% goal is not semantically useful, but every extra percentage helps exponentially. 

Note that this comparison is not valid for vaccines that only take one shot for immunity, people who get one vaccine shot after they have already caught covid and in the future, any booster shots.

It also might be argued that it's mistreating small children (younger than 12) since they don't have any approved vaccines yet, but while their chances of dying are tiny, they can still very successfuly transmit the virus and saving lives is very much about curbing the spread of the virus. 
"""

# ╔═╡ 322eecdf-56ff-42bd-986c-964c3eacd313
md"""## Testing prediction

This model is a small DSANet (Dual Self-Attention Network for Multivariate Time Series Forecasting) predicting the next three weeks. """

# ╔═╡ 0efbbf98-ee90-428a-b491-081d6dc08527
cases = df_total[:, [:DailyCases, :TotalCases, :PerPopulation]] |> Matrix{Float32};

# ╔═╡ ae921ac9-520a-4ae1-858e-d32a630eaf11
x̂ = mean(df_total.DailyCases); std_x = std(df_total.DailyCases)

# ╔═╡ e4413e75-fe3c-402a-a0ff-d199adf65ecd
begin
	poollength = 14; horizon = 14; datalength = 600;
	input, target = prepare_data(cases, poollength, datalength, horizon)
	
	inputsize = size(input, 1)
	local_length = 3
	n_kernels = 3
	d_model = 4
	hiddensize = 1
	n_layers = 3
	n_head = 2

	# Define the neural net
	model = DSANet(inputsize, poollength, local_length, n_kernels, d_model,
               hiddensize, n_layers, n_head)
	loss(x, y) = Flux.mse(model(x), y')
	evalcb() = Flux.throttle( () => @show(loss(input, target)), 5)
end;

# ╔═╡ b1629624-2b31-4edd-bcfa-d5b25bce77e8
count(isnan, input), count(isnan, cases), size(cases)

# ╔═╡ efbc5f35-6fc1-4c4c-b5da-4d5b070e02be
begin
	@show start_loss = loss(input, target)
	for _ = 1:20
		Flux.train!(loss, Flux.params(model),Iterators.repeated((input, target), 20), ADAMW(0.004))
		evalcb()
	end
	@show final_loss = loss(input, target)
end

# ╔═╡ de01cbd3-f8ba-4d88-9ac9-7f607b8567c5
@bind plot_prediction_i Slider(1:550, show_value=true)

# ╔═╡ 45ca89fe-412a-45fb-afd2-eb991d1fc858
cases[:, 1]

# ╔═╡ d6eedaf0-d666-4b12-8b6f-5ab473ba915a
begin
	current_input = cases[(end-13):end, :]
	last14_data = Flux.normalise(current_input, dims=1)[(end-13):end, :]
	last14 = permutedims(reshape(last14_data, (14, 3, 1, 1)), (2, 1, 3, 4))
	
	x_prediction = model(input)[plot_prediction_i:end] .* std_x .+ x̂
	# truth = cases[plot_prediction_i:end, 1]
	truth = target[plot_prediction_i:end] .* std_x .+ x̂
	
	plot([x_prediction, truth], labels=["prediction" "ground truth"])
end

# ╔═╡ 6e582294-40ff-4871-8749-db6f48761473


# ╔═╡ 256c1dc5-8f7f-4ae4-8a34-045624a3f7b4
last14

# ╔═╡ 22bfe01d-8077-4816-b5a9-94635d76120b
size(last14)

# ╔═╡ 623bba06-c217-4683-8be9-1bd366808c05
model(last14)

# ╔═╡ 0e5aa436-7553-4af2-907d-769a3c7295f0
md"# Util"

# ╔═╡ 5123d73c-6c9b-11eb-0231-675c2b98d0d3
yearweek(date) = (year(date) - 2020)*52 + dayofyear(date) ÷ 7

# ╔═╡ 15f92d78-5b26-11eb-0050-27f2434d1f75
week_p = @chain positive begin
	transform(:StatisticsDate => ByRow(x -> yearweek(x)) => :week)
	groupby([:week, :County])
	combine(nrow => :count_in_week)
	groupby([:County])
	transform(week_multi)
end;

# ╔═╡ dcba4866-5b26-11eb-3e27-8fc9dd4bae77
@df week_p plot(:week, [:count_in_week], group=:County, title="New infections in week", legend=:topleft, xlabel="week")

# ╔═╡ d7a78b2e-5cb7-11eb-1967-1b3dc0a388bd
plot(week_p.week, [week_p.x1], group=week_p.County, title="New infections multiplier in county", xlabel="week")

# ╔═╡ 446f8889-a549-4fd2-b3e4-c09af9961405
no_county = @chain week_p begin
	groupby([:week])
	combine(:count_in_week => sum => :count_in_week)
	transform(week_multi)
end;

# ╔═╡ 65004f86-3c67-43a6-bb01-16df98e58148
begin
	@df no_county plot(:week, [:x1], title="Combined new infections multiplier", xlabel="week", label="infection multiplier")
	
	hline!([1], label="stable baseline")
end

# ╔═╡ 958bf270-0d79-43b8-ba66-9c378559c100
begin
	last_week = no_county.week[end]
	before_last_week =  no_county.count_in_week[end-1]
	last_week_estimate = no_county.count_in_week[end] * last_week_multiplier
	
	@df no_county plot(:week, [:count_in_week], title="Combined new infections per week", xlabel="week", label="infections", ticks=:native)
	plot!([last_week-1, last_week], [before_last_week, last_week_estimate], line=:dot, linewidth=2, label="estimate")
end

# ╔═╡ 54322a8f-2413-4ae1-9d25-57b652cc9e36
week_vac = @chain long_vac begin
	transform(:StatisticsDate => ByRow(x -> yearweek(x)) => :week)
	groupby([:week])
	combine([:Completed => sum => :Completed, :InProgress => sum => :InProgress])
end;

# ╔═╡ c9bb8186-2cd2-48f2-b579-6d304d0d5e8d
begin
	week_vac.cum_completed = cumsum(week_vac.Completed);
	week_vac.cum_inprogress = cumsum(week_vac.InProgress);
	week_vac.cum = (cumsum(week_vac.InProgress) .+ cumsum(week_vac.Completed));
end;

# ╔═╡ 766b95ae-3d6d-4e12-bd11-9416bda6f36a
begin
	@df week_vac plot(:week, [:Completed + :InProgress, :Completed, :InProgress], ticks=:native, title="Vaccine doses per week", legend=:topleft, label=["combined" "completed" "in progress"])
end

# ╔═╡ 242017a9-e5d9-4302-ac97-2424aabf8116
begin
	population = 1_329_460
	now = week_vac[end-1,:]
	
	doses = now.Completed + now.InProgress
	
	total_todo = floor(Int64, 2 * population * 0.7)
	todo = total_todo - now.cum
	
	p_progress = doses / (2 * population * 0.7)
	p_progress2 = doses / todo
	p_complete = now.cum / total_todo
	
	days2complete = floor(Int64, p_progress2^-1 * 7)
	completion_date = today() + Day(days2complete)
	
	"""$(round(p_complete*100))% (+$(round(p_progress*100))%)
	 The whole population will be 70% vaccinated in $days2complete days ($completion_date)
	"""
end

# ╔═╡ bd2ada71-6b46-4a33-9fb2-722dace05194
begin
	days2pcompletion = ceil(Int64, (population * 0.7 - now.cum_inprogress) / now.InProgress * 7)
	pcompletion = today() + Day(days2pcompletion)
	"Partial vaccination will be complete in $days2pcompletion days ($pcompletion)"
end

# ╔═╡ 5a25bbf6-9212-4b30-b7fe-2fa14ca02522
population / 2, now.cum, total_todo

# ╔═╡ c7343b6f-dccf-4b7b-996f-af41996537cf
week_vac

# ╔═╡ 2682f4e4-017a-4b45-aa68-28151e6877b3
begin
	@df week_vac plot(:week, [:cum, :cum_completed, :cum_inprogress], label=["all" "completed" "first dose"], ticks=:native, title="Cumulative vaccinations", legend=:topleft)
end

# ╔═╡ 5d8ac6af-1911-4583-9907-7d4f58d7863c
md"""not vaccinated: $(1_329_460 - week_vac[end, :cum_completed]) \
vaccinated: $(week_vac[end, :cum_completed])

## hospitalized
"""

# ╔═╡ f6473e6d-ebe3-4832-ba1d-01a1f1885ac6
begin
	Y = week_vac[1:end-1,:cum] |> JArray{Float64}
	Y = Matrix(Y')
end

# ╔═╡ a8d97ecc-9ec3-4821-8c87-97da92521c05
begin
	p = 1;
	d = 2;
	q = 1;
	arima_settings = ARIMASettings(Y, d, p, q);
	
	# Estimation
	arima_out = arima(arima_settings, NelderMead(), Optim.Options(iterations=100, f_tol=1e-2, x_tol=1e-2, g_tol=1e-2, show_trace=true, show_every=500));
end

# ╔═╡ 187448cb-1c80-4089-8f65-634fe4e3088c
begin
	week_count = 20
	fc = forecast(arima_out, week_count, arima_settings);
end

# ╔═╡ e41ecea5-77b1-43aa-aa00-01be18978510
begin
	weeks = week_vac[1:end-1,:week] |> Array{Int64,1}
	for new_week = 1:week_count
		last_week = weeks[end]
		push!(weeks, last_week + 1)
	end
	
	months = repeat(monthabbr.(1:12), 2)
	
	plot(weeks, [Y[1,:]; NaN*ones(week_count)], label="Vaccinated", ticks=:native, legend=:right, xticks = (52:4:160, months), xlabel="Month", ylabel="People")
	plot!(weeks, [NaN*ones(size(Y)[2]); fc[1,:]], label="Prediction", line=:dot)
	plot!(weeks, population*0.7*2*ones(size(weeks)), label="70% Goal")
end

# ╔═╡ d8ed8d5c-6c9b-11eb-2215-2fb6b80d30e2
countmap(week.(df[!, :StatisticsDate]))

# ╔═╡ d5b5cf78-5a87-11eb-1d85-176632857548
function mylinspace(d1::DateTime, d2::DateTime, n::Int)
    Δ = d2 - d1
    T = typeof(Δ)
    δ = T(round(Int, Dates.value(Δ)/(n - 1)))
    d2 = d1 + δ*(n - 1)
    return d1:δ:d2
end

# ╔═╡ 7f5be60a-5b23-11eb-3d24-d17513534e16
ticks = mylinspace(DateTime(2020,03,01), DateTime(2021,03,06), 30)

# ╔═╡ 620a967e-5b2f-11eb-3dc5-6108d315124b
(..)(x::AbstractDict,i...) = getindex.(Ref(x), i...)

# ╔═╡ 9e3c3714-5b2d-11eb-2a50-413ab7ed65d1
df.population = inimarv.. df[!, :County];

# ╔═╡ 48f4d8c8-37b5-4c2d-aabb-4a0590bffffb
hospitalized_age = @chain hosp begin
	groupby(:AgeGroup)
	combine(:PatientCount => sum => :PatientCount)
	dropmissing(:AgeGroup)
	transform(:AgeGroup => (ag ->  merge_agegroup .. ag) => :AgeGroup)
	groupby(:AgeGroup)
	combine(:PatientCount => sum => :PatientCount)
end;

# ╔═╡ 08e97dd2-a870-43e0-8c91-4c6b605b664f
ages = @chain ages_csv begin
	subset(:Vanuserühm => ByRow(x -> x ∈ merge_keys))
	select(:Vanuserühm, :Value)
	transform(:Vanuserühm => (ag ->  merge_agegroup1 .. ag) => :AgeGroup)
	groupby([:AgeGroup])
	combine([:Value => sum => :Total])
end;

# ╔═╡ daab5fb2-355d-49ca-9268-3f6e40d7b0a1
vaccinated_age = @chain vac begin
	subset(:MeasurementType => ByRow(==("FullyVaccinated")))
	dropmissing(:AgeGroup)
	transform(:AgeGroup => (ag ->  merge_agegroup2 .. ag) => :AgeGroup)
	groupby([:AgeGroup])
	combine([:DailyCount => sum => :Vaccinated])
end

# ╔═╡ 59bfbded-8aaa-4797-a588-18b2f946e57a
tested_age = @chain positive begin
	transform(:AgeGroup => (ag ->  merge_agegroup .. ag) => :AgeGroup)
	groupby(:AgeGroup)
	combine(nrow => :TestedPositive)
end;

# ╔═╡ c179a703-3955-4353-8a1e-a01b610335f1
begin
	agegroup = innerjoin(hospitalized_age, vaccinated_age, tested_age, ages, on=:AgeGroup)
	agegroup.NotVaccinated = agegroup.Total .- agegroup.Vaccinated
	agegroup.NoProtection = agegroup.NotVaccinated .- agegroup.TestedPositive
	agegroup.NewExpectedPatients = agegroup.PatientCount ./ agegroup.Total .* agegroup.NoProtection 
	agegroup
end

# ╔═╡ 9131bfb2-5144-46f7-9ee7-db03290ad930
can_hospitalize = sum(agegroup.PatientCount ./ agegroup.Total .* agegroup.NoProtection + agegroup.Vaccinated * 0.00008)

# ╔═╡ b35767b7-cde8-4b4b-bac6-6aeaf17f53ff
can_hospitalize * 1.05 * 1.10 * 1.4

# ╔═╡ e68e2172-43f9-4add-80cd-5b221e5981e8
md"""
### estimated nr of people that can still be hospitalized: $(round(can_hospitalize; digits=2))

caveats for the above:
* there might be some double counting for patients in the hospital (from people who get very sick twice) (but probably not much)
* there's definitely a bunch of double counting for testing positive (from people get covid twice) (**a lot**)
* there's also a lot of double (/ triple!) counting for people who got vaccinated, and still got sick (and still went to the hospital) (**a lot a lot**)
"""

# ╔═╡ 4d7a04cc-dd16-4d01-b724-4ea42333e8fe
sum(agegroup.Total)

# ╔═╡ 61991d43-ad43-4638-ad38-b3e6d3d8cb63
value_counts(x) = sort(collect(countmap(x)), by=x -> x[2], rev=true)

# ╔═╡ Cell order:
# ╠═bb6cae46-4108-11eb-2309-3d11f13a19fa
# ╠═d8b334ae-4108-11eb-2546-99e75efc18d6
# ╠═7f15b8d8-17d9-4b89-aedb-99ff090a91ea
# ╠═e6b122ce-5548-11eb-3980-53dfd8e5897c
# ╠═eaab22ca-5b2c-11eb-1eb6-cf73054ee98e
# ╠═9e3c3714-5b2d-11eb-2a50-413ab7ed65d1
# ╠═6fcdea12-35f3-4648-8ba0-cfd6e89547ef
# ╠═2a795f4a-6bca-11eb-2b3f-b385b41d4759
# ╟─710d2e87-12df-4fdd-be2e-8826c691a86c
# ╠═ed6d5c68-5b1f-11eb-134b-57fcc502469c
# ╠═baf09934-5b20-11eb-3283-d9b7bdfb5a90
# ╠═dc1fdc56-6bcd-11eb-32c7-f3515450573c
# ╠═f9b7501b-abb7-4998-bf5a-787cba8355d6
# ╠═74295a2c-6bc9-11eb-1474-9befdff2e2bf
# ╠═7b2f2674-5b22-11eb-225c-cbd01d9b1058
# ╠═080ecf02-5549-11eb-06cd-b10c7ed4e1e4
# ╠═742c4eaa-7fe5-11eb-37e5-b96d6d7d86cd
# ╠═15f92d78-5b26-11eb-0050-27f2434d1f75
# ╟─e580107b-963f-4e0b-967a-539e0e0a544d
# ╠═dcba4866-5b26-11eb-3e27-8fc9dd4bae77
# ╠═46368bc1-2079-4ad0-aa1d-677ce6dbd250
# ╠═29030d24-50b1-4c5b-83b1-75695910def1
# ╠═12989f47-8e87-40df-a993-61d9f96516dd
# ╠═9dcb4ec0-dc17-428f-9e7d-b6fddad8c9c4
# ╠═f15da4cb-fc03-47b4-98d6-45f3edf158f6
# ╠═d49f6f5e-5cb5-11eb-14e1-45d31ab53e89
# ╠═d7a78b2e-5cb7-11eb-1967-1b3dc0a388bd
# ╠═65004f86-3c67-43a6-bb01-16df98e58148
# ╠═958bf270-0d79-43b8-ba66-9c378559c100
# ╠═446f8889-a549-4fd2-b3e4-c09af9961405
# ╠═ef39fc56-554b-11eb-3082-77349ed217d4
# ╠═c85e156e-554a-11eb-218b-df5eabe2d8ab
# ╟─53fd6066-4515-4641-8a7d-adc4a8e780a7
# ╠═77ead592-c4a1-4821-83c1-1b311362622b
# ╠═51dbbbb2-65b2-4b30-a628-6f49fe606cdc
# ╠═0fe1a173-4e9a-4b6c-9ea1-3647adc1c73e
# ╠═4e5614af-8cf2-46c8-86ee-54b8e9e790d5
# ╠═54322a8f-2413-4ae1-9d25-57b652cc9e36
# ╠═c9bb8186-2cd2-48f2-b579-6d304d0d5e8d
# ╠═766b95ae-3d6d-4e12-bd11-9416bda6f36a
# ╠═242017a9-e5d9-4302-ac97-2424aabf8116
# ╠═bd2ada71-6b46-4a33-9fb2-722dace05194
# ╠═5a25bbf6-9212-4b30-b7fe-2fa14ca02522
# ╠═c7343b6f-dccf-4b7b-996f-af41996537cf
# ╠═2682f4e4-017a-4b45-aa68-28151e6877b3
# ╟─5d8ac6af-1911-4583-9907-7d4f58d7863c
# ╠═147e2cf8-5bfc-4e52-9105-e6ccd8b466da
# ╠═48f4d8c8-37b5-4c2d-aabb-4a0590bffffb
# ╟─bf9dfb10-9fe3-48d3-a299-0e8c9744ac29
# ╟─4486854d-f57c-4c7d-9866-a50d3f31d1cd
# ╟─ff202e82-e45e-410d-9158-37f7b5de1fbc
# ╠═83dad0ff-128d-4ca4-a9d4-447088cb577b
# ╠═08e97dd2-a870-43e0-8c91-4c6b605b664f
# ╠═daab5fb2-355d-49ca-9268-3f6e40d7b0a1
# ╠═bc94dcb4-7f2a-422c-8e36-a23b1fc47fa9
# ╟─2e6ade2d-52d4-42cc-b7ee-332b4bcf4634
# ╠═59bfbded-8aaa-4797-a588-18b2f946e57a
# ╠═c179a703-3955-4353-8a1e-a01b610335f1
# ╠═9131bfb2-5144-46f7-9ee7-db03290ad930
# ╠═b35767b7-cde8-4b4b-bac6-6aeaf17f53ff
# ╠═4d7a04cc-dd16-4d01-b724-4ea42333e8fe
# ╠═4106d31a-8eae-40bb-9764-f3566c23d139
# ╠═e68e2172-43f9-4add-80cd-5b221e5981e8
# ╟─6eeca282-50f6-4cb3-abbd-5c3df6c3a4e5
# ╠═0b484dcf-b479-46d7-8c86-d96a43ff458d
# ╠═f6473e6d-ebe3-4832-ba1d-01a1f1885ac6
# ╠═a8d97ecc-9ec3-4821-8c87-97da92521c05
# ╠═187448cb-1c80-4089-8f65-634fe4e3088c
# ╠═e41ecea5-77b1-43aa-aa00-01be18978510
# ╟─322eecdf-56ff-42bd-986c-964c3eacd313
# ╠═0efbbf98-ee90-428a-b491-081d6dc08527
# ╠═ae921ac9-520a-4ae1-858e-d32a630eaf11
# ╠═b1629624-2b31-4edd-bcfa-d5b25bce77e8
# ╠═e4413e75-fe3c-402a-a0ff-d199adf65ecd
# ╠═efbc5f35-6fc1-4c4c-b5da-4d5b070e02be
# ╠═de01cbd3-f8ba-4d88-9ac9-7f607b8567c5
# ╠═45ca89fe-412a-45fb-afd2-eb991d1fc858
# ╠═d6eedaf0-d666-4b12-8b6f-5ab473ba915a
# ╠═6e582294-40ff-4871-8749-db6f48761473
# ╠═256c1dc5-8f7f-4ae4-8a34-045624a3f7b4
# ╠═22bfe01d-8077-4816-b5a9-94635d76120b
# ╠═623bba06-c217-4683-8be9-1bd366808c05
# ╟─0e5aa436-7553-4af2-907d-769a3c7295f0
# ╠═7f5be60a-5b23-11eb-3d24-d17513534e16
# ╠═5123d73c-6c9b-11eb-0231-675c2b98d0d3
# ╠═d8ed8d5c-6c9b-11eb-2215-2fb6b80d30e2
# ╠═d5b5cf78-5a87-11eb-1d85-176632857548
# ╠═620a967e-5b2f-11eb-3dc5-6108d315124b
# ╠═61991d43-ad43-4638-ad38-b3e6d3d8cb63
