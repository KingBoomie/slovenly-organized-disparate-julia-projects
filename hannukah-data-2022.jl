### A Pluto.jl notebook ###
# v0.19.12

using Markdown
using InteractiveUtils

# ╔═╡ d73dae94-8abd-11ed-16e5-ed217c7262a7
begin
	using DataFrames
	using CSV
	using PlutoUI
	using Chain
	using Dates
end

# ╔═╡ 73efb0cc-10a8-4f19-be44-6369dcab3683
TableOfContents()

# ╔═╡ 20304c5a-cb73-4dc6-b63e-0c040e5e9b08
md"# Data"

# ╔═╡ 45fae90a-f9a2-4f33-990a-330610203e7b
customers = CSV.read("hannukah-data-assets/noahs-customers.csv", DataFrame)

# ╔═╡ 05d8f9bd-e591-42a8-83d0-2a0f7827e2b5
orders = @chain CSV.read("hannukah-data-assets/noahs-orders.csv", DataFrame) begin
	transform(
		:ordered => ByRow(x-> DateTime(replace(x, " " => "T"))) => :ordered, 
	    :shipped => ByRow(x-> DateTime(replace(x, " " => "T"))) => :shipped
	)
end

# ╔═╡ 699857c0-6d4a-4439-86df-b0b6a972a304
orders_items = CSV.read("hannukah-data-assets/noahs-orders_items.csv", DataFrame)

# ╔═╡ cce2dbf3-a3c0-45dc-a4bf-036e95330908
products = CSV.read("hannukah-data-assets/noahs-products.csv", DataFrame)

# ╔═╡ f4928604-fc79-49ab-b370-58cbebe1064a
md"""# Day 1. 
Took 34 minutes to solve"""

# ╔═╡ 6d9baff5-a77d-4538-a900-19bafb550475
num_letter_map = Dict(
	'2' => r"[abc]",
	'3' => r"[def]",
	'4' => r"[ghi]",
	'5' => r"[jkl]",
	'6' => r"[mno]",
	'7' => r"[pqrs]",
	'8' => r"[tuv]",
	'9' => r"[wxyz]",
	'0' => r".?",
	'-' => r".?",
)

# ╔═╡ 31f9363e-687f-4e4e-a286-a84c18113b2f
function name_regex(phone)
	re = mapreduce(*, collect(phone)) do c
		get(num_letter_map, c, r".")
	end
end

# ╔═╡ 5cf58dc7-95dd-49d2-97fe-260b4b43549f
@chain customers begin
	transform(:phone => ByRow(name_regex))
	subset([:name, :phone_name_regex] => ByRow((n, re) -> occursin(re, lowercase(n))))
end

# ╔═╡ fbf5163f-ff36-4984-96e0-ca7c31fb55d5
re = mapreduce(*, collect("805-287-8515")) do c
	get(num_letter_map, c, r".")
end

# ╔═╡ 65ed65f1-4bd7-4e4e-ad22-18db9e1f384b
occursin(re, lowercase("t.j.Atp.tj.j"))

# ╔═╡ 25b43b34-5e44-4d44-8932-530973a3356e
md"""# Day 2
Took 58 minutes to solve
"""

# ╔═╡ 10e83aae-7f63-4a8b-bee1-9c81fc3fe3f1
customerJDs = subset(customers, :name => ByRow(n -> occursin(r"J[a-zA-Z]+ D[a-zA-Z]", n)))

# ╔═╡ caa57bcf-566f-4d21-b72e-4152f20dd925
orderJD = leftjoin(orders, customerJDs, on=:customerid)

# ╔═╡ 17b135b1-a7e6-46d9-876d-b210931a31e4
years_mask = map(orderJD.ordered) do d
	year(d) == 2017
end

# ╔═╡ c58fbb49-5924-4ddd-aa36-e2c6c8906ae0
order2017JD = orderJD[years_mask, :]

# ╔═╡ 744c4fe4-dbae-4448-a255-c0919a8337c3
coffees = subset(products, :desc => p -> occursin.(r"coffee"i, p))

# ╔═╡ 4fd8d675-14a3-4292-8613-f414a06e8734
coffeeSKU = coffees[3, :sku]

# ╔═╡ 77e46418-439b-457f-b05d-3c9ddf85812f
bagelss = subset(products, :desc => p -> occursin.(r"bagel"i, p))

# ╔═╡ 01ece661-9669-44bd-a493-a5c49862bdd8
bagelSKUs = bagelss.sku

# ╔═╡ ace270e6-e95f-4516-aff4-0a895d49a0f4
SKUs1 = [coffeeSKU; bagelSKUs[1]]

# ╔═╡ 75954696-c6e8-4ec5-a547-b162e81d938d
SKUs2 = [coffeeSKU; bagelSKUs[2]]

# ╔═╡ cc4c83a0-169e-409f-861c-7d1f3067ebeb
orderiid = @chain orders_items begin
	subset(:orderid => ByRow(Base.Fix2(∈, order2017JD.orderid)))
	groupby(:orderid)
	filter(_) do subdf # filter for coffee and bagels
		all(sku ∈ subdf.sku for sku in SKUs1) || 
		all(sku ∈ subdf.sku for sku in SKUs2)
	end
	_[1]
end

# ╔═╡ 0b82ae48-05c8-4646-8319-4c6e2cf20898
customer2 = subset(orderJD, :orderid => ByRow(==(orderiid[1, :orderid])) ).customerid[1]

# ╔═╡ 4a7c7fef-0fb4-42f4-b9ee-beb9ffe4f709
subset(orders, :orderid => ByRow(==(7409)))

# ╔═╡ 56787e7d-fa37-415c-bc4a-6e21095c586d
subset(customerJDs, :customerid => ByRow(==(customer2)))

# ╔═╡ 392377cf-7669-4db0-8cc1-e18a0698dbe8
md""" # Day 3
Took 13 minutes to solve
"""

# ╔═╡ 96c0ff91-0c9f-44f8-b0df-eca8297f1593
dog_years = [1922, 1934, 1946, 1958, 1970, 1982, 1994, 2006, 2018]

# ╔═╡ 5a4e7dca-1073-4faf-af52-be07d70faa64
function is_aries_dog(date::Date)
	y = year(date)
	y ∈ dog_years && Date(y, 3, 21) <= date <= Date(y, 4, 19)
end

# ╔═╡ 8b545346-460e-4e91-9c35-99b68fdf03bf
subset(customers, :birthdate => ByRow(is_aries_dog), :citystatezip => ByRow(==("South Ozone Park, NY 11420")))

# ╔═╡ d39655f6-1c8f-4fc6-bd22-a2d9bb295b0b
md"""# Day 4
47 minutes to solve
"""

# ╔═╡ 94336ddd-fa46-4dcc-927c-8bc52a75fde6
orders[orders.customerid .== 2274, :] # => dog guy did shopping around 2017-08-12

# ╔═╡ 84141dbf-bca8-465f-bf74-f9a2dbcc72ec
pastries = subset(products, :sku => p -> occursin.("BKY", p))

# ╔═╡ 6a04b979-f753-4e9b-b00e-4092f7b9bd09
bagel_customers = @chain orders begin
	# subset(:shipped => ByRow(x -> Date(2018) >= x >= Date(2017)))
	subset(:shipped => ByRow(x-> Time(0) <= Time(x) <= Time(5, 40)))
	leftjoin(orders_items, on=:orderid)
	subset(:sku => ByRow(startswith("BKY")))
	subset(:qty => ByRow(>(1)))
	
	#groupby(:orderid)
	#combine(nrow)
	#subset(:nrow => ByRow(>(1)))
	
	# groupby(:orderid)
	# leftjoin(products, on=:sku)
end

# ╔═╡ 0594ebf4-ad25-4571-bd24-2065bc388ec4
customer4 = subset(customers, :customerid => ByRow(∈(bagel_customers.customerid)))[4, :]

# ╔═╡ 36aeadd7-dd76-4b4d-a0ba-f4139c298e36
md"""# Day 5
Took 18 minutes to solve
"""

# ╔═╡ 377d5a61-1a68-4347-b7ba-233f0fb7b3b1
shirts = subset(products, :desc => p -> occursin.(r"Noah's Jersey"i, p)).sku

# ╔═╡ cbab1dc1-0c3b-4242-85d4-c902b4a2e4b2
shirt_customers = @chain orders begin
	leftjoin(orders_items, on=:orderid)
	subset(:sku => ByRow(∈(shirts)))
end

# ╔═╡ 7c308b3f-a27e-407b-904d-bb3de70f6a63
cat_food = subset(products, :desc => p -> occursin.(r"cat"i, p)).sku

# ╔═╡ c28c9136-c88c-42bc-b26d-a4b2d1801991
cat_customers = @chain orders begin
	leftjoin(orders_items, on=:orderid)
	subset(:sku => ByRow(∈(cat_food)))
	# groupby(:customerid)
	# combine(nrow)
	# sort(order(:nrow, rev=true))
	# innerjoin(shirt_customers, on=:customerid)
end

# ╔═╡ f15db3ed-bf52-4fe2-80ea-3e3daaed4afc
cat_shirt_customers = unique(cat_customers.customerid)

# ╔═╡ 4ba656aa-1ad4-4042-b752-5e05316d22ea


# ╔═╡ e2c91880-ad3e-4aac-9a17-5d8bc5a8a2fc
customer5 = subset(customers, 
	:customerid => ByRow(x -> x ∈ cat_shirt_customers), 
	:citystatezip => ByRow(==("Queens Village, NY 11429"))
)

# ╔═╡ c7eb5aec-824f-4d44-aa78-e8d799bab2dc
cities = unique(customers.citystatezip)

# ╔═╡ 5c59c657-020b-4d04-9527-7849c3f8fa28
cities[occursin.("Queens", cities)]

# ╔═╡ 4ac2a8c2-bb8e-4731-bd9c-b7c4dcf62448
md"""# Day 6
Solved in 23 minutes
"""

# ╔═╡ b7ef7884-421f-416e-8dda-c25dfd9b51de
biggest_winners = @chain orders_items begin
	# groupby(:orderid)
	innerjoin(products, on=:sku)
	transform([:unit_price, :wholesale_cost] => ByRow((unit, wholesale) -> unit - wholesale) => :win)
	subset(:win => ByRow(<(0)))
	leftjoin(orders, on=:orderid)
	
	groupby(:customerid)
	combine(:win => sum)
	leftjoin(customers, on=:customerid)
	sort(order(:win_sum))
end

# ╔═╡ a23441df-fc09-424b-b796-da24d6d6fbe2
customer6 = subset(customers, :customerid => ByRow(==(8342)))

# ╔═╡ 425267d2-c332-4baf-90eb-dc133045d386
md"""# Day 7
Solving took 72 minutes
"""

# ╔═╡ ba4f86ae-5ead-4dc1-9099-d8acfadb37e5
colored = subset(products, :sku => ByRow(startswith("COL"))).sku

# ╔═╡ a6b7784d-0e81-4e7d-8fe6-cdc8aebcb5e2
c6id = customer6[1, :customerid]

# ╔═╡ c32e2b91-08e9-4358-8ec1-627dcba1376b
day6woman_colored = @chain orders_items begin
	# subset(:sku => ByRow(∈(colored)))
	innerjoin(orders, on=:orderid)
	subset(:customerid => ByRow(==(c6id)))
end

# ╔═╡ ba912b49-76de-4ce1-818e-5dffefd21055
day6woman_colored_date = @chain day6woman_colored begin
	select(:ordered => ByRow(Date))
	_[:, 1]
end

# ╔═╡ f148bdf3-1a75-455e-89af-494a6f546fb7
day6woman_colored_datetime = @chain day6woman_colored begin
	select(:ordered)
	_[:, 1]
end

# ╔═╡ fd3671f4-45e0-48a7-86c9-069d6deecd0f
colored2 = day6woman_colored.sku

# ╔═╡ a9987b0c-5191-40ce-ac18-bb4ec3e8c64b
sameday = @chain orders begin
	leftjoin(orders_items, on=:orderid)
	# subset(:sku => ByRow(∈(colored)))
	transform(:ordered => ByRow(Date) => :ordered_date)
	subset(:ordered_date => ByRow(∈(day6woman_colored_date)))

	transform(:ordered => ByRow(s -> minimum(abs, s .- day6woman_colored_datetime)) => :timediff)
	subset(:timediff => ByRow(<(Hour(1))))
	
	leftjoin(products, on=:sku)
	subset(:desc => ByRow(contains("(")))
	transform(:desc => ByRow(x -> split(x, " (")) .=> AsTable)
	select(Not([:shipped, :items, :total, :qty, :unit_price, :desc, :wholesale_cost]))
	groupby([:x1, :ordered_date])
	filter(_) do subdf
		nrow(subdf) > 1 &&
		c6id ∈ subdf.customerid
	end
	
	# combine(nrow)
	# innerjoin(orders_items, on=:sku)
	

end

# ╔═╡ 83fc88d7-be76-4b31-bf76-57c87977b9d5
customers7 = combine(sameday, :customerid).customerid |> unique

# ╔═╡ 6d247f7c-646a-497c-b82f-9d5655edbf88
customer7 = subset(customers, :customerid => ByRow(∈(customers7)))

# ╔═╡ b9f2d070-f775-441a-aa35-c012a3c201ab
md"""# Day 8
solving took 12 minutes
"""

# ╔═╡ 33d0020f-fe20-4abc-a26e-c4f9e38eeac4
collectibles = subset(products, :desc => p -> occursin.(r"noah"i, p)).sku

# ╔═╡ e0f6b329-d0e6-4471-91c5-bd45c31e45c9
customers8 = @chain orders begin
	leftjoin(customers, on=:customerid)
	leftjoin(orders_items, on=:orderid)
	subset(:sku => ByRow(∈(collectibles)))
	groupby([:customerid, :sku])
	combine(nrow)
	groupby([:customerid])
	combine(nrow)
	sort(order(:nrow, rev=true))
end

# ╔═╡ 5aa1c3eb-d2be-4448-aaa5-c0733740a7a9
customer8 = subset(customers, :customerid => ByRow(==(4308)))

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
Chain = "8be319e6-bccf-4806-a6f7-6fae938471bc"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
CSV = "~0.10.8"
Chain = "~0.5.0"
DataFrames = "~1.4.4"
PlutoUI = "~0.7.49"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.3"
manifest_format = "2.0"
project_hash = "72d7e50bf87b76203db494e9ba351963b9b6690c"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "SnoopPrecompile", "Tables", "Unicode", "WeakRefStrings", "WorkerUtilities"]
git-tree-sha1 = "8c73e96bd6817c2597cfd5615b91fca5deccf1af"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.8"

[[deps.Chain]]
git-tree-sha1 = "8c4920235f6c561e401dfe569beb8b924adad003"
uuid = "8be319e6-bccf-4806-a6f7-6fae938471bc"
version = "0.5.0"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.Compat]]
deps = ["Dates", "LinearAlgebra", "UUIDs"]
git-tree-sha1 = "00a2cccc7f098ff3b66806862d275ca3db9e6e5a"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.5.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "0.5.2+0"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "e8119c1a33d267e16108be441a287a6981ba1630"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.14.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Random", "Reexport", "SnoopPrecompile", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "d4f69885afa5e6149d0cab3818491565cf41446d"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.4.4"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "e27c4ebe80e8699540f2d6c805cc12203b614f12"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.20"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "0cf92ec945125946352f3d46c96976ab972bde6f"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.3.2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InvertedIndices]]
git-tree-sha1 = "82aec7a3dd64f4d9584659dc0b62ef7db2ef3e19"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.2.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Parsers]]
deps = ["Dates", "SnoopPrecompile"]
git-tree-sha1 = "6466e524967496866901a78fca3f2e9ea445a559"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.5.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "eadad7b14cf046de6eb41f13c9275e5aa2711ab6"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.49"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "LaTeXStrings", "Markdown", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "96f6db03ab535bdb901300f88335257b0018689d"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.2.2"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "efd23b378ea5f2db53a55ae53d3133de4e080aa9"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.16"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SnoopPrecompile]]
git-tree-sha1 = "f604441450a3c0569830946e5b33b78c928e1a85"
uuid = "66db9d55-30c0-4569-8b51-7e840670fc0c"
version = "1.0.1"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "a4ada03f999bd01b3a25dcaa30b2d929fe537e00"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.1.0"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StringManipulation]]
git-tree-sha1 = "46da2434b41f41ac3594ee9816ce5541c6096123"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.3.0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "c79322d36826aa2f4fd8ecfa96ddb47b174ac78d"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.10.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "e4bdc63f5c6d62e80eb1c0043fcc0360d5950ff7"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.10"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.URIs]]
git-tree-sha1 = "ac00576f90d8a259f2c9d823e91d1de3fd44d348"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.WorkerUtilities]]
git-tree-sha1 = "cd1659ba0d57b71a464a29e64dbc67cfe83d54e7"
uuid = "76eceee3-57b5-4d4a-8e66-0e911cebbf60"
version = "1.6.1"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

# ╔═╡ Cell order:
# ╠═d73dae94-8abd-11ed-16e5-ed217c7262a7
# ╠═73efb0cc-10a8-4f19-be44-6369dcab3683
# ╠═20304c5a-cb73-4dc6-b63e-0c040e5e9b08
# ╠═45fae90a-f9a2-4f33-990a-330610203e7b
# ╠═05d8f9bd-e591-42a8-83d0-2a0f7827e2b5
# ╠═699857c0-6d4a-4439-86df-b0b6a972a304
# ╠═cce2dbf3-a3c0-45dc-a4bf-036e95330908
# ╠═f4928604-fc79-49ab-b370-58cbebe1064a
# ╠═5cf58dc7-95dd-49d2-97fe-260b4b43549f
# ╠═31f9363e-687f-4e4e-a286-a84c18113b2f
# ╠═6d9baff5-a77d-4538-a900-19bafb550475
# ╠═fbf5163f-ff36-4984-96e0-ca7c31fb55d5
# ╠═65ed65f1-4bd7-4e4e-ad22-18db9e1f384b
# ╠═25b43b34-5e44-4d44-8932-530973a3356e
# ╠═10e83aae-7f63-4a8b-bee1-9c81fc3fe3f1
# ╠═caa57bcf-566f-4d21-b72e-4152f20dd925
# ╠═17b135b1-a7e6-46d9-876d-b210931a31e4
# ╠═c58fbb49-5924-4ddd-aa36-e2c6c8906ae0
# ╠═744c4fe4-dbae-4448-a255-c0919a8337c3
# ╠═4fd8d675-14a3-4292-8613-f414a06e8734
# ╠═77e46418-439b-457f-b05d-3c9ddf85812f
# ╠═01ece661-9669-44bd-a493-a5c49862bdd8
# ╠═ace270e6-e95f-4516-aff4-0a895d49a0f4
# ╠═75954696-c6e8-4ec5-a547-b162e81d938d
# ╠═cc4c83a0-169e-409f-861c-7d1f3067ebeb
# ╠═0b82ae48-05c8-4646-8319-4c6e2cf20898
# ╠═4a7c7fef-0fb4-42f4-b9ee-beb9ffe4f709
# ╠═56787e7d-fa37-415c-bc4a-6e21095c586d
# ╠═392377cf-7669-4db0-8cc1-e18a0698dbe8
# ╠═96c0ff91-0c9f-44f8-b0df-eca8297f1593
# ╠═5a4e7dca-1073-4faf-af52-be07d70faa64
# ╠═8b545346-460e-4e91-9c35-99b68fdf03bf
# ╠═d39655f6-1c8f-4fc6-bd22-a2d9bb295b0b
# ╠═94336ddd-fa46-4dcc-927c-8bc52a75fde6
# ╠═84141dbf-bca8-465f-bf74-f9a2dbcc72ec
# ╠═6a04b979-f753-4e9b-b00e-4092f7b9bd09
# ╠═0594ebf4-ad25-4571-bd24-2065bc388ec4
# ╠═36aeadd7-dd76-4b4d-a0ba-f4139c298e36
# ╠═377d5a61-1a68-4347-b7ba-233f0fb7b3b1
# ╠═cbab1dc1-0c3b-4242-85d4-c902b4a2e4b2
# ╠═7c308b3f-a27e-407b-904d-bb3de70f6a63
# ╠═c28c9136-c88c-42bc-b26d-a4b2d1801991
# ╠═f15db3ed-bf52-4fe2-80ea-3e3daaed4afc
# ╠═4ba656aa-1ad4-4042-b752-5e05316d22ea
# ╠═e2c91880-ad3e-4aac-9a17-5d8bc5a8a2fc
# ╠═5c59c657-020b-4d04-9527-7849c3f8fa28
# ╠═c7eb5aec-824f-4d44-aa78-e8d799bab2dc
# ╠═4ac2a8c2-bb8e-4731-bd9c-b7c4dcf62448
# ╠═b7ef7884-421f-416e-8dda-c25dfd9b51de
# ╠═a23441df-fc09-424b-b796-da24d6d6fbe2
# ╟─425267d2-c332-4baf-90eb-dc133045d386
# ╠═ba4f86ae-5ead-4dc1-9099-d8acfadb37e5
# ╠═a6b7784d-0e81-4e7d-8fe6-cdc8aebcb5e2
# ╠═ba912b49-76de-4ce1-818e-5dffefd21055
# ╠═f148bdf3-1a75-455e-89af-494a6f546fb7
# ╠═c32e2b91-08e9-4358-8ec1-627dcba1376b
# ╠═fd3671f4-45e0-48a7-86c9-069d6deecd0f
# ╠═a9987b0c-5191-40ce-ac18-bb4ec3e8c64b
# ╠═6d247f7c-646a-497c-b82f-9d5655edbf88
# ╠═83fc88d7-be76-4b31-bf76-57c87977b9d5
# ╟─b9f2d070-f775-441a-aa35-c012a3c201ab
# ╠═33d0020f-fe20-4abc-a26e-c4f9e38eeac4
# ╠═e0f6b329-d0e6-4471-91c5-bd45c31e45c9
# ╠═5aa1c3eb-d2be-4448-aaa5-c0733740a7a9
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
