### A Pluto.jl notebook ###
# v0.19.4

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ d8b334ae-4108-11eb-2546-99e75efc18d6
begin
	using Plots
	import PlotlyJS
	plotlyjs()
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
	import FluxArchitectures
	using Statistics
	using LsqFit
	using HTTP
	TableOfContents()
end

# ╔═╡ 0b484dcf-b479-46d7-8c86-d96a43ff458d
begin
	using LinearAlgebra, Optim, Measures;
	# using TSAnalysis;
end

# ╔═╡ bb6cae46-4108-11eb-2309-3d11f13a19fa
# begin
# 	using P k g
# 	P k g .a c t i v a t e()
# 	P k g. a d d([
# 			"Plots", 
# 			"PlutoUI", 
# 			"StatsBase", 
# 			"DataStructures", 
# 			"Unitful", 
# 			"PhysicalConstants", 
# 			"UnitfulEquivalences", 
# 			"DataFrames", 
# 			"CSV", 
# 			"Dates", 
# 			"TimeZones", 
# 			"StatsPlots", 
# 			"ImageFiltering", 
# 			"OffsetArrays", 
# 			"Chain", 
# 			"FluxArchitectures",
# 			"LsqFit",
# 			"HTTP",
# 			])
# end

# ╔═╡ 7f15b8d8-17d9-4b89-aedb-99ff090a91ea
begin
	frmt = dateformat"yyyy-mm-dd HH:MM:SS"
	column_types = Dict(:ResultTime=>DateTime, :AnalysisInsertTime=>DateTime)
	
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
	df = CSV.read(string(download_path, filenames[2]), DataFrame, )# types=column_types, dateformat=frmt)
	dropmissing!(df)
	vac = CSV.read(string(download_path, filenames[3]), DataFrame)
	df_total = CSV.read(string(download_path, filenames[4]), DataFrame)
	dropmissing!(df_total)
end;

# ╔═╡ 710d2e87-12df-4fdd-be2e-8826c691a86c
md"## Testing"

# ╔═╡ 7b2f2674-5b22-11eb-225c-cbd01d9b1058
begin
	smooth_range = -7:0
	n = size(smooth_range)[1]
	kernel = OffsetArray(fill(1/n, n), smooth_range)
end;

# ╔═╡ 080ecf02-5549-11eb-06cd-b10c7ed4e1e4
groups = groupby(df, [:ResultValue]);

# ╔═╡ e580107b-963f-4e0b-967a-539e0e0a544d
md"""
Sidenote for all the following graphs with weeks in the x-axis. Technically what I currently count as a week is just the result of `floor(day_of_year/7)`. I used actual calendar weeks at first, but this ran into the nasty problem 2021 starting with week 52 for the first few days, which causes all sorts of problems. 

Also data from the very last week is inherently not complete.  
"""

# ╔═╡ 04dbf36e-b45f-479b-8876-f48e0ad520a0
function week_2_datetime(week)
	DateTime(2020) + Week(week)
end

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
	"0-4" => "0-17",
	"5-11" => "0-17",
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
merge_keys = Set(keys(merge_agegroup1))

# ╔═╡ 4fdd4194-a041-4701-ba7e-47e12dc61e31
unique(vac.AgeGroup)

# ╔═╡ bc94dcb4-7f2a-422c-8e36-a23b1fc47fa9
@chain vac begin
	subset(:StatisticsDate => ByRow(==(Date("2021-11-10"))), :MeasurementType => ByRow(==("FullyVaccinated")))
	groupby(:AgeGroup)
	combine(:TotalCount => sum)
end

# ╔═╡ 2e6ade2d-52d4-42cc-b7ee-332b4bcf4634
md"ignored vaccinated people for missing agegroup: $(sum(vac[ismissing.(vac.AgeGroup), :].DailyCount))"

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

# ╔═╡ b1629624-2b31-4edd-bcfa-d5b25bce77e8
count(isnan, cases), size(cases) #, count(isnan, df_total), 

# ╔═╡ e4413e75-fe3c-402a-a0ff-d199adf65ecd
begin
	poollength = 14; horizon = 30; datalength = 675;
	input, target = FluxArchitectures.prepare_data(cases, poollength, datalength, horizon)
	
	inputsize = size(input, 1)
	local_length = 3
	n_kernels = 3
	d_model = 4
	hiddensize = 1
	n_layers = 3
	n_head = 2

	# Define the neural net
	model = FluxArchitectures.DSANet(inputsize, poollength, local_length, n_kernels, d_model,
               hiddensize, n_layers, n_head)
	loss(x, y) = FluxArchitectures.Flux.mse(model(x), y')
	evalcb() = FluxArchitectures.Flux.throttle( () => @show(loss(input, target)), 5)
end;

# ╔═╡ efbc5f35-6fc1-4c4c-b5da-4d5b070e02be
begin
	@show start_loss = loss(input, target)
	for _ = 1:10
		FluxArchitectures.Flux.train!(loss, FluxArchitectures.Flux.params(model),Iterators.repeated((input, target), 20), FluxArchitectures.ADAMW(0.004))
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
	last14_data = FluxArchitectures.Flux.normalise(current_input, dims=1)[(end-13):end, :]
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

# ╔═╡ dc1ed460-4c72-4d9b-b8e5-8b975cfc247f
"""
Downloads Estonian population statistics from the official Estonian statistics API.
https://andmed.stat.ee/api/v1/et/stat/RV022U. Downloaded data is segmented by county and age group.

Returns a tuple of `(county_pop, age_pop)` with `county_pop` being a dictionary from county to population and `age_pop` being a DataFrame with agegroup and population. 
"""
function download_popstats()
	params_json = """
{
  "query": [
    {
      "code": "Aasta",
      "selection": {
        "filter": "item",
        "values": [
          "2021"
        ]
      }
    },
    {
      "code": "Maakond",
      "selection": {
        "filter": "item",
        "values": [
          "37",
          "39",
          "44",
          "49",
          "51",
          "57",
          "59",
          "65",
          "67",
          "70",
          "74",
          "78",
          "82",
          "84",
          "86",
          "19"
        ]
      }
    },
    {
      "code": "Sugu",
      "selection": {
        "filter": "item",
        "values": [
          "1"
        ]
      }
    },
    {
      "code": "Vanuserühm",
      "selection": {
        "filter": "item",
        "values": [
          "1",
          "2",
          "3",
          "4",
          "5",
          "6",
          "7",
          "8",
          "9",
          "10",
          "11",
          "12",
          "13",
          "14",
          "15",
          "16",
          "17",
          "18",
          "19",
          "20",
          "21",
          "22",
          "23"
        ]
      }
    }
  ],
  "response": {
    "format": "csv"
  }
}"""
	url = "https://andmed.stat.ee/api/v1/et/stat/RV022U"
	r = HTTP.request("POST", url, ["Content-Type" => "application/json"], params_json)
	df = CSV.read(r.body, DataFrame)
	county_population = Dict(eachrow(df[!, [:Maakond, Symbol("Vanuserühmad kokku")]]))
	agegroup_population = @chain df begin
		select(:Maakond, 5:26)
		DataFrames.stack(Not(:Maakond))
		groupby(:variable)
		combine(:value => sum => :Value)
		rename(:variable => :Vanuserühm)
	end
	county_population, agegroup_population
end

# ╔═╡ eaab22ca-5b2c-11eb-1eb6-cf73054ee98e
begin
	inimarv, ages_df = download_popstats()
end;

# ╔═╡ 6fcdea12-35f3-4648-8ba0-cfd6e89547ef
counties = collect(setdiff(keys(inimarv), ["..Tallinn", "..Tartu linn", "Maakond teadmata"]))

# ╔═╡ 2a795f4a-6bca-11eb-2b3f-b385b41d4759
@bind selectedCounty MultiSelect(counties)

# ╔═╡ ed6d5c68-5b1f-11eb-134b-57fcc502469c
positive = filter(x -> x.County ∈ selectedCounty && x.ResultValue == "P", df)

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

# ╔═╡ 74295a2c-6bc9-11eb-1474-9befdff2e2bf
next = @chain positive begin
	groupby([:StatisticsDate, :County])
	combine(nrow => :count)
	groupby([:County])
	transform((arr -> imfilter(arr.count, kernel) / inimarv[arr[1,:County]] * 100000))
end;

# ╔═╡ 742c4eaa-7fe5-11eb-37e5-b96d6d7d86cd
@df next plot(:StatisticsDate, [:x1], group=:County, title="New infections per 100000", legend=:topleft, ticks=:native)

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
	transform(:week => ByRow(week_2_datetime) => :date)
end

# ╔═╡ 65004f86-3c67-43a6-bb01-16df98e58148
begin
	@df no_county plot(:date, [:x1], title="Combined new infections multiplier", xlabel="week", label="infection multiplier")
	
	hline!([1], label="stable baseline")
end

# ╔═╡ 958bf270-0d79-43b8-ba66-9c378559c100
begin
	last_week = no_county.date[end]
	before_last_week =  no_county.count_in_week[end-1]
	last_week_estimate = no_county.count_in_week[end] * last_week_multiplier
	
	@df no_county plot(:date, [:count_in_week], title="Combined new infections per week", xlabel="week", label="infections", ticks=:native)
	plot!([last_week-Week(1), last_week], [before_last_week, last_week_estimate], line=:dot, linewidth=2, label="estimate")
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
ages = @chain ages_df begin
	subset(:Vanuserühm => ByRow(x -> x ∈ merge_keys))
	select(:Vanuserühm, :Value)
	transform(:Vanuserühm => (ag ->  merge_agegroup1 .. ag) => :AgeGroup)
	groupby([:AgeGroup])
	combine([:Value => sum => :Total])
end

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
end

# ╔═╡ e064f170-fea2-4dbe-a0d9-f290661105a9
vac_hospitialization = DataFrame(:AgeGroup => tested_age.AgeGroup, :VaccinatedHospitalizedProbability => [0., 0.0001, 0.00005, 0., 0., 0.00015, 0.00025, 0.00055 ])

# ╔═╡ c179a703-3955-4353-8a1e-a01b610335f1
begin
	agegroup = innerjoin(hospitalized_age, vaccinated_age, tested_age, vac_hospitialization, ages, on=:AgeGroup)
	agegroup.NotVaccinated = agegroup.Total .- agegroup.Vaccinated
	agegroup.NoProtection = agegroup.NotVaccinated .- agegroup.TestedPositive
	agegroup.NewExpectedPatients = agegroup.PatientCount ./ agegroup.Total .* agegroup.NoProtection .+ agegroup.VaccinatedHospitalizedProbability .* agegroup.Vaccinated
	agegroup
end

# ╔═╡ d2119115-2dc5-4271-9722-6570ec54851b
sum(agegroup.NewExpectedPatients)

# ╔═╡ 9131bfb2-5144-46f7-9ee7-db03290ad930
can_hospitalize = sum(agegroup.NewExpectedPatients)

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

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
Chain = "8be319e6-bccf-4806-a6f7-6fae938471bc"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
DataStructures = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
FluxArchitectures = "53d20848-f986-4c56-957e-0e417ec068db"
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
ImageFiltering = "6a3955dd-da59-5b1f-98d4-e7296123deb5"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
LsqFit = "2fda8390-95c7-5789-9bda-21331edee243"
Measures = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
OffsetArrays = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
Optim = "429524aa-4258-5aef-a3af-852621145aeb"
PlotlyJS = "f0f68f2c-4968-5e81-91da-67840de0976a"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
StatsPlots = "f3b207a7-027a-5e70-b257-86293d7955fd"
TimeZones = "f269a46b-ccf7-5d73-abea-4c690281aa53"

[compat]
CSV = "~0.9.11"
Chain = "~0.4.10"
DataFrames = "~1.3.0"
DataStructures = "~0.18.11"
FluxArchitectures = "~0.1.4"
HTTP = "~0.9.17"
ImageFiltering = "~0.7.1"
LsqFit = "~0.12.1"
Measures = "~0.3.1"
OffsetArrays = "~1.10.8"
Optim = "~1.5.0"
PlotlyJS = "~0.18.8"
Plots = "~1.25.2"
PlutoUI = "~0.7.23"
StatsBase = "~0.33.13"
StatsPlots = "~0.14.29"
TimeZones = "~1.7.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.0"
manifest_format = "2.0"

[[deps.AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "485ee0867925449198280d4af84bdb46a2a404d0"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.0.1"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "abb72771fd8895a7ebd83d5632dc4b989b022b5b"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.2"

[[deps.AbstractTrees]]
git-tree-sha1 = "03e0550477d86222521d254b741d470ba17ea0b5"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.3.4"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "84918055d15b3114ede17ac6a7182f68870c16f7"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.1"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.Arpack]]
deps = ["Arpack_jll", "Libdl", "LinearAlgebra"]
git-tree-sha1 = "2ff92b71ba1747c5fdd541f8fc87736d82f40ec9"
uuid = "7d9fca2a-8960-54d3-9f78-7d1dccf2cb97"
version = "0.4.0"

[[deps.Arpack_jll]]
deps = ["Libdl", "OpenBLAS_jll", "Pkg"]
git-tree-sha1 = "e214a9b9bd1b4e1b4f15b22c0994862b66af7ff7"
uuid = "68821587-b530-5797-8361-c406ea357684"
version = "3.5.0+3"

[[deps.ArrayInterface]]
deps = ["Compat", "IfElse", "LinearAlgebra", "Requires", "SparseArrays", "Static"]
git-tree-sha1 = "265b06e2b1f6a216e0e8f183d28e4d354eab3220"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "3.2.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.AssetRegistry]]
deps = ["Distributed", "JSON", "Pidfile", "SHA", "Test"]
git-tree-sha1 = "b25e88db7944f98789130d7b503276bc34bc098e"
uuid = "bf4720bc-e11a-5d0c-854e-bdca1663c893"
version = "0.1.0"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[deps.BFloat16s]]
deps = ["LinearAlgebra", "Printf", "Random", "Test"]
git-tree-sha1 = "a598ecb0d717092b5539dbbe890c98bac842b072"
uuid = "ab4f0b2a-ad5b-11e8-123f-65d77653426b"
version = "0.2.0"

[[deps.BSON]]
git-tree-sha1 = "ebcd6e22d69f21249b7b8668351ebf42d6dc87a1"
uuid = "fbb218c0-5317-5bc6-957e-2ee96dd4b1f0"
version = "0.3.4"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BinDeps]]
deps = ["Libdl", "Pkg", "SHA", "URIParser", "Unicode"]
git-tree-sha1 = "1289b57e8cf019aede076edab0587eb9644175bd"
uuid = "9e28174c-4ba2-5203-b857-d8d62c4213ee"
version = "1.0.2"

[[deps.Blink]]
deps = ["Base64", "BinDeps", "Distributed", "JSExpr", "JSON", "Lazy", "Logging", "MacroTools", "Mustache", "Mux", "Reexport", "Sockets", "WebIO", "WebSockets"]
git-tree-sha1 = "08d0b679fd7caa49e2bca9214b131289e19808c0"
uuid = "ad839575-38b3-5650-b840-f874b8c74a25"
version = "0.12.5"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.CEnum]]
git-tree-sha1 = "215a9aa4a1f23fbd05b92769fdd62559488d70e9"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.1"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings"]
git-tree-sha1 = "49f14b6c56a2da47608fe30aed711b5882264d7a"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.9.11"

[[deps.CUDA]]
deps = ["AbstractFFTs", "Adapt", "BFloat16s", "CEnum", "CompilerSupportLibraries_jll", "ExprTools", "GPUArrays", "GPUCompiler", "LLVM", "LazyArtifacts", "Libdl", "LinearAlgebra", "Logging", "Printf", "Random", "Random123", "RandomNumbers", "Reexport", "Requires", "SparseArrays", "SpecialFunctions", "TimerOutputs"]
git-tree-sha1 = "5bd05cd090588389201f7e1c703d50ace07be861"
uuid = "052768ef-5323-5732-b1bb-66c8b64840ba"
version = "3.6.4"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.CatIndices]]
deps = ["CustomUnitRanges", "OffsetArrays"]
git-tree-sha1 = "a0f80a09780eed9b1d106a1bf62041c2efc995bc"
uuid = "aafaddc9-749c-510e-ac4f-586e18779b91"
version = "0.2.2"

[[deps.Chain]]
git-tree-sha1 = "339237319ef4712e6e5df7758d0bccddf5c237d9"
uuid = "8be319e6-bccf-4806-a6f7-6fae938471bc"
version = "0.4.10"

[[deps.ChainRules]]
deps = ["ChainRulesCore", "Compat", "LinearAlgebra", "Random", "RealDot", "Statistics"]
git-tree-sha1 = "c6366ec79d9e62cd11030bba0945712eb4013712"
uuid = "082447d4-558c-5d27-93f4-14fc19e9eca2"
version = "1.17.0"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "4c26b4e9e91ca528ea212927326ece5918a04b47"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.11.2"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "bf98fa45a0a4cee295de98d4c1462be26345b9a1"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.2"

[[deps.Clustering]]
deps = ["Distances", "LinearAlgebra", "NearestNeighbors", "Printf", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "75479b7df4167267d75294d14b58244695beb2ac"
uuid = "aaaa29a8-35af-508c-8bc3-b662a17a0fe5"
version = "0.14.2"

[[deps.CodeTracking]]
deps = ["InteractiveUtils", "UUIDs"]
git-tree-sha1 = "9aa8a5ebb6b5bf469a7e0e2b5202cf6f8c291104"
uuid = "da1fd8a2-8d9e-5ec2-8556-3022fb5608a2"
version = "1.0.6"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "Colors", "FixedPointNumbers", "Random"]
git-tree-sha1 = "a851fec56cb73cfdf43762999ec72eff5b86882a"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.15.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "3f1f500312161f1ae067abe07d13b40f78f32e07"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.8"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[deps.CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "44c37b4636bc54afac5c574d2d02b625349d6582"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.41.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.ComputationalResources]]
git-tree-sha1 = "52cb3ec90e8a8bea0e62e275ba577ad0f74821f7"
uuid = "ed09eef8-17a6-5b46-8889-db040fac31e3"
version = "0.3.2"

[[deps.Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[deps.Crayons]]
git-tree-sha1 = "3f71217b538d7aaee0b69ab47d9b7724ca8afa0d"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.0.4"

[[deps.CustomUnitRanges]]
git-tree-sha1 = "1a3f97f907e6dd8983b744d2642651bb162a3f7a"
uuid = "dc8bdbbb-1ca9-579f-8c36-e416f6a65cce"
version = "1.0.2"

[[deps.DataAPI]]
git-tree-sha1 = "cc70b17275652eb47bc9e5f81635981f13cea5c8"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.9.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "2e993336a3f68216be91eb8ee4625ebbaba19147"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.3.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3daef5523dd2e769dad2365274f760ff5f282c7d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.11"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.DataValues]]
deps = ["DataValueInterfaces", "Dates"]
git-tree-sha1 = "d88a19299eba280a6d062e135a43f00323ae70bf"
uuid = "e7dc6d0d-1eca-5fa6-8ad6-5aecde8b7ea5"
version = "0.4.13"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[deps.DiffResults]]
deps = ["StaticArrays"]
git-tree-sha1 = "c18e98cba888c6c25d1c3b048e4b3380ca956805"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.0.3"

[[deps.DiffRules]]
deps = ["LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "9bc5dac3c8b6706b58ad5ce24cffd9861f07c94f"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.9.0"

[[deps.Distances]]
deps = ["LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "3258d0659f812acde79e8a74b11f17ac06d0ca04"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.7"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["ChainRulesCore", "DensityInterface", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "c1724611e6ae29c6094c8d9850e3136297ba7fff"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.36"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[deps.Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3f3a2501fa7236e9b911e0f7a588c657e822bb6d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.3+0"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b3bfd02e98aedfa5cf885665493c5598c350cd2f"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.2.10+0"

[[deps.ExprTools]]
git-tree-sha1 = "b7e3d17636b348f005f11040025ae8c6f645fe92"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.6"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "Pkg", "Zlib_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "d8a578692e3077ac998b50c0217dfd67f21d1e5f"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.0+0"

[[deps.FFTViews]]
deps = ["CustomUnitRanges", "FFTW"]
git-tree-sha1 = "cbdf14d1e8c7c8aacbe8b19862e0179fd08321c2"
uuid = "4f61f5a4-77b1-5117-aa51-3ab5ef4ef0cd"
version = "0.3.2"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "463cb335fa22c4ebacfd1faba5fde14edb80d96c"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.4.5"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "04d13bfa8ef11720c24e4d840c0033d145537df7"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.17"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "8756f9935b7ccc9064c6eef0bff0ad643df733a3"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.12.7"

[[deps.FiniteDiff]]
deps = ["ArrayInterface", "LinearAlgebra", "Requires", "SparseArrays", "StaticArrays"]
git-tree-sha1 = "8b3c09b56acaf3c0e581c66638b85c8650ee9dca"
uuid = "6a86dc24-6348-571c-b903-95158fe2bd41"
version = "2.8.1"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Flux]]
deps = ["AbstractTrees", "Adapt", "ArrayInterface", "CUDA", "CodecZlib", "Colors", "DelimitedFiles", "Functors", "Juno", "LinearAlgebra", "MacroTools", "NNlib", "NNlibCUDA", "Pkg", "Printf", "Random", "Reexport", "SHA", "SparseArrays", "Statistics", "StatsBase", "Test", "ZipFile", "Zygote"]
git-tree-sha1 = "e8b37bb43c01eed0418821d1f9d20eca5ba6ab21"
uuid = "587475ba-b771-5e3f-ad9e-33799f191a9c"
version = "0.12.8"

[[deps.FluxArchitectures]]
deps = ["BSON", "Flux", "JuliennedArrays", "LazyArtifacts", "Random", "Reexport", "Revise", "SliceMap", "Tables", "Zygote"]
git-tree-sha1 = "ea4c811a577d84f2c25e0b59a30dde3c97f91e66"
uuid = "53d20848-f986-4c56-957e-0e417ec068db"
version = "0.1.4"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "2b72a5624e289ee18256111657663721d59c143e"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.24"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.FunctionalCollections]]
deps = ["Test"]
git-tree-sha1 = "04cb9cfaa6ba5311973994fe3496ddec19b6292a"
uuid = "de31a74c-ac4f-5751-b3fd-e18cd04993ca"
version = "0.5.0"

[[deps.Functors]]
git-tree-sha1 = "e4768c3b7f597d5a352afa09874d16e3c3f6ead2"
uuid = "d9f16b24-f501-4c13-a1f2-28368ffc5196"
version = "0.2.7"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "0c603255764a1fa0b61752d2bec14cfbd18f7fe8"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.5+1"

[[deps.GPUArrays]]
deps = ["Adapt", "LinearAlgebra", "Printf", "Random", "Serialization", "Statistics"]
git-tree-sha1 = "d9681e61fbce7dde48684b40bdb1a319c4083be7"
uuid = "0c68f7d7-f131-5f86-a1c3-88cf8149b2d7"
version = "8.1.3"

[[deps.GPUCompiler]]
deps = ["ExprTools", "InteractiveUtils", "LLVM", "Libdl", "Logging", "TimerOutputs", "UUIDs"]
git-tree-sha1 = "2cac236070c2c4b36de54ae9146b55ee2c34ac7a"
uuid = "61eb1bfa-7361-4325-ad38-22787b887f55"
version = "0.13.10"

[[deps.GR]]
deps = ["Base64", "DelimitedFiles", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Printf", "Random", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "30f2b340c2fff8410d89bfcdc9c0a6dd661ac5f7"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.62.1"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "fd75fa3a2080109a2c0ec9864a6e14c60cca3866"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.62.0+0"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "58bcdf5ebc057b085e58d95c138725628dd7453c"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.1"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "a32d672ac2c967f3deb8a81d828afc739c838a06"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.68.3+2"

[[deps.Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "1c5a84319923bea76fa145d49e93aa4394c73fc2"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.1"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "0fa77022fe4b511826b39c894c90daf5fce3334a"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.17"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.Hiccup]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "6187bb2d5fcbb2007c39e7ac53308b0d371124bd"
uuid = "9fb69e20-1954-56bb-a84f-559cc56a8ff7"
version = "0.2.2"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
git-tree-sha1 = "2b078b5a615c6c0396c77810d92ee8c6f470d238"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.3"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.IRTools]]
deps = ["InteractiveUtils", "MacroTools", "Test"]
git-tree-sha1 = "006127162a51f0effbdfaab5ac0c83f8eb7ea8f3"
uuid = "7869d1d1-7146-5819-86e3-90919afe41df"
version = "0.4.4"

[[deps.IfElse]]
git-tree-sha1 = "debdd00ffef04665ccbb3e150747a77560e8fad1"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.1"

[[deps.ImageBase]]
deps = ["ImageCore", "Reexport"]
git-tree-sha1 = "b51bb8cae22c66d0f6357e3bcb6363145ef20835"
uuid = "c817782e-172a-44cc-b673-b171935fbb9e"
version = "0.1.5"

[[deps.ImageCore]]
deps = ["AbstractFFTs", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Graphics", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "Reexport"]
git-tree-sha1 = "9a5c62f231e5bba35695a20988fc7cd6de7eeb5a"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.9.3"

[[deps.ImageFiltering]]
deps = ["CatIndices", "ComputationalResources", "DataStructures", "FFTViews", "FFTW", "ImageBase", "ImageCore", "LinearAlgebra", "OffsetArrays", "Reexport", "SparseArrays", "StaticArrays", "Statistics", "TiledIteration"]
git-tree-sha1 = "15bd05c1c0d5dbb32a9a3d7e0ad2d50dd6167189"
uuid = "6a3955dd-da59-5b1f-98d4-e7296123deb5"
version = "0.7.1"

[[deps.IniFile]]
deps = ["Test"]
git-tree-sha1 = "098e4d2c533924c921f9f9847274f2ad89e018b8"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.0"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "8d70835a3759cdd75881426fced1508bb7b7e1b6"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.1.1"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d979e54b71da82f3a65b62553da4fc3d18c9004c"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2018.0.3+2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Interpolations]]
deps = ["AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "b15fc0a95c564ca2e0a7ae12c1f095ca848ceb31"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.13.5"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "a7254c0acd8e62f1ac75ad24d5db43f5f19f3c65"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.2"

[[deps.InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.IterTools]]
git-tree-sha1 = "fa6287a4469f5e048d763df38279ee729fbd44e5"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.4.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "642a199af8b68253517b80bd3bfd17eb4e84df6e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.3.0"

[[deps.JSExpr]]
deps = ["JSON", "MacroTools", "Observables", "WebIO"]
git-tree-sha1 = "bd6c034156b1e7295450a219c4340e32e50b08b1"
uuid = "97c1335a-c9c5-57fe-bc5d-ec35cebe8660"
version = "0.5.3"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d735490ac75c5cb9f1b00d8b5509c11984dc6943"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.0+0"

[[deps.JuliaInterpreter]]
deps = ["CodeTracking", "InteractiveUtils", "Random", "UUIDs"]
git-tree-sha1 = "a2366b16704ffe78be1831341e6799ab2f4f07d2"
uuid = "aa1ae85d-cabe-5617-a682-6adf51b2e16a"
version = "0.9.0"

[[deps.JuliennedArrays]]
git-tree-sha1 = "4aeebbfcf0615641ec4b0782b73b638eeeabd62e"
uuid = "5cadff95-7770-533d-a838-a1bf817ee6e0"
version = "0.3.0"

[[deps.Juno]]
deps = ["Base64", "Logging", "Media", "Profile"]
git-tree-sha1 = "07cb43290a840908a771552911a6274bc6c072c7"
uuid = "e5e0dc1b-0480-54bc-9374-aad01c23163d"
version = "0.8.4"

[[deps.Kaleido_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "2ef87eeaa28713cb010f9fb0be288b6c1a4ecd53"
uuid = "f7e6163d-2fa5-5f23-b69c-1db539e41963"
version = "0.1.0+0"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "591e8dc09ad18386189610acafb970032c519707"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.3"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LLVM]]
deps = ["CEnum", "LLVMExtra_jll", "Libdl", "Printf", "Unicode"]
git-tree-sha1 = "f8dcd7adfda0dddaf944e62476d823164cccc217"
uuid = "929cbde3-209d-540e-8aea-75f648917ca0"
version = "4.7.1"

[[deps.LLVMExtra_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "67cc5406b15bd04ff72a45f628bec61d36078908"
uuid = "dad2f222-ce93-54a1-a47d-0025e8a3acab"
version = "0.0.13+3"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "Printf", "Requires"]
git-tree-sha1 = "a8f4f279b6fa3c3c4f1adadd78a621b13a506bce"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.9"

[[deps.Lazy]]
deps = ["MacroTools"]
git-tree-sha1 = "1370f8202dac30758f3c345f9909b97f53d87d3f"
uuid = "50d2b5c4-7a5e-59d5-8109-a42b560f39c0"
version = "0.15.1"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "7739f837d6447403596a75d19ed01fd08d6f56bf"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.3.0+3"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "c9551dd26e31ab17b86cbd00c2ede019c08758eb"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.3.0+1"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LineSearches]]
deps = ["LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "Printf"]
git-tree-sha1 = "f27132e551e959b3667d8c93eae90973225032dd"
uuid = "d3d80556-e9d4-5f37-9878-2ab0fcc64255"
version = "7.1.1"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "be9eef9f9d78cecb6f262f3c10da151a6c5ab827"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.5"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoweredCodeUtils]]
deps = ["JuliaInterpreter"]
git-tree-sha1 = "f46e8f4e38882b32dcc11c8d31c131d556063f39"
uuid = "6f1432cf-f94c-5a45-995e-cdbf5db27b0b"
version = "2.2.0"

[[deps.LsqFit]]
deps = ["Distributions", "ForwardDiff", "LinearAlgebra", "NLSolversBase", "OptimBase", "Random", "StatsBase"]
git-tree-sha1 = "91aa1442e63a77f101aff01dec5a821a17f43922"
uuid = "2fda8390-95c7-5789-9bda-21331edee243"
version = "0.12.1"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "5455aef09b40e5020e1520f551fa3135040d4ed0"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2021.1.1+2"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.MappedArrays]]
git-tree-sha1 = "e8b359ef06ec72e8c030463fe02efe5527ee5142"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.1"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Measures]]
git-tree-sha1 = "e498ddeee6f9fdb4551ce855a46f54dbd900245f"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.1"

[[deps.Media]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "75a54abd10709c01f1b86b84ec225d26e840ed58"
uuid = "e89f7d12-3494-54d1-8411-f7d8b9ae1f27"
version = "0.5.0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.Mocking]]
deps = ["Compat", "ExprTools"]
git-tree-sha1 = "29714d0a7a8083bba8427a4fbfb00a540c681ce7"
uuid = "78c3b35d-d492-501b-9361-3d52fe80e533"
version = "0.7.3"

[[deps.MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "b34e3bc3ca7c94914418637cb10cc4d1d80d877d"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.3"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.MultivariateStats]]
deps = ["Arpack", "LinearAlgebra", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "8d958ff1854b166003238fe191ec34b9d592860a"
uuid = "6f286f6a-111f-5878-ab1e-185364afe411"
version = "0.8.0"

[[deps.Mustache]]
deps = ["Printf", "Tables"]
git-tree-sha1 = "21d7a05c3b94bcf45af67beccab4f2a1f4a3c30a"
uuid = "ffc61752-8dc7-55ee-8c37-f3e9cdd09e70"
version = "1.0.12"

[[deps.Mux]]
deps = ["AssetRegistry", "Base64", "HTTP", "Hiccup", "Pkg", "Sockets", "WebSockets"]
git-tree-sha1 = "82dfb2cead9895e10ee1b0ca37a01088456c4364"
uuid = "a975b10e-0019-58db-a62f-e48ff68538c9"
version = "0.7.6"

[[deps.NLSolversBase]]
deps = ["DiffResults", "Distributed", "FiniteDiff", "ForwardDiff"]
git-tree-sha1 = "50310f934e55e5ca3912fb941dec199b49ca9b68"
uuid = "d41bc354-129a-5804-8e4c-c37616107c6c"
version = "7.8.2"

[[deps.NNlib]]
deps = ["Adapt", "ChainRulesCore", "Compat", "LinearAlgebra", "Pkg", "Requires", "Statistics"]
git-tree-sha1 = "afcfd88042cc5a62743c98ca311668ff5c03148a"
uuid = "872c559c-99b0-510c-b3b7-b6c96a88d5cd"
version = "0.7.32"

[[deps.NNlibCUDA]]
deps = ["CUDA", "LinearAlgebra", "NNlib", "Random", "Statistics"]
git-tree-sha1 = "a2dc748c9f6615197b6b97c10bcce829830574c9"
uuid = "a00861dc-f156-4864-bf3c-e6376f28a68d"
version = "0.1.11"

[[deps.NaNMath]]
git-tree-sha1 = "bfe47e760d60b82b66b61d2d44128b62e3a369fb"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.5"

[[deps.NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "16baacfdc8758bc374882566c9187e785e85c2f0"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.9"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.Observables]]
git-tree-sha1 = "fe29afdef3d0c4a8286128d4e45cc50621b1e43d"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.4.0"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "043017e0bdeff61cfbb7afeb558ab29536bbb5ed"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.10.8"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "15003dcb7d8db3c6c857fda14891a539a8f2705a"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.10+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Optim]]
deps = ["Compat", "FillArrays", "ForwardDiff", "LineSearches", "LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "PositiveFactorizations", "Printf", "SparseArrays", "StatsBase"]
git-tree-sha1 = "35d435b512fbab1d1a29138b5229279925eba369"
uuid = "429524aa-4258-5aef-a3af-852621145aeb"
version = "1.5.0"

[[deps.OptimBase]]
deps = ["NLSolversBase", "Printf", "Reexport"]
git-tree-sha1 = "9cb1fee807b599b5f803809e85c81b582d2009d6"
uuid = "87e2bd06-a317-5318-96d9-3ecbac512eee"
version = "2.0.2"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.PCRE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b2a7af664e098055a7529ad1a900ded962bca488"
uuid = "2f80f16e-611a-54ab-bc61-aa92de5b98fc"
version = "8.44.0+0"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "ee26b350276c51697c9c2d88a072b339f9f03d73"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.5"

[[deps.PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "646eed6f6a5d8df6708f15ea7e02a7a2c4fe4800"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.10"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "ae4bbcadb2906ccc085cf52ac286dc1377dceccc"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.1.2"

[[deps.Pidfile]]
deps = ["FileWatching", "Test"]
git-tree-sha1 = "1be8660b2064893cd2dae4bd004b589278e4440d"
uuid = "fa939f87-e72e-5be4-a000-7fc836dbe307"
version = "1.2.0"

[[deps.Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Requires", "Statistics"]
git-tree-sha1 = "a3a964ce9dc7898193536002a6dd892b1b5a6f1d"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "2.0.1"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "e4fe0b50af3130ddd25e793b471cb43d5279e3e6"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.1.1"

[[deps.PlotlyBase]]
deps = ["ColorSchemes", "Dates", "DelimitedFiles", "DocStringExtensions", "JSON", "LaTeXStrings", "Logging", "Parameters", "Pkg", "REPL", "Requires", "Statistics", "UUIDs"]
git-tree-sha1 = "180d744848ba316a3d0fdf4dbd34b77c7242963a"
uuid = "a03496cd-edff-5a9b-9e67-9cda94a718b5"
version = "0.8.18"

[[deps.PlotlyJS]]
deps = ["Base64", "Blink", "DelimitedFiles", "JSExpr", "JSON", "Kaleido_jll", "Markdown", "Pkg", "PlotlyBase", "REPL", "Reexport", "Requires", "WebIO"]
git-tree-sha1 = "53d6325e14d3bdb85fd387a085075f36082f35a3"
uuid = "f0f68f2c-4968-5e81-91da-67840de0976a"
version = "0.18.8"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "GeometryBasics", "JSON", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "PlotThemes", "PlotUtils", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun"]
git-tree-sha1 = "65ebc27d8c00c84276f14aaf4ff63cbe12016c70"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.25.2"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "5152abbdab6488d5eec6a01029ca6697dff4ec8f"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.23"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "db3a23166af8aebf4db5ef87ac5b00d36eb771e2"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.0"

[[deps.PositiveFactorizations]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "17275485f373e6673f7e7f97051f703ed5b15b20"
uuid = "85a6dd25-e78a-55b7-8502-1745935b8125"
version = "0.2.4"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00cfd92944ca9c760982747e9a1d0d5d86ab1e5a"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.2"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "d940010be611ee9d67064fe559edbb305f8cc0eb"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.2.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "c6c0f690d0cc7caddb74cef7aa847b824a16b256"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+1"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "78aadffb3efd2155af139781b8a8df1ef279ea39"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.4.2"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Random123]]
deps = ["Libdl", "Random", "RandomNumbers"]
git-tree-sha1 = "0e8b146557ad1c6deb1367655e052276690e71a3"
uuid = "74087812-796a-5b5d-8853-05524746bad3"
version = "1.4.2"

[[deps.RandomNumbers]]
deps = ["Random", "Requires"]
git-tree-sha1 = "043da614cc7e95c703498a491e2c21f58a2b8111"
uuid = "e6cf234a-135c-5ec9-84dd-332b85af5143"
version = "1.5.3"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "01d341f502250e81f6fec0afe662aa861392a3aa"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.2"

[[deps.RealDot]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "9f0a1b71baaf7650f4fa8a1d168c7fb6ee41f0c9"
uuid = "c1ae055f-0cd5-4b69-90a6-9a35b1a98df9"
version = "0.1.0"

[[deps.RecipesBase]]
git-tree-sha1 = "6bf3f380ff52ce0832ddd3a2a7b9538ed1bcca7d"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.2.1"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase"]
git-tree-sha1 = "7ad0dfa8d03b7bcf8c597f59f5292801730c55b8"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.4.1"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "8f82019e525f4d5c669692772a6f4b0a58b06a6a"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.2.0"

[[deps.Revise]]
deps = ["CodeTracking", "Distributed", "FileWatching", "JuliaInterpreter", "LibGit2", "LoweredCodeUtils", "OrderedCollections", "Pkg", "REPL", "Requires", "UUIDs", "Unicode"]
git-tree-sha1 = "2f9d4d6679b5f0394c52731db3794166f49d5131"
uuid = "295af30f-e4ad-537b-8983-00126c2a3abe"
version = "3.3.1"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "244586bc07462d22aed0113af9c731f2a518c93e"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.10"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SliceMap]]
deps = ["ForwardDiff", "JuliennedArrays", "StaticArrays", "Tracker", "ZygoteRules"]
git-tree-sha1 = "dedda55df795e59a8a7a941ae5627fa1cd87e16a"
uuid = "82cb661a-3f19-5665-9e27-df437c7e54c8"
version = "0.2.6"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "e08890d19787ec25029113e88c34ec20cac1c91e"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.0.0"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

[[deps.Static]]
deps = ["IfElse"]
git-tree-sha1 = "7f5a513baec6f122401abfc8e9c074fdac54f6c1"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "0.4.1"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "3c76dde64d03699e074ac02eb2e8ba8254d428da"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.2.13"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
git-tree-sha1 = "0f2aa8e32d511f758a2ce49208181f7733a0936a"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.1.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "2bb0cb32026a66037360606510fca5984ccc6b75"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.13"

[[deps.StatsFuns]]
deps = ["ChainRulesCore", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "bedb3e17cc1d94ce0e6e66d3afa47157978ba404"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "0.9.14"

[[deps.StatsPlots]]
deps = ["Clustering", "DataStructures", "DataValues", "Distributions", "Interpolations", "KernelDensity", "LinearAlgebra", "MultivariateStats", "Observables", "Plots", "RecipesBase", "RecipesPipeline", "Reexport", "StatsBase", "TableOperations", "Tables", "Widgets"]
git-tree-sha1 = "d6956cefe3766a8eb5caae9226118bb0ac61c8ac"
uuid = "f3b207a7-027a-5e70-b257-86293d7955fd"
version = "0.14.29"

[[deps.StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArrays", "Tables"]
git-tree-sha1 = "2ce41e0d042c60ecd131e9fb7154a3bfadbf50d3"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.3"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.TableOperations]]
deps = ["SentinelArrays", "Tables", "Test"]
git-tree-sha1 = "e383c87cf2a1dc41fa30c093b2a19877c83e1bc1"
uuid = "ab02a1b2-a7df-11e8-156e-fb1833f50b87"
version = "1.2.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "TableTraits", "Test"]
git-tree-sha1 = "bb1064c9a84c52e277f1096cf41434b675cd368b"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.6.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TiledIteration]]
deps = ["OffsetArrays"]
git-tree-sha1 = "5683455224ba92ef59db72d10690690f4a8dc297"
uuid = "06e1c1a7-607b-532d-9fad-de7d9aa2abac"
version = "0.3.1"

[[deps.TimeZones]]
deps = ["Dates", "Downloads", "InlineStrings", "LazyArtifacts", "Mocking", "Printf", "RecipesBase", "Serialization", "Unicode"]
git-tree-sha1 = "ce5aab0b0146b81efefae52f13002e19c2af57ac"
uuid = "f269a46b-ccf7-5d73-abea-4c690281aa53"
version = "1.7.0"

[[deps.TimerOutputs]]
deps = ["ExprTools", "Printf"]
git-tree-sha1 = "a5aed757f65c8a1c64503bc4035f704d24c749bf"
uuid = "a759f4b9-e2f1-59dc-863e-4aeb61b1ea8f"
version = "0.5.14"

[[deps.Tracker]]
deps = ["Adapt", "DiffRules", "ForwardDiff", "LinearAlgebra", "MacroTools", "NNlib", "NaNMath", "Printf", "Random", "Requires", "SpecialFunctions", "Statistics"]
git-tree-sha1 = "95dc67d124fc57e348987211b5e8ce2e29a7f8dc"
uuid = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
version = "0.2.17"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[deps.URIParser]]
deps = ["Unicode"]
git-tree-sha1 = "53a9f49546b8d2dd2e688d216421d050c9a31d0d"
uuid = "30578b45-9adc-5946-b283-645ec420af67"
version = "0.4.1"

[[deps.URIs]]
git-tree-sha1 = "97bbe755a53fe859669cd907f2d96aee8d2c1355"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.3.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Wayland_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "3e61f0b86f90dacb0bc0e73a0c5a83f6a8636e23"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.19.0+0"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "66d72dc6fcc86352f01676e8f0f698562e60510f"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.23.0+0"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "c69f9da3ff2f4f02e811c3323c22e5dfcb584cfa"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.1"

[[deps.WebIO]]
deps = ["AssetRegistry", "Base64", "Distributed", "FunctionalCollections", "JSON", "Logging", "Observables", "Pkg", "Random", "Requires", "Sockets", "UUIDs", "WebSockets", "Widgets"]
git-tree-sha1 = "5fe32e4086d49f7ab9b087296742859f3ae6d62a"
uuid = "0f1e0344-ec1d-5b48-a673-e5cf874b6c29"
version = "0.8.16"

[[deps.WebSockets]]
deps = ["Base64", "Dates", "HTTP", "Logging", "Sockets"]
git-tree-sha1 = "f91a602e25fe6b89afc93cf02a4ae18ee9384ce3"
uuid = "104b5d7c-a370-577a-8038-80a2059c5097"
version = "1.5.9"

[[deps.Widgets]]
deps = ["Colors", "Dates", "Observables", "OrderedCollections"]
git-tree-sha1 = "80661f59d28714632132c73779f8becc19a113f2"
uuid = "cc8bc4a8-27d6-5769-a93b-9d913e69aa62"
version = "0.6.4"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "1acf5bdf07aa0907e0a37d3718bb88d4b687b74a"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.12+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[deps.ZipFile]]
deps = ["Libdl", "Printf", "Zlib_jll"]
git-tree-sha1 = "3593e69e469d2111389a9bd06bac1f3d730ac6de"
uuid = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"
version = "0.9.4"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "cc4bf3fdde8b7e3e9fa0351bdeedba1cf3b7f6e6"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.0+0"

[[deps.Zygote]]
deps = ["AbstractFFTs", "ChainRules", "ChainRulesCore", "DiffRules", "Distributed", "FillArrays", "ForwardDiff", "IRTools", "InteractiveUtils", "LinearAlgebra", "MacroTools", "NaNMath", "Random", "Requires", "SpecialFunctions", "Statistics", "ZygoteRules"]
git-tree-sha1 = "78da1a0a69bcc86b33f7cb07bc1566c926412de3"
uuid = "e88e6eb3-aa80-5325-afca-941959d7151f"
version = "0.6.33"

[[deps.ZygoteRules]]
deps = ["MacroTools"]
git-tree-sha1 = "8c1a8e4dfacb1fd631745552c8db35d0deb09ea0"
uuid = "700de1a5-db45-46bc-99cf-38207098b444"
version = "0.2.2"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "ece2350174195bb31de1a63bea3a41ae1aa593b6"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "0.9.1+5"
"""

# ╔═╡ Cell order:
# ╠═bb6cae46-4108-11eb-2309-3d11f13a19fa
# ╠═d8b334ae-4108-11eb-2546-99e75efc18d6
# ╠═7f15b8d8-17d9-4b89-aedb-99ff090a91ea
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
# ╠═04dbf36e-b45f-479b-8876-f48e0ad520a0
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
# ╠═5d8ac6af-1911-4583-9907-7d4f58d7863c
# ╠═147e2cf8-5bfc-4e52-9105-e6ccd8b466da
# ╠═48f4d8c8-37b5-4c2d-aabb-4a0590bffffb
# ╠═bf9dfb10-9fe3-48d3-a299-0e8c9744ac29
# ╠═4486854d-f57c-4c7d-9866-a50d3f31d1cd
# ╠═ff202e82-e45e-410d-9158-37f7b5de1fbc
# ╠═83dad0ff-128d-4ca4-a9d4-447088cb577b
# ╠═08e97dd2-a870-43e0-8c91-4c6b605b664f
# ╠═4fdd4194-a041-4701-ba7e-47e12dc61e31
# ╠═daab5fb2-355d-49ca-9268-3f6e40d7b0a1
# ╠═bc94dcb4-7f2a-422c-8e36-a23b1fc47fa9
# ╟─2e6ade2d-52d4-42cc-b7ee-332b4bcf4634
# ╠═59bfbded-8aaa-4797-a588-18b2f946e57a
# ╠═e064f170-fea2-4dbe-a0d9-f290661105a9
# ╠═c179a703-3955-4353-8a1e-a01b610335f1
# ╠═d2119115-2dc5-4271-9722-6570ec54851b
# ╠═9131bfb2-5144-46f7-9ee7-db03290ad930
# ╠═b35767b7-cde8-4b4b-bac6-6aeaf17f53ff
# ╠═4d7a04cc-dd16-4d01-b724-4ea42333e8fe
# ╟─e68e2172-43f9-4add-80cd-5b221e5981e8
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
# ╠═dc1ed460-4c72-4d9b-b8e5-8b975cfc247f
# ╠═7f5be60a-5b23-11eb-3d24-d17513534e16
# ╠═5123d73c-6c9b-11eb-0231-675c2b98d0d3
# ╠═d8ed8d5c-6c9b-11eb-2215-2fb6b80d30e2
# ╠═d5b5cf78-5a87-11eb-1d85-176632857548
# ╠═620a967e-5b2f-11eb-3dc5-6108d315124b
# ╠═61991d43-ad43-4638-ad38-b3e6d3d8cb63
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
