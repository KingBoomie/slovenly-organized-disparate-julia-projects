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

# ╔═╡ 89b8e562-1252-11ec-17ca-cf7517afb20e
begin
	using Pkg
	using PlutoUI
	using StatsBase
	using DataStructures
	using DataFrames
	using CSV
	using TimeZones
	using Dates
	using OffsetArrays
	using Chain
	using XLSX
	using AlgebraOfGraphics
	using CairoMakie
	using HypertextLiteral
	using CategoricalArrays
	using Graphs
	using MetaGraphs
	using GraphPlot
	using SGtSNEpi
	using Colors
end

# ╔═╡ 17bee913-4365-4008-ade7-8059cf5cc22c
begin
	using Statistics
	using TexTables
end

# ╔═╡ 4be35008-86b4-418a-b754-d70511b2a852
TableOfContents()

# ╔═╡ 4a7c2832-4465-4738-b875-b0bfc59fba7e
cd("/home/kris/learning/heategevus2020/data")

# ╔═╡ d823fc97-b613-44cc-a5f1-62a22ca41abc
md"""absoluutse muutuse osakaal: $(@bind abs_importance PlutoUI.Slider(0:0.1:5, default=0.2,show_value=true))    \
relatiivse muutuse osakaal: $(@bind rel_importance PlutoUI.Slider(0:0.1:5, default=2,show_value=true))    \
absoluutse summa osakaal: $(@bind sum_importance PlutoUI.Slider(0:0.1:5, default=1,show_value=true))    \
"""

# ╔═╡ 9c027964-6cb9-4406-a7d5-22081f4773fd
md"## kõik üle 100 000€ saajad, kelle tulu on eelmise aastaga päris palju muutunud    

P.S. all tabelis rea peale vajutades tehakse selle MTÜ kohta läbi aastate muutumise graafikud"

# ╔═╡ a615112c-a3e6-42fa-b99a-986831c9a9fd
tulud = [:KINGITUS_TULU :TOETUSE_TULU :LIIKMEMAKSU_TULU :MAJANDUS_TULU :MUU_TULU];

# ╔═╡ 6e68d35b-f386-4c20-b25a-794c4c49a1e4
tulu_nimed = ["kingitus" "toetus" "liikmemaks" "majandus" "muu"];

# ╔═╡ 82003b0c-0f65-4348-8bb3-4bc93bc8b487
tuluk = dims(2) => renamer(tulu_nimed);

# ╔═╡ 5e959a31-313f-4bba-9154-79d2bb6a85d4
tulu_map = mapping(:AASTA, tulud .=> "tulud", stack=tuluk, color=tuluk);

# ╔═╡ 40414329-7d7f-4a85-b5c1-42f889696b97
md"## kõik üle 100 000€ saajad, kes eelmisel aastal märkisid suure osa oma tulust teise kategooriasse"

# ╔═╡ c0ae2c9b-18fd-4303-b60c-d6ad6e56f772
rel_cols = [ :KINGITUS_TULU_muutus_rel, :TOETUSE_TULU_muutus_rel] # Symbol.(names(res, r"rel"))

# ╔═╡ 81639687-8845-4ebe-a94c-171fbf2c763b
md"# data"

# ╔═╡ 93bda779-ca59-46d6-bdd5-8670a594b15e
md"## inf4 füüsilised isikud"

# ╔═╡ e033ea39-f324-4618-a760-c5bd18a3b5c8
function sugu_vanus(isik)
	year_start = isik[1] ∈ ('3','4') ? 1900 : 2000
	gender = isik[1] ∈ ('3','5') ? :mees : :naine
	year_end = parse(Int, isik[2:3])
	(sugu=gender, vanus=2020 - (year_start + year_end))
end

# ╔═╡ 50375d3c-2244-4137-b3c5-ebfd3861a7c1
col_mapping_4f = Dict(zip(["ISIK_KOOD", "IK_ALGUS"], ["KOOD", "ISIK"]))

# ╔═╡ eb1f7822-8614-461a-bd22-12f25cdfba01
inf4_f = @chain XLSX.readtable("INF4_knd_2020_F2.xlsx", "Export") begin
	DataFrame(_...)
	rename!(col_mapping_4f)
	transform(:KOOD => ByRow(k -> parse(Int, k)) => :KOOD)
	transform(:AASTA => ByRow(k -> convert(Int, k)) => :AASTA)
	transform(:ISIK => ByRow(sugu_vanus) => AsTable)
	transform(:JRKNR => ByRow(k -> convert(Int, k)) => :JRKNR)
end

# ╔═╡ d1b61f6a-6439-4fd2-9cae-9f6c5bc23e6f
md"## inf4 juriidilised isikud"

# ╔═╡ 9cb10585-a20d-4c8b-9c2d-358cdc0a7c8d
col_mapping_4j = Dict(zip(["Annetuse saaja reg.kood"], ["KOOD"]))

# ╔═╡ 9050790e-47ca-4196-8567-59e5c591cfa7
inf4_j = @chain XLSX.readtable("INF4_knd_2020_Juriidilised isikud.xlsx", "Export") begin
	DataFrame(_...)
	rename!(col_mapping_4j)
	transform(:KOOD => ByRow(k -> parse(Int, k)) => :KOOD)
	transform(:AASTA => ByRow(k -> convert(Int, k)) => :AASTA)
end

# ╔═╡ 2eb2b55d-38a5-4270-a443-a4b43da1dbe0
md"## inf4 combined"

# ╔═╡ bf422f25-bee2-4e5c-a92f-912f5c4ba4ce
shared_cols = [:AASTA, :KOOD, :SUMMA]

# ╔═╡ 267f1ce1-9df4-472b-a5ea-c19cf65a94c6
inf4 = vcat(inf4_j[!, shared_cols], inf4_f[!, shared_cols])

# ╔═╡ f91c060d-484c-4679-9a5d-664adb540559
md"## inf9"

# ╔═╡ 654e87b3-d8a3-47e7-b798-be476af899a3
begin
	from_colnames = ["Reg. nr.", "Aasta", "Nimi"]
	to_colnames   = ["KOOD", "AASTA", "NIMI"]
	col_mapping = Dict(zip(from_colnames, to_colnames))
	inf9_bins = [0, 6000, 80000, 3E8]
	
	inf9_labels = ["small", "medium", "large"]
	inf9_labels2 = ["väike MTÜ (<6037€)", "keskmine MTÜ (<79690€)", "suur MTÜ"]
end

# ╔═╡ 51fecba7-ec97-422e-bb58-65f4fd33855e
inf9 = @chain XLSX.readtable("INF9_knd_2020.xlsx", "Export") begin
	DataFrame(_...)
	rename!(col_mapping)
	transform(:KOOD => ByRow(k -> parse(Int, k)) => :KOOD)
	transform(:AASTA => ByRow(k -> convert(Int, k)) => :AASTA)
	transform(4 => (x -> cut(x, inf9_bins, labels=inf9_labels)) => :suurus) # väike ~ 75% MTÜdest, keskmine 75-95, suur 95-100%
end

# ╔═╡ b396ea76-6347-4ab3-b82e-a6e10b332dae
begin
	from_colnames1 = ["Kingitused ja annetused (19000)", "Toetused ja eraldised (19010)", "Liikme- ja sisseastumis-maksud (19020)", "Majandus- tegevusest saadud tulu (19030)", "Muud tulud (19040)", "suurus"]
	to_colnames1   = ["KINGITUS_TULU", "TOETUSE_TULU", "LIIKMEMAKSU_TULU", "MAJANDUS_TULU", "MUU_TULU", "suurus"]
	col_mapping1 = Dict(zip(from_colnames1, to_colnames1))
end

# ╔═╡ 4d17e42e-f1eb-4c8c-9272-fc1edf359cf8
kood_nimi = select(inf9, :KOOD, :NIMI, :suurus)

# ╔═╡ 17bf6a38-b72a-42f7-89cb-3faa76f3aa7b
inf9_old = @chain begin
	DataFrame(XLSX.readtable("Copy of INF9 2015-19 Parandatud.xlsx", "9_19")...)
	select(Not([Symbol("Annetuste % tuludest"), :tegevusala]))
	transform!(4 => (x -> cut(x, inf9_bins, labels=inf9_labels)) => :suurus)
end

# ╔═╡ ba52539d-9387-4f06-9ae1-d12a07b5c2d7
inf9_columns = names(inf9_old)

# ╔═╡ b85895bd-20c7-4887-beca-4100840aadc8
year_inf9 = [2015 => "9_15", 2016 => "9_16", 2017 => "9_17", 2018 => "9_18", 2019 => "9_19"]

# ╔═╡ 11c48240-609b-4414-98f9-a7be19c9653d
inf9_old2 = map(year_inf9) do (year, year_name)
	df = DataFrame(XLSX.readtable("Copy of INF9 2015-19 Parandatud.xlsx", year_name)...)
	df.AASTA .= year
	transform!(df, 4 => (x -> cut(x, inf9_bins, labels=inf9_labels)) => :suurus)
	select!(df, inf9_columns)
	dropmissing!(df, [:KOOD, :NIMI])
end

# ╔═╡ b55c67cd-701a-426c-8d33-8309be6a39ef
begin
	inf9_all2 = vcat(inf9, inf9_old2...)
	rename!(inf9_all2, col_mapping1)
end

# ╔═╡ a47dceb2-cdaa-4c4f-82be-d27fd75471cd
begin
	inf9_all = vcat(inf9, inf9_old)
	rename!(inf9_all, col_mapping1)
end

# ╔═╡ 7d3937ac-1cca-4c56-8830-162ebdd46b7b
function muutus_rel(x)
	rel = x[1] / x[2]
	# abso = x[1] - x[2] 
	
	if isinf(rel)
		return 1000 * rel_importance
	elseif isnan(rel)
		return 0
	end
	abs(1-rel) * rel_importance
end

# ╔═╡ b22e0cc3-c134-4815-9f1e-2b6cca3778a1
muutus_abs(x) = log10(abs(x[1] - x[2]) + 1) * abs_importance

# ╔═╡ 5efe21e3-fd04-4d04-9f08-355d8606778d
res = @chain inf9_all begin
	coalesce.(_, 0)
	groupby(:KOOD)
	transform(nrow => :year_count)
	filter(x -> x.year_count > 1, _)
	groupby(:KOOD)
	transform(
			:KINGITUS_TULU .=> [muutus_rel, muutus_abs],
 			:TOETUSE_TULU .=> [muutus_rel, muutus_abs],
 			:LIIKMEMAKSU_TULU .=> [muutus_rel, muutus_abs],
 			:MAJANDUS_TULU .=> [muutus_rel, muutus_abs],
 			:MUU_TULU .=> [muutus_rel, muutus_abs],
 			:KOKKU .=> [muutus_rel, muutus_abs],
			)
	filter(x -> x.AASTA == 2020, _)
end

# ╔═╡ fa0f9a70-5f4c-4e4f-8db0-bc56666431d1
selected_cols = Symbol.([names(res, r"muutus"); :kokku]);

# ╔═╡ 68f726b9-e70a-4e9d-bff6-3a8763d01f5c
all_rel_cols = Symbol.(names(res, r"rel"));

# ╔═╡ 6f3e0514-8d82-46f7-809b-8654eaa2d9e2
sorted_ = @chain res begin
	# filter(x -> x.KOOD ∈ by_kood.KOOD, _)
	filter(x -> x.KOKKU > 100_000 && x.KOKKU_muutus_rel !=  1000 * rel_importance, _)
	filter(x -> all(collect(x[all_rel_cols]) .!= 1000 * rel_importance), _)
	transform(:KOKKU => (x -> log10.(x) .* sum_importance) => :kokku)
	transform(selected_cols => ByRow((x...) -> sum(x)) => :cost)
	sort(:cost, rev=true)
	select([:KOOD, :NIMI, :KOKKU, :cost, selected_cols...])
end

# ╔═╡ 7ac4a2bd-aa01-4272-a041-5d4bd2309828
sorted_2 = @chain res begin
	#filter(x -> x.KOOD == 90005188, _)
	filter(x -> x.KOKKU > 100_000 && x.KOKKU_muutus_rel != 1000 * rel_importance, _)
	transform(rel_cols => ((x...) -> sum(x)) => :cost)
	filter(x -> x.cost > 1_000, _)
	sort(:KOKKU, rev=true)
	select([:KOOD, :NIMI, :KOKKU, :cost, rel_cols...])
end

# ╔═╡ 546d31e6-0520-426a-aa76-ba6ccdbfc0ae
simpl = filter(x -> x.KINGITUS_TULU_muutus_rel > 10 && !isinf(x.KINGITUS_TULU_muutus_rel), res)

# ╔═╡ 955f2697-6f2e-4fc2-89c6-4ced3e3a7138
let plt = data(simpl) * mapping(:KINGITUS_TULU_muutus_rel) * histogram(bins=range(0, 1, length=15))
	draw(plt)
end

# ╔═╡ ab1e8588-6513-4c7f-8212-99318a59cfb9
filter(x -> x.KOOD == 80044767, res)

# ╔═╡ 5a4edd6b-7c4c-4815-9cfc-9cea50ba902f
inf4_sum = @chain inf4 begin
	groupby(:KOOD)
	combine(:SUMMA => sum)
end

# ╔═╡ 7059ebce-d79f-4ebf-aa55-2c938daf69c9
inf4_ja_9_kink = innerjoin(inf9, inf4_sum, on=:KOOD)[:, ["KOOD", "NIMI", "Kingitused ja annetused (19000)", "SUMMA_sum"]]

# ╔═╡ 4f22cd6f-f8a3-4ab9-94a8-74c1277e6e0c
begin
	mask = inf4_ja_9_kink[:, 3] .< inf4_ja_9_kink[:, 4]
	fd_u1 = inf4_ja_9_kink[mask, :]
end

# ╔═╡ e0ef1bfd-aaa3-4b98-8f2a-4c753ebe5e31
XLSX.writetable("inf4_suurem.xlsx", collect(DataFrames.eachcol(fd_u1)), DataFrames.names(fd_u1))

# ╔═╡ d2c5a961-5796-4682-981d-40f8e8e7b364
fd_u2 = res[res.AASTA .== 2020, Not(:year_count)]

# ╔═╡ 407b3c76-e04d-4d5a-8de1-78decc3733d6
XLSX.writetable("tulu_muutus.xlsx", collect(DataFrames.eachcol(fd_u2)), DataFrames.names(fd_u2))

# ╔═╡ 8f93d246-22a5-4dca-b1d3-898530eedca3
begin 
	tegevusala = select(DataFrame(XLSX.readtable("Copy of INF9 2015-19 Parandatud.xlsx", "9_19")...), ([:KOOD, :tegevusala]),)
end

# ╔═╡ 53a0a6ad-f9a4-43db-bdea-3f6e855c785f
md"# plots"

# ╔═╡ ea00b4e8-a7bb-46be-b5de-333f55e3a32a
set_aog_theme!()

# ╔═╡ fb98f4d5-d6c1-4c5f-a0f4-2049ae79ebcd
inf9_all2

# ╔═╡ f5d2ebec-8a52-456e-9bf6-929da5a37f67
people_and_companies = vcat(inf4_f, inf4_j, cols=:union)

# ╔═╡ 4c8dbee2-ebf3-484f-be50-77a74bc3d855
axis = (width = 300, height = 300, ytickformat="{:.0f}",)

# ╔═╡ 71982546-0609-4723-bd38-0833cb865be7
@bind top_n_annetuse_tulemust html"<input type=range min=5 max=30>"

# ╔═╡ c4704605-32a1-4c11-add4-22ce0c2e5baf
top_n_annetuse_tulemust

# ╔═╡ 2c5d6268-b002-4782-88d2-d082454bcde0
top_mtu_from_axis = (
			aspect=3, 
			xticklabelrotation=π/4, 
			ytickformat="{:.2f} mln €"
			)

# ╔═╡ e8b80d37-e12a-48f6-bdb4-d933e6622f66
let plt = data(inf9_all2) * mapping(:AASTA) * visual(BarPlot, width=0.8)
	draw(plt; axis=top_mtu_from_axis) # ????
end

# ╔═╡ 7ed75b62-544e-4e08-bd59-bcb23116c852


# ╔═╡ dfb5a1ba-2ce1-4ed7-b476-4d46a9bd2ae7
@bind top_n_annetust html"<input type=range min=5 max=30 label='hm'>"

# ╔═╡ 5560e0ba-26a3-4dcd-a81e-080e5e3f52a0


# ╔═╡ 9e0a571c-64b9-48f9-a6f3-322e5b362903
top_n_annetust

# ╔═╡ 7d829250-9a4b-4f83-8c1f-d68de7626acd


# ╔═╡ fb84f920-d989-44ba-99ea-6b8d4cc135e4


# ╔═╡ 5e5f58be-ee76-4500-9607-b5517c2a7a14
md"# descriptive stats"

# ╔═╡ d5d82300-f5fd-4d7e-8a19-33c0df0ea8d3
function suurused(x)
	symbols = Symbol.(x)
	(pisile_annetusi = count(==(:small), symbols), keskmisele_annetusi = count(==(:medium), symbols), suurele_annetusi = count(==(:large), symbols))
end

# ╔═╡ 5ee5e49f-12b5-45de-a3f5-1145929d2c82
cut(inf4_f.SUMMA, 4)

# ╔═╡ 9fe8afdf-1861-42b0-aa43-62ac5dc09288
cut(inf9[:,4], 4)

# ╔═╡ c77a5d3b-687f-46d7-9043-be4312485ba3
bins = [0, 19, 31, 61, 120]; labels=["... 18", "19...30", "31...60", "61..."]

# ╔═╡ 5b17085e-a408-4fa3-b917-f1ab97ac7112
people = @chain inf4_f begin 
	innerjoin(_, tegevusala, kood_nimi; on=:KOOD)
	transform(:vanus => (x -> cut(x, bins; labels)) => :bvanus)
end

# ╔═╡ 8f24f101-ba3f-43bf-91f1-22fb1501648e
let plt = data(people) * mapping(:SUMMA => "annetuse suurus", layout=:tegevusala) * visual(alpha=0.5) * histogram(bins=range(0, 200, length=15))
	draw(plt; axis=(ylabel="nr annetusi", title="annetuste arv tegevusala järgi", axis...))
end

# ╔═╡ 25f6f8d6-41a9-4ab6-995d-5a472d80bdfa
let plt = data(people) * mapping(:SUMMA => "annetuse suurus") * visual(alpha=0.5) * histogram(bins=range(0, 200, length=15))
	draw(plt; axis=(ylabel="nr annetusi", title="annetuste arv kokku" , axis...))
end

# ╔═╡ 1e6b67ff-3189-4f17-a436-26ef7c65b3a1
by_kood = @chain people begin
	groupby([:KOOD, :tegevusala, :NIMI])
	combine(:SUMMA => sum => :summa, nrow => :annetuste_arv)
	sort([:summa], rev=true)
	first(top_n_annetuse_tulemust)
end

# ╔═╡ 77a4dc8a-15f8-4a52-8ef4-7b72640e3810
let plt = data(by_kood) * mapping(
		:NIMI => sorter(by_kood.NIMI...), 
		:summa => (s -> s / 1_000_000) => "summa",
		color=:tegevusala
		) * visual(BarPlot, width=0.8)
	
	draw(plt; axis=top_mtu_from_axis, figure=(resolution=(1200, 800), ))
end

# ╔═╡ e0084951-adf2-452d-bda1-2fb6a52cf316
sorted_people = @chain people begin
	# filter(x -> x.KOOD ∈ by_kood.KOOD, _)
	sort(:SUMMA, rev=true)
	first(top_n_annetust)
	@aside _[!, :i] = 1:top_n_annetust
end

# ╔═╡ c796dcac-10be-43a1-8a06-8d054ead4b31
let plt = data(sorted_people) * mapping(:i => "koht nimekirjas", :SUMMA => (s -> s / 1_000_000), color=:tegevusala) * visual(BarPlot, width=0.8)
	draw(plt, axis=top_mtu_from_axis)
end

# ╔═╡ d9833595-8d07-475e-bb4b-d6ab88c41485
let plt = data(people) * expectation() * mapping(:bvanus, :SUMMA => "keskmine annetus", color=:sugu, dodge=:sugu, layout=:tegevusala)
	draw(plt, axis=(xticklabelrotation=π/4,))
end

# ╔═╡ 1c909719-1839-4071-8165-e09e6e5ae9e7
let plt = data(people) * expectation() * mapping(:bvanus => "vanus", :SUMMA => log10 => "keskmine annetus", color=:sugu, dodge=:sugu, layout=:tegevusala)
	draw(plt, 
		axis=(
			xticklabelrotation=π/4,
			yticks=(0:4, string.([0, 10, 100, 1000, 10000]))
			)
		)
end

# ╔═╡ 94ecbff9-885e-4bd3-bbb0-93f17c5b2cdd
descr = @chain inf4_f begin
	innerjoin(_, kood_nimi; on=:KOOD)
	transform(:vanus => (x -> cut(x, bins; labels)) => :bvanus)
	transform(:SUMMA => ByRow(Float64) => :SUMMA)
	groupby([:sugu, :vanus, :bvanus, :JRKNR])
	combine(:SUMMA => sum => :SUMMA, :suurus => suurused => AsTable)
end

# ╔═╡ b9f76683-bab6-4c1c-b7be-6d2cf2f4ec71
writable_descr = transform(descr, :sugu => ByRow(string) => :sugu, :bvanus => ByRow(string) => :bvanus)

# ╔═╡ ec33a82b-1b17-4d1b-b914-96784437064a
XLSX.writetable("inf4_knd_2020_f_per_person.xlsx", collect(DataFrames.eachcol(writable_descr)), DataFrames.names(writable_descr))

# ╔═╡ 67faa5c3-795d-443d-b249-bd8b0f717774
let plt = data(descr) * frequency() * mapping(:vanus, color=:sugu, dodge=:sugu)
	draw(plt, axis=(xticks = LinearTicks(12),))
end

# ╔═╡ 7821dc2c-87d8-4999-9871-7487cead5bad
let plt = data(descr) * expectation() * mapping(:vanus, :SUMMA => "keskmine annetus", color=:sugu, dodge=:sugu)
	draw(plt, axis=(xticks = LinearTicks(12),))
end

# ╔═╡ 2af5937b-b123-422f-b2f9-e4e2e6d9d113
let plt = data(descr) * visual(BoxPlot, show_notch=true, show_outliers=false) * mapping(:bvanus, :SUMMA => "keskmine annetus", dodge=:sugu, color=:sugu)
	draw(plt)
end

# ╔═╡ f7c23ef0-1532-49f3-8298-0a243e402312
let plt = data(descr) * visual(BoxPlot, show_notch=true, show_outliers=false) * mapping(:bvanus, :SUMMA => "keskmine annetus", dodge=:sugu, color=:sugu)
	draw(plt)
end

# ╔═╡ 09c3e9da-22b5-4d1b-8568-bb5de6f4c25c
@chain descr begin
	groupby([:vanus, :sugu])
	combine(:pisile_annetusi => mean => :annetuste_arv)
	data(_) * visual(BarPlot, width=0.8) * mapping(:vanus => "Vanus", :annetuste_arv => "Keskmine annetuste arv", color=:sugu, dodge=:sugu)
	draw(_, axis=(ytickformat="{:.1f}", xticks = LinearTicks(12), title="Pisikestele MTÜdele (kingituste kogusumma < 6000€) tehtud annetuste arv"))
end

# ╔═╡ 916bde7b-d45a-4b18-ae64-cf2dd3f5080b
@chain descr begin
	groupby([:vanus, :sugu])
	combine(:keskmisele_annetusi => mean => :annetuste_arv)
	data(_) * visual(BarPlot, width=0.8) * mapping(:vanus => "Vanus", :annetuste_arv => "Keskmine annetuste arv", color=:sugu, dodge=:sugu)
	draw(_, axis=(ytickformat="{:.1f}", xticks = LinearTicks(12), title="Keskmistele MTÜdele (6000€ <= kingituste kogusumma < 70000€) tehtud annetuste arv"))
end

# ╔═╡ 4c1e4b36-7270-45f0-a272-6c6e2ce88ea9
@chain descr begin
	groupby([:vanus, :sugu])
	combine(:suurele_annetusi => mean => :annetuste_arv)
	data(_) * visual(BarPlot, width=0.8) * mapping(:vanus => "Vanus", :annetuste_arv => "Keskmine annetuste arv", color=:sugu, dodge=:sugu)
	draw(_, axis=(ytickformat="{:.1f}", xticks = LinearTicks(12), title="Suurtele MTÜdele (kingituste kogusumma > 70000€) tehtud annetuste arv"))
end

# ╔═╡ 841acad1-f891-453b-b87b-700fd6fc3023
SUM = combine(groupby(descr, [:vanus, :sugu]), :SUMMA => sum)

# ╔═╡ ba45c719-540e-474d-8ec7-6024826e3c03
let plt = data(SUM) * visual(BarPlot, width=0.8) * mapping(:vanus => "Vanus", :SUMMA_sum => (x -> x / 1000) => "Annetuste summa", color=:sugu, dodge=:sugu)
	draw(plt, axis=(ytickformat="{:.1f}k €", xticks = LinearTicks(12)))
end

# ╔═╡ cb1317a0-5fff-4aa8-ac92-f9d3d1876b43
descr_s = @chain descr begin
	groupby([:bvanus, :sugu])
	combine(:SUMMA .=> [sum, median, length, maximum])
	sort([:bvanus, :sugu])
end

# ╔═╡ 57166a7e-054f-40f2-b29c-3c80864b8e94
stats = ("Annetusi" => length, 
		 "Summa" => sum,
		 "Suurim" => maximum,
		 "Mediaan" => median,
		)

# ╔═╡ 737b592e-5843-4c62-ad59-b58b39d46adb
mehed = summarize_by(filter(x -> x.sugu == :mees, descr), :bvanus, [:SUMMA], stats=stats);

# ╔═╡ 14da725d-82e4-4f6d-9e4f-240001a2c982
naised = summarize_by(filter(x -> x.sugu == :naine, descr), :bvanus, [:SUMMA], stats=stats);

# ╔═╡ ff215580-86d1-4286-b974-f200a8b014a4
@fmt Real = "{:.0f}"

# ╔═╡ 7b084ef8-6a89-4c5a-8de0-7ba9f1a9fcc4
tbl = join_table("Mehed" => mehed, "Naised" => naised)

# ╔═╡ b69bc373-18e0-491e-93bf-045852093378


# ╔═╡ 7884f473-2c30-482f-9a2e-c52617291898
to_tex(tbl) |> Markdown.LaTeX

# ╔═╡ c24330e2-55c6-457b-965d-fd3c0a3089ce
median(descr.SUMMA)

# ╔═╡ c01a06a1-6bba-4da2-8ce8-24e0c77d39c0
median(inf4_f.SUMMA)

# ╔═╡ 81a0f8bd-725b-4cda-91ef-0d713766caa0


# ╔═╡ 0f223764-99ac-465c-8dad-93278a415d4a
mtus = groupby(inf9_all2, :KOOD);

# ╔═╡ 3c0cb4ab-7bd7-4fec-b637-d61c84d1d296
# Threads.@threads for group = mtus
# 	sel = @chain group begin
# 		coalesce.(0)
# 		sort!(:AASTA)
# 		_[!,4:end] ./= 1_000_000
# 	end
# 	filename = "../inf9-graafikud/$(sel.KOOD[1]).png"
# 	title = "$(sel.NIMI[end])"
# 	let plt = data(sel) * tulu_map * visual(BarPlot, width=0.8)
# 		fg = draw(plt; axis=(ytickformat="{:.2f} mln €", title=title,))
# 		save(filename, fg, px_per_unit=3)
# 	end
# end

# ╔═╡ 797bc58f-74e9-4e49-bbf5-7b2395d9ab66


# ╔═╡ 74cb65eb-13fa-4908-939f-0c01b17b0917
@bind protsent PlutoUI.Slider(0.1:0.01:1, default=0.8)

# ╔═╡ 3e8e0e0a-d404-4a0b-89f4-e55e90c7de30
kumuleeriv_kink = @chain inf9 begin
	select(4 => :kink)
	@aside SUM = sum(_.kink)
	transform(:kink => (x -> x / SUM) => :osa)
	transform(:osa => cumsum => :cumosa)
	transform(_, :kink => (x -> 1:size(_, 1)) => :i)
	
	#data(_) * visual(Lines) * mapping(:i, :cumosa)
	#draw(axis=(limits=(0, 1000, 0, 1),))
end;

# ╔═╡ 51c9ce07-3876-4680-8078-8de41bcbb9bf
n = findfirst(>(protsent), kumuleeriv_kink.cumosa) |> x -> something(x, size(inf9, 1));

# ╔═╡ 03760fc5-8fdf-4bc5-9ada-43d727693aba
n_percent = round(n/size(inf9, 1) * 100, digits=1)

# ╔═╡ 7bd238d8-797d-48d9-b65e-42d271b727fe
actual_percentage = round(kumuleeriv_kink[n, :cumosa] * 100, digits=1)

# ╔═╡ cd797616-f87f-40fd-ad4a-ecd7c05672ea
md"""
## Pareto põhimõte: 80/20

Esimese $n ( $n_percent %) MTÜ kingitused on $(actual_percentage)% kõikidest kingitustest
"""

# ╔═╡ 0eb1f986-a29a-4a40-9b53-852b49e09e6c
total_annetus = sum(inf9[!, 4])

# ╔═╡ f0ef5755-005a-4bbe-a30f-789ee1ba8c0e
md"# inimeste annetamise graaf"

# ╔═╡ b2a69e19-be4b-4177-b9c5-a513d7dd4cf5
gkood = @chain inf4_f begin
	groupby(:JRKNR)
	transform(nrow => :n)
	subset(:n => ByRow(>(1)))
	groupby(:KOOD)
end

# ╔═╡ 81d7e76c-cf26-4340-801e-7e26ae07527e
ginim = @chain inf4_f begin
	groupby(:JRKNR)
	transform(nrow => :n)
	subset(:n => ByRow(>(1)))
	groupby(:JRKNR)
end

# ╔═╡ abbe65b4-a62b-4e2d-9f55-a7937c3b8935
size(gkood, 1)

# ╔═╡ 31e9c9c4-627d-402b-911d-617b08fb6830
gkood[1]

# ╔═╡ 977738ca-21d3-42e6-9aac-85cd64bb2f65
begin 
	G_kood = MetaGraph(size(gkood, 1), 0.0)
	for (i, (key, group)) = enumerate(pairs(gkood))
		set_prop!(G_kood, i, :KOOD, string(key.KOOD))
		set_prop!(G_kood, i, :jrknrs, string.(group.JRKNR))
	end
	set_indexing_prop!(G_kood, :KOOD)
end

# ╔═╡ dd3c357b-a489-460a-bbb6-cf162d0351cf
begin 
	G_inim = MetaGraph(size(ginim, 1))
	for (i, (key, group)) = enumerate(pairs(ginim))
		set_prop!(G_inim, i, :JRKNR, string(key.JRKNR))
		set_prop!(G_inim, i, :kood_sum, zip(string.(group.KOOD), group.SUMMA))
	end
	set_indexing_prop!(G_inim, :JRKNR)
end

# ╔═╡ c6a480a9-cf6a-4e02-b2bb-49b9d7b16ff6
jrknr = get_prop(G_kood, 1, :jrknrs)[1]

# ╔═╡ 50e2acb9-adfd-4e6d-8e0c-59bc87917488
edge_to = first(get_prop(G_inim, G_inim[jrknr, :JRKNR], :kood_sum))

# ╔═╡ dbe49d71-4821-4883-ae7d-cdcc7f829e03
for (i, (key, group)) = enumerate(pairs(gkood))
	for person_jrk = get_prop(G_kood, i, :jrknrs)
		for (kood_s, summ) = get_prop(G_inim, G_inim[person_jrk, :JRKNR], :kood_sum)
			edge_to = G_kood[kood_s, :KOOD]
			if !has_edge(G_kood, i, edge_to)
				add_edge!(G_kood, i, edge_to, :weight, summ)
			else
				prev_sum = get_prop(G_kood, i, edge_to, :weight)
				set_prop!(G_kood, i, edge_to, :weight, prev_sum + summ)
			end
		end
	end
 end

# ╔═╡ 29d1129f-2b62-4831-8efc-76c7f5869302
adjacency_matrix(G_kood)

# ╔═╡ 845ef5bc-70d6-4ebd-8756-0868e4d66059
weight_A = [MetaGraphs.weights(G_kood)[x, y] for x=1:991, y=1:991]

# ╔═╡ 16cea35a-d84b-428a-8be1-142db030f1cc
A = adjacency_matrix(G_kood) .* weight_A

# ╔═╡ 06514b52-b647-4791-b816-137a0f7feca9
begin
	Y = sgtsnepi(A, d=2)
end

# ╔═╡ 4609a7f0-d2ba-402e-a22e-c69437e2a57f
show_embedding(Y; A=A, lwd_in = 0.1, lwd_out = 0.01)

# ╔═╡ 07df7026-541b-40d7-a0f5-5efa74132671
g = SimpleGraph(G_kood)

# ╔═╡ e06571d6-a7f5-4d18-8e83-6f1fd836b05c
g[1]

# ╔═╡ 3cfc20e5-89da-41b3-a17e-906b14288d79
gt = complete_graph(10)

# ╔═╡ cf5941da-7ee0-4791-a50d-339e849b4907
betweenness_centrality(g)

# ╔═╡ 62292693-709d-44b3-88d8-c3b186584d3f
@bind topN PlutoUI.Slider(1:100, show_value=true)

# ╔═╡ 49a8e0e5-341e-4d7d-b2f6-f3639c743ce0
sg, vmap = induced_subgraph(G_kood, 1:topN)

# ╔═╡ 8353e29f-8eb1-4997-b3f3-3fbf7bffc771
MetaGraphs.weights(G_kood)[x, y]

# ╔═╡ 2266b23c-0603-4906-bfdc-8164e289d186
label_dict = Dict(zip(string.(kood_nimi.KOOD), string.(kood_nimi.NIMI)))

# ╔═╡ d864dcd3-5faf-4467-8b44-f7c60a908ef0
ne(sg)

# ╔═╡ 7d9a56ca-e6a4-4465-b01c-4b53138d87bd


# ╔═╡ 330fb435-d236-4fd9-a94b-a5f8297353a2
glabel = [label_dict[get_prop(G_kood, i, :KOOD)] for i = 1:nv(G_kood)]

# ╔═╡ 8bdfef1a-a3af-4aa6-b894-84503ddb2cea
gplot(sg, nodelabel=glabel[1:topN], edgelinewidth=0:0.1:10)

# ╔═╡ 9e05b350-4539-48ae-84fa-68df38104906
G_kood["80088606", :KOOD]

# ╔═╡ 42e7e7d9-2bf5-4440-a59c-5eb34562fd46
gk = get_prop(G, 3, :KOOD)

# ╔═╡ 32d4bbc3-e144-40be-9fc6-4a39196f7c76
gk.KOOD

# ╔═╡ 1155e90c-65b2-4c55-9c4f-18ac49195691
ClickedRow() = @htl("""
<div>
	<output>1</output>
<script>

	// Select elements relative to `currentScript`
	var div = currentScript.parentElement
	var aboveCell = currentScript.closest("pluto-cell").previousElementSibling
	var rows = [...aboveCell.querySelectorAll("pluto-output table tbody tr")]
	
	
	var rowIx = 1;
	function handleRowClick(event) {
		var newRowIx = +event.target.closest("tr").children[0].textContent
		if (newRowIx !== rowIx) {
			rowIx = newRowIx
			div.value = newRowIx
			div.firstElementChild.textContent = newRowIx
			div.dispatchEvent(new CustomEvent("input"))
		}
		event.preventDefault()
	}
	
	rows.forEach(r => r.onclick = handleRowClick)
	

	// Set the initial value
	div.value = rowIx

</script>
</div>
""")

# ╔═╡ e58c61ae-f464-4df2-9c17-f787e2add8c3
@bind clicked_sorted_i ClickedRow()

# ╔═╡ de0e3e9b-8e0f-48f3-8a63-7d57f6b4c4b1
clicked_sorted_kood = sorted_[clicked_sorted_i,:KOOD]

# ╔═╡ ae8bbe30-7848-46b4-b463-c084d5f92627
selected_1 = @chain inf9_all2 begin
	subset(:KOOD => ByRow(==(clicked_sorted_kood)))
	coalesce.(0)
	sort(:AASTA)
	_[!,4:9] ./= 1_000_000
end

# ╔═╡ 227b3145-a7c4-4db2-9a03-2fe267bfc722
let plt = data(selected_1) * tulu_map * visual(BarPlot, width=0.8)
	draw(plt; axis=top_mtu_from_axis)
end

# ╔═╡ b36d74e7-db05-4efc-ba5e-428003ea8ea4
@bind clicked_sorted_i_2 ClickedRow()

# ╔═╡ afba4d8c-5d87-49a3-a00c-498d442cbb90
clicked_sorted_kood_2 = sorted_2[clicked_sorted_i_2,:KOOD];

# ╔═╡ a6a20163-6ed6-463c-9054-ba63890a7691
selected_2 = @chain inf9_all2 begin
	filter(x -> x.KOOD == clicked_sorted_kood_2, _)
	coalesce.(0)
	sort(:AASTA)
	_[!,4:9] ./= 1_000_000
end

# ╔═╡ d4dd90ab-fed3-4925-bf19-36d169483d5f
let plt = data(selected_2) * tulu_map * visual(BarPlot, width=0.8)
	draw(plt; axis=top_mtu_from_axis)
end

# ╔═╡ 485188ca-2759-49c2-93c6-3da34dd0e686
Base.show(io::IO, ::MIME"text/html", x::CategoricalArrays.CategoricalValue) = print(io, get(x))

# ╔═╡ cf78994f-5df9-4c3e-bfb5-405fe9c382a8
value_counts(x) = sort(collect(countmap(x)), by=x -> x[2], rev=true)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
AlgebraOfGraphics = "cbdf2221-f076-402e-a563-3d30da359d67"
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
CairoMakie = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
CategoricalArrays = "324d7699-5711-5eae-9e2f-1d82baa6b597"
Chain = "8be319e6-bccf-4806-a6f7-6fae938471bc"
Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
DataStructures = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
GraphPlot = "a2cc645c-3eea-5389-862e-a155d0052231"
Graphs = "86223c79-3864-5bf0-83f7-82e725a168b6"
HypertextLiteral = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
MetaGraphs = "626554b9-1ddb-594c-aa3c-2596fe9399a5"
OffsetArrays = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
Pkg = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
SGtSNEpi = "e6c19c8d-e382-4a50-b2c6-174ddd647730"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
TexTables = "ebf5ac4f-3ec1-555f-9ac9-3d72ed88c471"
TimeZones = "f269a46b-ccf7-5d73-abea-4c690281aa53"
XLSX = "fdbf4ff8-1666-58a4-91e7-1b58723a45e0"

[compat]
AlgebraOfGraphics = "~0.6.0"
CSV = "~0.9.9"
CairoMakie = "~0.6.6"
CategoricalArrays = "~0.10.1"
Chain = "~0.4.8"
Colors = "~0.12.8"
DataFrames = "~1.2.2"
DataStructures = "~0.18.10"
GraphPlot = "~0.5.0"
Graphs = "~1.4.1"
HypertextLiteral = "~0.9.2"
MetaGraphs = "~0.7.0"
OffsetArrays = "~1.10.7"
PlutoUI = "~0.7.16"
SGtSNEpi = "~0.2.1"
StatsBase = "~0.33.12"
TexTables = "~0.2.4"
TimeZones = "~1.6.1"
XLSX = "~0.7.8"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "485ee0867925449198280d4af84bdb46a2a404d0"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.0.1"

[[AbstractTrees]]
git-tree-sha1 = "03e0550477d86222521d254b741d470ba17ea0b5"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.3.4"

[[Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "84918055d15b3114ede17ac6a7182f68870c16f7"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.1"

[[AlgebraOfGraphics]]
deps = ["Colors", "Dates", "FileIO", "GLM", "GeoInterface", "GeometryBasics", "GridLayoutBase", "KernelDensity", "Loess", "Makie", "PlotUtils", "PooledArrays", "RelocatableFolders", "StatsBase", "StructArrays", "Tables"]
git-tree-sha1 = "a79d1facb9fb0cd858e693088aa366e328109901"
uuid = "cbdf2221-f076-402e-a563-3d30da359d67"
version = "0.6.0"

[[Animations]]
deps = ["Colors"]
git-tree-sha1 = "e81c509d2c8e49592413bfb0bb3b08150056c79d"
uuid = "27a7e980-b3e6-11e9-2bcd-0b925532e340"
version = "0.4.1"

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "f87e559f87a45bece9c9ed97458d3afe98b1ebb9"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.1.0"

[[ArrayInterface]]
deps = ["Compat", "IfElse", "LinearAlgebra", "Requires", "SparseArrays", "Static"]
git-tree-sha1 = "49fe2b94edd1a54ac4919b33432daefd8e6c0f28"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "3.1.35"

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[Automa]]
deps = ["Printf", "ScanByte", "TranscodingStreams"]
git-tree-sha1 = "d50976f217489ce799e366d9561d56a98a30d7fe"
uuid = "67c07d97-cdcb-5c2c-af73-a7f9c32a568b"
version = "0.8.2"

[[AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[BinDeps]]
deps = ["Libdl", "Pkg", "SHA", "URIParser", "Unicode"]
git-tree-sha1 = "1289b57e8cf019aede076edab0587eb9644175bd"
uuid = "9e28174c-4ba2-5203-b857-d8d62c4213ee"
version = "1.0.2"

[[Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[CEnum]]
git-tree-sha1 = "215a9aa4a1f23fbd05b92769fdd62559488d70e9"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.1"

[[CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings"]
git-tree-sha1 = "c0a735698d1a0a388c5c7ae9c7fb3da72fd5424e"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.9.9"

[[Cairo]]
deps = ["Cairo_jll", "Colors", "Glib_jll", "Graphics", "Libdl", "Pango_jll"]
git-tree-sha1 = "d0b3f8b4ad16cb0a2988c6788646a5e6a17b6b1b"
uuid = "159f3aea-2a34-519c-b102-8c37f9878175"
version = "1.0.5"

[[CairoMakie]]
deps = ["Base64", "Cairo", "Colors", "FFTW", "FileIO", "FreeType", "GeometryBasics", "LinearAlgebra", "Makie", "SHA", "StaticArrays"]
git-tree-sha1 = "774ff1cce3ae930af3948c120c15eeb96c886c33"
uuid = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
version = "0.6.6"

[[Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "f2202b55d816427cd385a9a4f3ffb226bee80f99"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+0"

[[CategoricalArrays]]
deps = ["DataAPI", "Future", "Missings", "Printf", "Requires", "Statistics", "Unicode"]
git-tree-sha1 = "fbc5c413a005abdeeb50ad0e54d85d000a1ca667"
uuid = "324d7699-5711-5eae-9e2f-1d82baa6b597"
version = "0.10.1"

[[Chain]]
git-tree-sha1 = "cac464e71767e8a04ceee82a889ca56502795705"
uuid = "8be319e6-bccf-4806-a6f7-6fae938471bc"
version = "0.4.8"

[[ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "0541d306de71e267c1a724f84d44bbc981f287b4"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.10.2"

[[CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[ColorBrewer]]
deps = ["Colors", "JSON", "Test"]
git-tree-sha1 = "61c5334f33d91e570e1d0c3eb5465835242582c4"
uuid = "a2cac450-b92f-5266-8821-25eda20663c8"
version = "0.4.0"

[[ColorSchemes]]
deps = ["ColorTypes", "Colors", "FixedPointNumbers", "Random"]
git-tree-sha1 = "a851fec56cb73cfdf43762999ec72eff5b86882a"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.15.0"

[[ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "32a2b8af383f11cbb65803883837a149d10dfe8a"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.10.12"

[[ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "45efb332df2e86f2cb2e992239b6267d97c9e0b6"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.7"

[[Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "31d0151f5716b655421d9d75b7fa74cc4e744df2"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.39.0"

[[CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[Compose]]
deps = ["Base64", "Colors", "DataStructures", "Dates", "IterTools", "JSON", "LinearAlgebra", "Measures", "Printf", "Random", "Requires", "Statistics", "UUIDs"]
git-tree-sha1 = "c6461fc7c35a4bb8d00905df7adafcff1fe3a6bc"
uuid = "a81c6b42-2e10-5240-aca2-a61377ecd94b"
version = "0.9.2"

[[Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[Crayons]]
git-tree-sha1 = "3f71217b538d7aaee0b69ab47d9b7724ca8afa0d"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.0.4"

[[DataAPI]]
git-tree-sha1 = "cc70b17275652eb47bc9e5f81635981f13cea5c8"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.9.0"

[[DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "d785f42445b63fc86caa08bb9a9351008be9b765"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.2.2"

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "7d9d316f04214f7efdbb6398d545446e246eff02"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.10"

[[DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[Distances]]
deps = ["LinearAlgebra", "Statistics", "StatsAPI"]
git-tree-sha1 = "09d9eaef9ef719d2cd5d928a191dc95be2ec8059"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.5"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[Distributions]]
deps = ["ChainRulesCore", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns"]
git-tree-sha1 = "15dad92b6a36400c988de3fc9490a372599f5b4c"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.21"

[[DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "a32185f5428d3986f47c2ab78b1f216d5e6cc96f"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.5"

[[Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3f3a2501fa7236e9b911e0f7a588c657e822bb6d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.3+0"

[[EllipsisNotation]]
deps = ["ArrayInterface"]
git-tree-sha1 = "8041575f021cba5a099a456b4163c9a08b566a02"
uuid = "da5c29d0-fa7d-589e-88eb-ea29b0a81949"
version = "1.1.0"

[[Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b3bfd02e98aedfa5cf885665493c5598c350cd2f"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.2.10+0"

[[ExprTools]]
git-tree-sha1 = "b7e3d17636b348f005f11040025ae8c6f645fe92"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.6"

[[EzXML]]
deps = ["Printf", "XML2_jll"]
git-tree-sha1 = "0fa3b52a04a4e210aeb1626def9c90df3ae65268"
uuid = "8f5d6c58-4d21-5cfd-889c-e3ad7ee6a615"
version = "1.1.0"

[[FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "Pkg", "Zlib_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "d8a578692e3077ac998b50c0217dfd67f21d1e5f"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.0+0"

[[FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "463cb335fa22c4ebacfd1faba5fde14edb80d96c"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.4.5"

[[FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[FLANN]]
deps = ["BinDeps", "Distances", "Libdl"]
git-tree-sha1 = "5e69a6f74abee6660ad11458f7eea5817604ef44"
uuid = "4ef67f76-e0de-5105-ac01-03b6482fb4f8"
version = "1.1.0"

[[FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "3c041d2ac0a52a12a27af2782b34900d9c3ee68c"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.11.1"

[[FilePathsBase]]
deps = ["Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "7fb0eaac190a7a68a56d2407a6beff1142daf844"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.12"

[[FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "8756f9935b7ccc9064c6eef0bff0ad643df733a3"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.12.7"

[[FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[FreeType]]
deps = ["CEnum", "FreeType2_jll"]
git-tree-sha1 = "cabd77ab6a6fdff49bfd24af2ebe76e6e018a2b4"
uuid = "b38be410-82b0-50bf-ab77-7b57e271db43"
version = "4.0.0"

[[FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[FreeTypeAbstraction]]
deps = ["ColorVectorSpace", "Colors", "FreeType", "GeometryBasics", "StaticArrays"]
git-tree-sha1 = "19d0f1e234c13bbfd75258e55c52aa1d876115f5"
uuid = "663a7486-cb36-511b-a19d-713bb74d65c9"
version = "0.9.2"

[[FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[GLM]]
deps = ["Distributions", "LinearAlgebra", "Printf", "Reexport", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "StatsModels"]
git-tree-sha1 = "f564ce4af5e79bb88ff1f4488e64363487674278"
uuid = "38e38edf-8417-5370-95a0-9cbb8c7f171a"
version = "1.5.1"

[[GeoInterface]]
deps = ["RecipesBase"]
git-tree-sha1 = "f63297cb6a2d2c403d18b3a3e0b7fcb01c0a3f40"
uuid = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"
version = "0.5.6"

[[GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "58bcdf5ebc057b085e58d95c138725628dd7453c"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.1"

[[Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "7bf67e9a481712b3dbe9cb3dac852dc4b1162e02"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.68.3+0"

[[GraphPlot]]
deps = ["ArnoldiMethod", "ColorTypes", "Colors", "Compose", "DelimitedFiles", "Graphs", "LinearAlgebra", "Random", "SparseArrays"]
git-tree-sha1 = "5e51d9d9134ebcfc556b82428521fe92f709e512"
uuid = "a2cc645c-3eea-5389-862e-a155d0052231"
version = "0.5.0"

[[Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "1c5a84319923bea76fa145d49e93aa4394c73fc2"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.1"

[[Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[Graphs]]
deps = ["ArnoldiMethod", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "92243c07e786ea3458532e199eb3feee0e7e08eb"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.4.1"

[[GridLayoutBase]]
deps = ["GeometryBasics", "InteractiveUtils", "Match", "Observables"]
git-tree-sha1 = "e2f606c87d09d5187bb6069dab8cee0af7c77bdb"
uuid = "3955a311-db13-416c-9275-1d80ed98e5e9"
version = "0.6.1"

[[Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "8a954fed8ac097d5be04921d595f741115c1b2ad"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+0"

[[Hwloc]]
deps = ["Hwloc_jll"]
git-tree-sha1 = "92d99146066c5c6888d5a3abc871e6a214388b91"
uuid = "0e44f5e4-bd66-52a0-8798-143a42290a1d"
version = "2.0.0"

[[Hwloc_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3395d4d4aeb3c9d31f5929d32760d8baeee88aaf"
uuid = "e33a78d0-f292-5ffc-b300-72abe9b543c8"
version = "2.5.0+0"

[[Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[HypertextLiteral]]
git-tree-sha1 = "5efcf53d798efede8fee5b2c8b09284be359bf24"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.2"

[[IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[IfElse]]
git-tree-sha1 = "28e837ff3e7a6c3cdb252ce49fb412c8eb3caeef"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.0"

[[ImageCore]]
deps = ["AbstractFFTs", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Graphics", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "Reexport"]
git-tree-sha1 = "9a5c62f231e5bba35695a20988fc7cd6de7eeb5a"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.9.3"

[[ImageIO]]
deps = ["FileIO", "Netpbm", "OpenEXR", "PNGFiles", "TiffImages", "UUIDs"]
git-tree-sha1 = "a2951c93684551467265e0e32b577914f69532be"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.5.9"

[[Imath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "87f7662e03a649cffa2e05bf19c303e168732d3e"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.1.2+0"

[[IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[Inflate]]
git-tree-sha1 = "f5fc07d4e706b84f72d54eedcc1c13d92fb0871c"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.2"

[[InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "19cb49649f8c41de7fea32d089d37de917b553da"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.0.1"

[[IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d979e54b71da82f3a65b62553da4fc3d18c9004c"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2018.0.3+2"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[Interpolations]]
deps = ["AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "61aa005707ea2cebf47c8d780da8dc9bc4e0c512"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.13.4"

[[IntervalSets]]
deps = ["Dates", "EllipsisNotation", "Statistics"]
git-tree-sha1 = "3cc368af3f110a767ac786560045dceddfc16758"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.5.3"

[[InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "f0c6489b12d28fb4c2103073ec7452f3423bd308"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.1"

[[InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[Isoband]]
deps = ["isoband_jll"]
git-tree-sha1 = "f9b6d97355599074dc867318950adaa6f9946137"
uuid = "f1662d9f-8043-43de-a69a-05efc1cc6ff4"
version = "0.1.1"

[[IterTools]]
git-tree-sha1 = "05110a2ab1fc5f932622ffea2a003221f4782c18"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.3.0"

[[IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[JLD2]]
deps = ["DataStructures", "FileIO", "MacroTools", "Mmap", "Pkg", "Printf", "Reexport", "TranscodingStreams", "UUIDs"]
git-tree-sha1 = "46b7834ec8165c541b0b5d1c8ba63ec940723ffb"
uuid = "033835bb-8acc-5ee8-8aae-3f567f8a3819"
version = "0.4.15"

[[JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "642a199af8b68253517b80bd3bfd17eb4e84df6e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.3.0"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "591e8dc09ad18386189610acafb970032c519707"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.3"

[[LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[LaTeXStrings]]
git-tree-sha1 = "c7f1c695e06c01b95a67f0cd1d34994f3e7db104"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.2.1"

[[LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "761a393aeccd6aa92ec3515e428c26bf99575b3b"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+0"

[[Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[LightGraphs]]
deps = ["ArnoldiMethod", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "432428df5f360964040ed60418dd5601ecd240b6"
uuid = "093fc24a-ae57-5d10-9952-331d41423f4d"
version = "1.3.5"

[[LinearAlgebra]]
deps = ["Libdl"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[Loess]]
deps = ["Distances", "LinearAlgebra", "Statistics"]
git-tree-sha1 = "b5254a86cf65944c68ed938e575f5c81d5dfe4cb"
uuid = "4345ca2d-374a-55d4-8d30-97f9976e7612"
version = "0.5.3"

[[LogExpFunctions]]
deps = ["ChainRulesCore", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "6193c3815f13ba1b78a51ce391db8be016ae9214"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.4"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "5455aef09b40e5020e1520f551fa3135040d4ed0"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2021.1.1+2"

[[MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "5a5bc6bf062f0f95e62d0fe0a2d99699fed82dd9"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.8"

[[Makie]]
deps = ["Animations", "Base64", "ColorBrewer", "ColorSchemes", "ColorTypes", "Colors", "Contour", "Distributions", "DocStringExtensions", "FFMPEG", "FileIO", "FixedPointNumbers", "Formatting", "FreeType", "FreeTypeAbstraction", "GeometryBasics", "GridLayoutBase", "ImageIO", "IntervalSets", "Isoband", "KernelDensity", "LaTeXStrings", "LinearAlgebra", "MakieCore", "Markdown", "Match", "MathTeXEngine", "Observables", "Packing", "PlotUtils", "PolygonOps", "Printf", "Random", "RelocatableFolders", "Serialization", "Showoff", "SignedDistanceFields", "SparseArrays", "StaticArrays", "Statistics", "StatsBase", "StatsFuns", "StructArrays", "UnicodeFun"]
git-tree-sha1 = "56b0b7772676c499430dc8eb15cfab120c05a150"
uuid = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
version = "0.15.3"

[[MakieCore]]
deps = ["Observables"]
git-tree-sha1 = "7bcc8323fb37523a6a51ade2234eee27a11114c8"
uuid = "20f20a25-4f0e-4fdf-b5d1-57303727442b"
version = "0.1.3"

[[MappedArrays]]
git-tree-sha1 = "e8b359ef06ec72e8c030463fe02efe5527ee5142"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.1"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[Match]]
git-tree-sha1 = "5cf525d97caf86d29307150fcba763a64eaa9cbe"
uuid = "7eb4fadd-790c-5f42-8a69-bfa0b872bfbf"
version = "1.1.0"

[[MathTeXEngine]]
deps = ["AbstractTrees", "Automa", "DataStructures", "FreeTypeAbstraction", "GeometryBasics", "LaTeXStrings", "REPL", "RelocatableFolders", "Test"]
git-tree-sha1 = "70e733037bbf02d691e78f95171a1fa08cdc6332"
uuid = "0a4f8689-d25c-4efe-a92b-7142dfc1aa53"
version = "0.2.1"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[Measures]]
git-tree-sha1 = "e498ddeee6f9fdb4551ce855a46f54dbd900245f"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.1"

[[MetaGraphs]]
deps = ["Graphs", "JLD2", "Random"]
git-tree-sha1 = "5658bebcf7e58e7ff09aa004ff6e806478c5e93a"
uuid = "626554b9-1ddb-594c-aa3c-2596fe9399a5"
version = "0.7.0"

[[Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[Mocking]]
deps = ["Compat", "ExprTools"]
git-tree-sha1 = "29714d0a7a8083bba8427a4fbfb00a540c681ce7"
uuid = "78c3b35d-d492-501b-9361-3d52fe80e533"
version = "0.7.3"

[[MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "b34e3bc3ca7c94914418637cb10cc4d1d80d877d"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.3"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[NaNMath]]
git-tree-sha1 = "bfe47e760d60b82b66b61d2d44128b62e3a369fb"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.5"

[[NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "16baacfdc8758bc374882566c9187e785e85c2f0"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.9"

[[Netpbm]]
deps = ["FileIO", "ImageCore"]
git-tree-sha1 = "18efc06f6ec36a8b801b23f076e3c6ac7c3bf153"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.0.2"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[Observables]]
git-tree-sha1 = "fe29afdef3d0c4a8286128d4e45cc50621b1e43d"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.4.0"

[[OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "c0e9e582987d36d5a61e650e6e543b9e44d9914b"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.10.7"

[[Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7937eda4681660b4d6aeeecc2f7e1c81c8ee4e2f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+0"

[[OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "327f53360fdb54df7ecd01e96ef1983536d1e633"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.2"

[[OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "923319661e9a22712f24596ce81c54fc0366f304"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.1.1+0"

[[OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"

[[OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "15003dcb7d8db3c6c857fda14891a539a8f2705a"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.10+0"

[[OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[PCRE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b2a7af664e098055a7529ad1a900ded962bca488"
uuid = "2f80f16e-611a-54ab-bc61-aa92de5b98fc"
version = "8.44.0+0"

[[PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "4dd403333bcf0909341cfe57ec115152f937d7d8"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.1"

[[PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "33ae7d19c6ba748d30c0c08a82378aae7b64b5e9"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.3.11"

[[Packing]]
deps = ["GeometryBasics"]
git-tree-sha1 = "1155f6f937fa2b94104162f01fa400e192e4272f"
uuid = "19eb6ba3-879d-56ad-ad62-d5c202156566"
version = "0.4.2"

[[PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "646eed6f6a5d8df6708f15ea7e02a7a2c4fe4800"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.10"

[[Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9bc1871464b12ed19297fbc56c4fb4ba84988b0d"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.47.0+0"

[[Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "f19e978f81eca5fd7620650d7dbea58f825802ee"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.1.0"

[[Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "a7a7e1a88853564e551e4eba8650f8c38df79b37"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.1.1"

[[PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "b084324b4af5a438cd63619fd006614b3b20b87b"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.0.15"

[[PlutoUI]]
deps = ["Base64", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "4c8a7d080daca18545c56f1cac28710c362478f3"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.16"

[[PolygonOps]]
git-tree-sha1 = "77b3d3605fc1cd0b42d95eba87dfcd2bf67d5ff6"
uuid = "647866c9-e3ac-4575-94e7-e3d426903924"
version = "0.1.2"

[[PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a193d6ad9c45ada72c14b731a318bedd3c2f00cf"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.3.0"

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00cfd92944ca9c760982747e9a1d0d5d86ab1e5a"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.2"

[[PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "d940010be611ee9d67064fe559edbb305f8cc0eb"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.2.3"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "afadeba63d90ff223a6a48d2009434ecee2ec9e8"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.7.1"

[[QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "78aadffb3efd2155af139781b8a8df1ef279ea39"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.4.2"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[Ratios]]
deps = ["Requires"]
git-tree-sha1 = "01d341f502250e81f6fec0afe662aa861392a3aa"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.2"

[[RecipesBase]]
git-tree-sha1 = "44a75aa7a527910ee3d1751d1f0e4148698add9e"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.1.2"

[[Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "df2be5142a2a3db2da37b21d87c9fa7973486bfd"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "0.1.2"

[[Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "4036a3bd08ac7e968e27c203d45f5fff15020621"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.1.3"

[[Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[SGtSNEpi]]
deps = ["Colors", "Distances", "FLANN", "Hwloc", "Libdl", "LightGraphs", "LinearAlgebra", "NearestNeighbors", "Requires", "SparseArrays", "sgtsnepi_jll"]
git-tree-sha1 = "a96bf5e944b12a1afc9343782c1af49d0330ef4d"
uuid = "e6c19c8d-e382-4a50-b2c6-174ddd647730"
version = "0.2.1"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[SIMD]]
git-tree-sha1 = "9ba33637b24341aba594a2783a502760aa0bff04"
uuid = "fdea26ae-647d-5447-a871-4b548cad5224"
version = "3.3.1"

[[ScanByte]]
deps = ["Libdl", "SIMD"]
git-tree-sha1 = "9cc2955f2a254b18be655a4ee70bc4031b2b189e"
uuid = "7b38b023-a4d7-4c5e-8d43-3f3097f304eb"
version = "0.3.0"

[[Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

[[SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "f45b34656397a1f6e729901dc9ef679610bd12b5"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.8"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[ShiftedArrays]]
git-tree-sha1 = "22395afdcf37d6709a5a0766cc4a5ca52cb85ea0"
uuid = "1277b4bf-5013-50f5-be3d-901d8477a67a"
version = "1.0.0"

[[Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[SignedDistanceFields]]
deps = ["Random", "Statistics", "Test"]
git-tree-sha1 = "d263a08ec505853a5ff1c1ebde2070419e3f28e9"
uuid = "73760f76-fbc4-59ce-8f25-708e95d2df96"
version = "0.4.0"

[[SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "2d57e14cd614083f132b6224874296287bfa3979"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "1.8.0"

[[StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

[[Static]]
deps = ["IfElse"]
git-tree-sha1 = "e7bc80dc93f50857a5d1e3c8121495852f407e6a"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "0.4.0"

[[StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "3c76dde64d03699e074ac02eb2e8ba8254d428da"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.2.13"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[StatsAPI]]
git-tree-sha1 = "1958272568dc176a1d881acb797beb909c785510"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.0.0"

[[StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "eb35dcc66558b2dda84079b9a1be17557d32091a"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.12"

[[StatsFuns]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "95072ef1a22b057b1e80f73c2a89ad238ae4cfff"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "0.9.12"

[[StatsModels]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "Printf", "REPL", "ShiftedArrays", "SparseArrays", "StatsBase", "StatsFuns", "Tables"]
git-tree-sha1 = "5cfe2d754634d9f11ae19e7b45dad3f8e4883f54"
uuid = "3eaba693-59b7-5ba5-a881-562e759f1c8d"
version = "0.6.27"

[[StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArrays", "Tables"]
git-tree-sha1 = "2ce41e0d042c60ecd131e9fb7154a3bfadbf50d3"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.3"

[[SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "TableTraits", "Test"]
git-tree-sha1 = "fed34d0e71b91734bf0a7e10eb1bb05296ddbcd0"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.6.0"

[[Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[TexTables]]
deps = ["Compat", "DataFrames", "DataStructures", "Distributions", "Formatting", "GLM", "Parameters", "StatsBase", "StatsModels"]
git-tree-sha1 = "f15f302b6345690f14fe2f6f986c9d4d721fe925"
uuid = "ebf5ac4f-3ec1-555f-9ac9-3d72ed88c471"
version = "0.2.4"

[[TiffImages]]
deps = ["ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "OffsetArrays", "PkgVersion", "ProgressMeter", "UUIDs"]
git-tree-sha1 = "016185e1a16c1bd83a4352b19a3b136224f22e38"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.5.1"

[[TimeZones]]
deps = ["Dates", "Downloads", "InlineStrings", "LazyArtifacts", "Mocking", "Pkg", "Printf", "RecipesBase", "Serialization", "Unicode"]
git-tree-sha1 = "b4c6460412b1db0b4f1679ab2d5ef72568a14a57"
uuid = "f269a46b-ccf7-5d73-abea-4c690281aa53"
version = "1.6.1"

[[TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[URIParser]]
deps = ["Unicode"]
git-tree-sha1 = "53a9f49546b8d2dd2e688d216421d050c9a31d0d"
uuid = "30578b45-9adc-5946-b283-645ec420af67"
version = "0.4.1"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "c69f9da3ff2f4f02e811c3323c22e5dfcb584cfa"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.1"

[[WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

[[XLSX]]
deps = ["Dates", "EzXML", "Printf", "Tables", "ZipFile"]
git-tree-sha1 = "96d05d01d6657583a22410e3ba416c75c72d6e1d"
uuid = "fdbf4ff8-1666-58a4-91e7-1b58723a45e0"
version = "0.7.8"

[[XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "1acf5bdf07aa0907e0a37d3718bb88d4b687b74a"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.12+0"

[[XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[ZipFile]]
deps = ["Libdl", "Printf", "Zlib_jll"]
git-tree-sha1 = "3593e69e469d2111389a9bd06bac1f3d730ac6de"
uuid = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"
version = "0.9.4"

[[Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[cilkrts_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "45f98face02f3e1696a1ca4152268433121ba7b1"
uuid = "71772805-00bc-5a29-9044-a26d819b7806"
version = "0.1.2+0"

[[isoband_jll]]
deps = ["Libdl", "Pkg"]
git-tree-sha1 = "a1ac99674715995a536bbce674b068ec1b7d893d"
uuid = "9a68df92-36a6-505f-a73e-abb412b6bfb4"
version = "0.2.2+0"

[[libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "c45f4e40e7aafe9d086379e5578947ec8b95a8fb"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+0"

[[nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"

[[sgtsnepi_jll]]
deps = ["Artifacts", "FFTW_jll", "JLLWrappers", "Libdl", "Pkg", "cilkrts_jll"]
git-tree-sha1 = "02754e06363e07db5ab6a1d7f04b03dec68505c5"
uuid = "c2c51ba6-9464-585c-93d5-ba434ab08fad"
version = "2.0.0+0"

[[x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"
"""

# ╔═╡ Cell order:
# ╠═89b8e562-1252-11ec-17ca-cf7517afb20e
# ╟─4be35008-86b4-418a-b754-d70511b2a852
# ╠═4a7c2832-4465-4738-b875-b0bfc59fba7e
# ╟─d823fc97-b613-44cc-a5f1-62a22ca41abc
# ╟─fa0f9a70-5f4c-4e4f-8db0-bc56666431d1
# ╟─9c027964-6cb9-4406-a7d5-22081f4773fd
# ╟─6f3e0514-8d82-46f7-809b-8654eaa2d9e2
# ╠═e58c61ae-f464-4df2-9c17-f787e2add8c3
# ╟─ae8bbe30-7848-46b4-b463-c084d5f92627
# ╠═227b3145-a7c4-4db2-9a03-2fe267bfc722
# ╠═5e959a31-313f-4bba-9154-79d2bb6a85d4
# ╠═82003b0c-0f65-4348-8bb3-4bc93bc8b487
# ╠═a615112c-a3e6-42fa-b99a-986831c9a9fd
# ╠═6e68d35b-f386-4c20-b25a-794c4c49a1e4
# ╠═68f726b9-e70a-4e9d-bff6-3a8763d01f5c
# ╠═de0e3e9b-8e0f-48f3-8a63-7d57f6b4c4b1
# ╟─40414329-7d7f-4a85-b5c1-42f889696b97
# ╟─c0ae2c9b-18fd-4303-b60c-d6ad6e56f772
# ╟─7ac4a2bd-aa01-4272-a041-5d4bd2309828
# ╠═b36d74e7-db05-4efc-ba5e-428003ea8ea4
# ╟─d4dd90ab-fed3-4925-bf19-36d169483d5f
# ╟─a6a20163-6ed6-463c-9054-ba63890a7691
# ╟─afba4d8c-5d87-49a3-a00c-498d442cbb90
# ╟─81639687-8845-4ebe-a94c-171fbf2c763b
# ╟─93bda779-ca59-46d6-bdd5-8670a594b15e
# ╠═eb1f7822-8614-461a-bd22-12f25cdfba01
# ╠═e033ea39-f324-4618-a760-c5bd18a3b5c8
# ╠═50375d3c-2244-4137-b3c5-ebfd3861a7c1
# ╟─d1b61f6a-6439-4fd2-9cae-9f6c5bc23e6f
# ╠═9050790e-47ca-4196-8567-59e5c591cfa7
# ╠═9cb10585-a20d-4c8b-9c2d-358cdc0a7c8d
# ╟─2eb2b55d-38a5-4270-a443-a4b43da1dbe0
# ╠═267f1ce1-9df4-472b-a5ea-c19cf65a94c6
# ╟─bf422f25-bee2-4e5c-a92f-912f5c4ba4ce
# ╟─f91c060d-484c-4679-9a5d-664adb540559
# ╠═51fecba7-ec97-422e-bb58-65f4fd33855e
# ╠═654e87b3-d8a3-47e7-b798-be476af899a3
# ╠═b396ea76-6347-4ab3-b82e-a6e10b332dae
# ╠═4d17e42e-f1eb-4c8c-9272-fc1edf359cf8
# ╠═17bf6a38-b72a-42f7-89cb-3faa76f3aa7b
# ╠═ba52539d-9387-4f06-9ae1-d12a07b5c2d7
# ╠═11c48240-609b-4414-98f9-a7be19c9653d
# ╠═b55c67cd-701a-426c-8d33-8309be6a39ef
# ╠═b85895bd-20c7-4887-beca-4100840aadc8
# ╠═a47dceb2-cdaa-4c4f-82be-d27fd75471cd
# ╠═5efe21e3-fd04-4d04-9f08-355d8606778d
# ╠═7d3937ac-1cca-4c56-8830-162ebdd46b7b
# ╠═b22e0cc3-c134-4815-9f1e-2b6cca3778a1
# ╠═546d31e6-0520-426a-aa76-ba6ccdbfc0ae
# ╠═955f2697-6f2e-4fc2-89c6-4ced3e3a7138
# ╠═ab1e8588-6513-4c7f-8212-99318a59cfb9
# ╠═5a4edd6b-7c4c-4815-9cfc-9cea50ba902f
# ╠═7059ebce-d79f-4ebf-aa55-2c938daf69c9
# ╠═4f22cd6f-f8a3-4ab9-94a8-74c1277e6e0c
# ╠═e0ef1bfd-aaa3-4b98-8f2a-4c753ebe5e31
# ╠═d2c5a961-5796-4682-981d-40f8e8e7b364
# ╠═407b3c76-e04d-4d5a-8de1-78decc3733d6
# ╠═ec33a82b-1b17-4d1b-b914-96784437064a
# ╠═b9f76683-bab6-4c1c-b7be-6d2cf2f4ec71
# ╠═8f93d246-22a5-4dca-b1d3-898530eedca3
# ╟─53a0a6ad-f9a4-43db-bdea-3f6e855c785f
# ╠═ea00b4e8-a7bb-46be-b5de-333f55e3a32a
# ╠═fb98f4d5-d6c1-4c5f-a0f4-2049ae79ebcd
# ╠═e8b80d37-e12a-48f6-bdb4-d933e6622f66
# ╠═5b17085e-a408-4fa3-b917-f1ab97ac7112
# ╠═f5d2ebec-8a52-456e-9bf6-929da5a37f67
# ╠═4c8dbee2-ebf3-484f-be50-77a74bc3d855
# ╠═8f24f101-ba3f-43bf-91f1-22fb1501648e
# ╠═25f6f8d6-41a9-4ab6-995d-5a472d80bdfa
# ╠═1e6b67ff-3189-4f17-a436-26ef7c65b3a1
# ╠═71982546-0609-4723-bd38-0833cb865be7
# ╠═c4704605-32a1-4c11-add4-22ce0c2e5baf
# ╠═77a4dc8a-15f8-4a52-8ef4-7b72640e3810
# ╠═2c5d6268-b002-4782-88d2-d082454bcde0
# ╠═7ed75b62-544e-4e08-bd59-bcb23116c852
# ╠═e0084951-adf2-452d-bda1-2fb6a52cf316
# ╠═dfb5a1ba-2ce1-4ed7-b476-4d46a9bd2ae7
# ╠═5560e0ba-26a3-4dcd-a81e-080e5e3f52a0
# ╠═9e0a571c-64b9-48f9-a6f3-322e5b362903
# ╠═c796dcac-10be-43a1-8a06-8d054ead4b31
# ╠═7d829250-9a4b-4f83-8c1f-d68de7626acd
# ╠═fb84f920-d989-44ba-99ea-6b8d4cc135e4
# ╠═67faa5c3-795d-443d-b249-bd8b0f717774
# ╠═7821dc2c-87d8-4999-9871-7487cead5bad
# ╠═d9833595-8d07-475e-bb4b-d6ab88c41485
# ╠═1c909719-1839-4071-8165-e09e6e5ae9e7
# ╠═2af5937b-b123-422f-b2f9-e4e2e6d9d113
# ╠═f7c23ef0-1532-49f3-8298-0a243e402312
# ╠═ba45c719-540e-474d-8ec7-6024826e3c03
# ╠═09c3e9da-22b5-4d1b-8568-bb5de6f4c25c
# ╠═916bde7b-d45a-4b18-ae64-cf2dd3f5080b
# ╠═4c1e4b36-7270-45f0-a272-6c6e2ce88ea9
# ╠═5e5f58be-ee76-4500-9607-b5517c2a7a14
# ╠═17bee913-4365-4008-ade7-8059cf5cc22c
# ╠═94ecbff9-885e-4bd3-bbb0-93f17c5b2cdd
# ╠═d5d82300-f5fd-4d7e-8a19-33c0df0ea8d3
# ╠═841acad1-f891-453b-b87b-700fd6fc3023
# ╠═5ee5e49f-12b5-45de-a3f5-1145929d2c82
# ╠═9fe8afdf-1861-42b0-aa43-62ac5dc09288
# ╠═c77a5d3b-687f-46d7-9043-be4312485ba3
# ╠═cb1317a0-5fff-4aa8-ac92-f9d3d1876b43
# ╠═57166a7e-054f-40f2-b29c-3c80864b8e94
# ╠═737b592e-5843-4c62-ad59-b58b39d46adb
# ╠═14da725d-82e4-4f6d-9e4f-240001a2c982
# ╠═ff215580-86d1-4286-b974-f200a8b014a4
# ╠═7b084ef8-6a89-4c5a-8de0-7ba9f1a9fcc4
# ╠═b69bc373-18e0-491e-93bf-045852093378
# ╠═7884f473-2c30-482f-9a2e-c52617291898
# ╠═c24330e2-55c6-457b-965d-fd3c0a3089ce
# ╠═c01a06a1-6bba-4da2-8ce8-24e0c77d39c0
# ╠═81a0f8bd-725b-4cda-91ef-0d713766caa0
# ╠═0f223764-99ac-465c-8dad-93278a415d4a
# ╠═3c0cb4ab-7bd7-4fec-b637-d61c84d1d296
# ╠═797bc58f-74e9-4e49-bbf5-7b2395d9ab66
# ╟─cd797616-f87f-40fd-ad4a-ecd7c05672ea
# ╟─74cb65eb-13fa-4908-939f-0c01b17b0917
# ╟─3e8e0e0a-d404-4a0b-89f4-e55e90c7de30
# ╟─51c9ce07-3876-4680-8078-8de41bcbb9bf
# ╟─03760fc5-8fdf-4bc5-9ada-43d727693aba
# ╟─7bd238d8-797d-48d9-b65e-42d271b727fe
# ╟─0eb1f986-a29a-4a40-9b53-852b49e09e6c
# ╠═f0ef5755-005a-4bbe-a30f-789ee1ba8c0e
# ╠═b2a69e19-be4b-4177-b9c5-a513d7dd4cf5
# ╠═81d7e76c-cf26-4340-801e-7e26ae07527e
# ╠═abbe65b4-a62b-4e2d-9f55-a7937c3b8935
# ╠═31e9c9c4-627d-402b-911d-617b08fb6830
# ╠═977738ca-21d3-42e6-9aac-85cd64bb2f65
# ╠═dd3c357b-a489-460a-bbb6-cf162d0351cf
# ╠═c6a480a9-cf6a-4e02-b2bb-49b9d7b16ff6
# ╠═50e2acb9-adfd-4e6d-8e0c-59bc87917488
# ╠═dbe49d71-4821-4883-ae7d-cdcc7f829e03
# ╠═29d1129f-2b62-4831-8efc-76c7f5869302
# ╠═845ef5bc-70d6-4ebd-8756-0868e4d66059
# ╠═16cea35a-d84b-428a-8be1-142db030f1cc
# ╠═06514b52-b647-4791-b816-137a0f7feca9
# ╠═4609a7f0-d2ba-402e-a22e-c69437e2a57f
# ╠═07df7026-541b-40d7-a0f5-5efa74132671
# ╠═e06571d6-a7f5-4d18-8e83-6f1fd836b05c
# ╠═3cfc20e5-89da-41b3-a17e-906b14288d79
# ╠═cf5941da-7ee0-4791-a50d-339e849b4907
# ╠═62292693-709d-44b3-88d8-c3b186584d3f
# ╠═49a8e0e5-341e-4d7d-b2f6-f3639c743ce0
# ╠═8bdfef1a-a3af-4aa6-b894-84503ddb2cea
# ╠═8353e29f-8eb1-4997-b3f3-3fbf7bffc771
# ╠═2266b23c-0603-4906-bfdc-8164e289d186
# ╠═d864dcd3-5faf-4467-8b44-f7c60a908ef0
# ╠═7d9a56ca-e6a4-4465-b01c-4b53138d87bd
# ╠═330fb435-d236-4fd9-a94b-a5f8297353a2
# ╠═9e05b350-4539-48ae-84fa-68df38104906
# ╠═42e7e7d9-2bf5-4440-a59c-5eb34562fd46
# ╠═32d4bbc3-e144-40be-9fc6-4a39196f7c76
# ╠═1155e90c-65b2-4c55-9c4f-18ac49195691
# ╠═485188ca-2759-49c2-93c6-3da34dd0e686
# ╠═cf78994f-5df9-4c3e-bfb5-405fe9c382a8
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
