### A Pluto.jl notebook ###
# v0.19.5

using Markdown
using InteractiveUtils

# ╔═╡ c1d8b2dc-9d53-437b-a5ef-683451518ddd
begin
	using PlutoUI
	using Chain
	using Dates
end

# ╔═╡ 8ce90108-fe66-4a03-a8c6-0367f0fb8981
read("/home/kris/dev/yanu-workspace/logs3/rosout.log", String)

# ╔═╡ 02ea6b9c-c6fb-11ec-3163-8372a0f47aa1
begin
	file = read("/home/kris/dev/yanu-workspace/logs3/rosout.log", String)
	log = @chain file begin
		split(_, "\n165")
		_[3:end]
		map(_) do line
			ts, loglevel, node, lineno, rest = split(line, " ", limit=5)
			topics, message = split(rest, r"\[[^\]]+\]")
			time = Dates.unix2datetime(parse(Float32, string("165", ts)))
			(;node,time,message)
		end
	end
end

# ╔═╡ a5e0cefc-ee35-4535-9480-e6b97c3109df
function preparing_drinks(log)
	@chain log begin
		filter((x -> x.node == "/Yanu_Engine_Server"), _)
		filter((x -> contains(x.message, "recipe: ") || contains(x.message, "FINAL State completed Successfully.")), _)
	end
end

# ╔═╡ 00fa6621-6d60-456b-9e29-5dc80e77ca5c
preparing_drinks1 = preparing_drinks(log)

# ╔═╡ 6a1d9d01-67cc-4913-99de-b66a8c30517e
line = file

# ╔═╡ 0a476e4e-bbe7-4f5c-a352-56380a5ca276
ts, loglevel, node, lineno, rest = split(line, " ", limit=5)

# ╔═╡ d9f9f0c6-e566-42f9-bf6d-3aef79aa84cf
topics, message = split(rest, "] ")

# ╔═╡ 90b52464-5f52-47ea-bbec-5ad244d9c687
message

# ╔═╡ aaf105f8-b5a0-4c8d-a519-6a010712cde9
cd("/home/kris/dev/yanu-workspace/logs")

# ╔═╡ 81f2cc1d-721f-42fe-a585-ce9295c61079
begin
	all_the_logs = []
	for folder in readdir()
		if isdir(folder)
			for filename in readdir(folder)
				filepath = string(folder, "/", filename)
				if filesize(filepath) > 100 && contains(filename, "rosout")
					push!(all_the_logs, read(filepath, String))
				end
			end
		end
	end
	all_the_logs
end

# ╔═╡ 7c3ac9ce-0e5b-42a2-ba4b-236e341d98a8
begin
	res = map(all_the_logs) do file
		log = @chain file begin
			split(_, "\n16526")
			_[3:end]
			map(_) do line
				ts, loglevel, node, lineno, rest = split(line, " ", limit=5)
				topics, message = split(rest, r"\[[^\]]+\]")
				time = Dates.unix2datetime(parse(Float32, string("16526", ts)))
				(;node,time,message)
			end
			filter(_) do x
				x.node == "/Yanu_Engine_Server" && x.message != " Current state COCKTAIL_WAITING_ORDER" && x.time > DateTime("2022-04-29T10:50:00")
			end
			map(_) do x
				(x.message, x.time)
			end
		end
	end
	res1 = filter(!isempty, res)
	# fil(res1) do log
	# 	map(log) do
			
end

# ╔═╡ 708776ef-62ab-44c5-bde3-868d7e27deec
begin
	res2 = map(all_the_logs) do file
		log = @chain file begin
			split(_, "\n16526")
			_[3:end]
			map(_) do line
				ts, loglevel, node, lineno, rest = split(line, " ", limit=5)
				topics, message = split(rest, r"\[[^\]]+\]")
				time = Dates.unix2datetime(parse(Float32, string("16526", ts)))
				(;node,time,message)
			end
			filter(_) do x 
				contains(x.message, "recipe: ") || contains(x.message, "FINAL State completed Successfully.")
			end
			map(_) do x
				(x.message, x.time)
			end
		end
	end
	res3 = filter(!isempty, res2)
	# fil(res1) do log
	# 	map(log) do
			
end

# ╔═╡ 2982279b-8fa8-43e1-945c-f53d1b92ee42
Dates.unix2datetime(1652660000)

# ╔═╡ 3637c0cb-b6ab-4662-acbf-23dd53738838
map(length, res1)

# ╔═╡ 3862f1fe-7529-46ea-b0eb-da04029abb6e
60*60*1000 * 150 / 1024 / 1024 * 24

# ╔═╡ 4920d59e-b234-445e-8cee-74a642adb5a4
(map(length, all_the_logs) |> sum) / 1024 / 1024

# ╔═╡ 66dc85c7-28f9-40ba-acf2-f165218c0ef9
6 * 6.7 * 24

# ╔═╡ b171680a-7c8f-46fd-bfff-45689569ea78


# ╔═╡ ccb0fc9a-97c5-4673-87b3-ebe28b2ae250


# ╔═╡ a6775aea-3068-4fba-8ed1-5f66a4095248


# ╔═╡ 287930e3-a337-4525-888e-923974701352


# ╔═╡ 7d1d5ca2-091b-4ead-8d92-cb0b397a35b7


# ╔═╡ 27add3ee-7f71-44ef-8b35-a936b10cbd4b


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Chain = "8be319e6-bccf-4806-a6f7-6fae938471bc"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
Chain = "~0.4.10"
PlutoUI = "~0.7.38"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.0"
manifest_format = "2.0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Chain]]
git-tree-sha1 = "339237319ef4712e6e5df7758d0bccddf5c237d9"
uuid = "8be319e6-bccf-4806-a6f7-6fae938471bc"
version = "0.4.10"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

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

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

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

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "1285416549ccfcdf0c50d4997a94331e88d68413"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.3.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "670e559e5c8e191ded66fa9ea89c97f10376bb4c"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.38"

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

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╠═c1d8b2dc-9d53-437b-a5ef-683451518ddd
# ╠═8ce90108-fe66-4a03-a8c6-0367f0fb8981
# ╠═02ea6b9c-c6fb-11ec-3163-8372a0f47aa1
# ╠═00fa6621-6d60-456b-9e29-5dc80e77ca5c
# ╠═a5e0cefc-ee35-4535-9480-e6b97c3109df
# ╠═6a1d9d01-67cc-4913-99de-b66a8c30517e
# ╠═0a476e4e-bbe7-4f5c-a352-56380a5ca276
# ╠═d9f9f0c6-e566-42f9-bf6d-3aef79aa84cf
# ╠═90b52464-5f52-47ea-bbec-5ad244d9c687
# ╠═aaf105f8-b5a0-4c8d-a519-6a010712cde9
# ╠═81f2cc1d-721f-42fe-a585-ce9295c61079
# ╠═7c3ac9ce-0e5b-42a2-ba4b-236e341d98a8
# ╠═708776ef-62ab-44c5-bde3-868d7e27deec
# ╠═2982279b-8fa8-43e1-945c-f53d1b92ee42
# ╠═3637c0cb-b6ab-4662-acbf-23dd53738838
# ╠═3862f1fe-7529-46ea-b0eb-da04029abb6e
# ╠═4920d59e-b234-445e-8cee-74a642adb5a4
# ╠═66dc85c7-28f9-40ba-acf2-f165218c0ef9
# ╠═b171680a-7c8f-46fd-bfff-45689569ea78
# ╠═ccb0fc9a-97c5-4673-87b3-ebe28b2ae250
# ╠═a6775aea-3068-4fba-8ed1-5f66a4095248
# ╠═287930e3-a337-4525-888e-923974701352
# ╠═7d1d5ca2-091b-4ead-8d92-cb0b397a35b7
# ╠═27add3ee-7f71-44ef-8b35-a936b10cbd4b
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
