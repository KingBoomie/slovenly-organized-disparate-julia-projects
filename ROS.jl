### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ 28dec7bc-c846-11eb-2576-0d28a2569db6
begin
	using Pkg
	Pkg.activate(mktempdir())
end

# ╔═╡ bcdf3958-9a53-437f-8c0e-529b37e3e833
begin
	Pkg.add(["Plots", "PlutoUI","StatsBase", "DataStructures", "Unitful", "UnitfulRecipes", "PhysicalConstants", "UnitfulEquivalences", "DataFrames", "CSV", "Dates", "TimeZones", "StatsPlots", "ImageFiltering", "OffsetArrays", "FileIO", "StaticArrays", "FastIOBuffers", "TranscodingStreams", "CodecBzip2", "Tokenize", "DataInterpolations", "GR"])
	Pkg.develop(["RobotOSData"])

	using Plots
	gr()
	# plotly()
	using PlutoUI
	using StatsBase
	using DataStructures
	using Unitful
	using PhysicalConstants.CODATA2018: c_0, h, ħ
	using UnitfulEquivalences
	using UnitfulRecipes
	using DataFrames
	using CSV
	using TimeZones
	using Dates
	using StatsPlots
	using ImageFiltering
	using OffsetArrays
	using RobotOSData
	using FileIO
	using StaticArrays
	using DataInterpolations
end

# ╔═╡ c13e43d4-b7d6-4d65-996d-b2568d43b9f4
module ExtraMessages
    module tf2_msgs
        using RobotOSData.Messages # imports Readable, Header
        using RobotOSData.StdMsgs
        using RobotOSData.CommonMsgs # for sensor_msgs
        struct TFMessage <: Readable
	        transforms::Vector{geometry_msgs.TransformStamped}
        end
    end
end

# ╔═╡ ebbe541a-7ae5-4b18-b079-239bd733c5fb
bag = load("/home/kris/learning/robotont/bagfiles/straight-movement2.bag", ExtraMessages)

# ╔═╡ 433f3fe3-45c6-43c4-84f1-7b54178ed34a
bag.topic_map

# ╔═╡ 977dbaf0-ed9b-4582-9378-8e1eabd1a1c1
time_range = ROSTime("2021-06-10T11:08:50"):ROSTime("2021-06-10T11:09:21")

# ╔═╡ 10e08ba1-6e48-4d6c-8949-83e0c8ee82e7
tfs = [tf for msg ∈ bag[RobotOSData.ConnectionFilter(2), time_range] for tf ∈ msg.data.transforms ]

# ╔═╡ 0df647f5-340f-4b8a-9826-4ee55ea66890
countmap([tf.child_frame_id for tf ∈ tfs])

# ╔═╡ bf83571f-c7f5-45d9-87a9-23c2bcff04fe
zs = [(convert(DateTime, tf.header.time), tf.transform.translation.z) for tf ∈ tfs if tf.child_frame_id ∈ ("tag_5","tag_6")]

# ╔═╡ 8f96e1d2-32e4-46d8-998c-7728f4204fda
df = DataFrame(NamedTuple{(:time, :pos)}.(zs))

# ╔═╡ 79d2d3ed-d65d-44b2-aa6c-6964785a044a
mzs = combine(groupby(df, [:time]), :pos => mean => :mpos)

# ╔═╡ d42aa9df-4991-494e-a30d-24351ede8a0a
@df mzs plot(:time, [:mpos], ticks=:native)

# ╔═╡ fa2f217f-0184-4947-b161-191feba95d42
dist = mzs[!, :mpos] .* u"m" # add units

# ╔═╡ accbb017-a1c4-4122-b2ce-7711a946312a
time = mzs[!, :time] - mzs[1, :time]

# ╔═╡ 02e4c44e-42d7-4064-b522-1384122eee5e
plot(time[2:end], diff(dist) * u"1/s", title="Not smoothed", ylabel="speed")

# ╔═╡ 854e8a1a-3caa-4661-ba85-d0542f1489bb
begin
	smooth_range = -10:10
	n_ = size(smooth_range)[1]
	kernel = OffsetArray(fill(1/n_, n_), smooth_range)
end;

# ╔═╡ 4ae7323d-be6b-45c8-b16f-52c27968efc8
plot(time[2:end], diff(imfilter(dist, kernel)) * u"1/s", title="Smoothed with uniform kernel", ylabel="velocity")

# ╔═╡ c4054e36-b8a9-4743-8b36-bba84f29ec1b
velocity_gauss = diff(imfilter(dist, KernelFactors.gaussian(3))) * u"1/s"

# ╔═╡ faeb3515-b797-4920-b3ff-5672e47b1a51
plot(time[2:end], velocity_gauss, title="Smoothed with gaussian kernel", ylabel="velocity")

# ╔═╡ eb19d479-d778-4f9f-89b7-6825163769aa
acceleration_gauss = diff(imfilter(velocity_gauss, KernelFactors.gaussian(3))) * u"1/s"

# ╔═╡ cfe4a5f3-5d70-467b-9706-bebd17b55305
plot(time[3:end], acceleration_gauss, title="Smoothed with gaussian kernel", ylabel="acceleration")

# ╔═╡ 53699f51-6295-4f3e-8376-0891e4f3afd2
odom = bag["/robotont/odom", time_range]

# ╔═╡ 14101c1e-f328-487b-a8a9-570e54fe7aa9
ox = [(convert(DateTime, o.data.header.time), o.data.twist.twist.linear.y, o.data.pose.pose.position.x) for o = odom]

# ╔═╡ 88f25939-55ba-4c26-9976-7f9e733f6966
odf = DataFrame(NamedTuple{(:time, :vel, :pos)}.(ox))

# ╔═╡ 9dfa7cda-1a14-43bf-9b0e-ca2fe8f0dcac
otime = odf[!, :time] - odf[1, :time]

# ╔═╡ 3c548f42-982c-49f7-9768-5f75771f28a7
plot(otime[1:end], odf[!, :vel])

# ╔═╡ 5f003d0a-f6ae-4bb9-8b8e-a1f7be829385
mean(odf[!,:vel])

# ╔═╡ eb52fa86-4c01-4100-91f4-eb94f4ad15d8
begin
	start = mzs[1,:mpos]
	
	plot(time, mzs[!, :mpos], ticks=:native, label="camera")
	plot!(otime, start .- odf[!, :pos], ticks=:native, label="odom")
end

# ╔═╡ d1929e40-a617-4577-a875-0b7e2f8878e6


# ╔═╡ Cell order:
# ╠═28dec7bc-c846-11eb-2576-0d28a2569db6
# ╠═bcdf3958-9a53-437f-8c0e-529b37e3e833
# ╠═ebbe541a-7ae5-4b18-b079-239bd733c5fb
# ╠═433f3fe3-45c6-43c4-84f1-7b54178ed34a
# ╠═977dbaf0-ed9b-4582-9378-8e1eabd1a1c1
# ╠═10e08ba1-6e48-4d6c-8949-83e0c8ee82e7
# ╠═0df647f5-340f-4b8a-9826-4ee55ea66890
# ╠═c13e43d4-b7d6-4d65-996d-b2568d43b9f4
# ╠═bf83571f-c7f5-45d9-87a9-23c2bcff04fe
# ╠═8f96e1d2-32e4-46d8-998c-7728f4204fda
# ╠═79d2d3ed-d65d-44b2-aa6c-6964785a044a
# ╠═d42aa9df-4991-494e-a30d-24351ede8a0a
# ╠═fa2f217f-0184-4947-b161-191feba95d42
# ╠═accbb017-a1c4-4122-b2ce-7711a946312a
# ╠═02e4c44e-42d7-4064-b522-1384122eee5e
# ╠═854e8a1a-3caa-4661-ba85-d0542f1489bb
# ╠═4ae7323d-be6b-45c8-b16f-52c27968efc8
# ╠═c4054e36-b8a9-4743-8b36-bba84f29ec1b
# ╠═faeb3515-b797-4920-b3ff-5672e47b1a51
# ╠═eb19d479-d778-4f9f-89b7-6825163769aa
# ╠═cfe4a5f3-5d70-467b-9706-bebd17b55305
# ╠═53699f51-6295-4f3e-8376-0891e4f3afd2
# ╠═14101c1e-f328-487b-a8a9-570e54fe7aa9
# ╠═88f25939-55ba-4c26-9976-7f9e733f6966
# ╠═9dfa7cda-1a14-43bf-9b0e-ca2fe8f0dcac
# ╠═3c548f42-982c-49f7-9768-5f75771f28a7
# ╠═5f003d0a-f6ae-4bb9-8b8e-a1f7be829385
# ╠═eb52fa86-4c01-4100-91f4-eb94f4ad15d8
# ╠═d1929e40-a617-4577-a875-0b7e2f8878e6
