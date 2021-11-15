### A Pluto.jl notebook ###
# v0.16.0

using Markdown
using InteractiveUtils

# ╔═╡ 28dec7bc-c846-11eb-2576-0d28a2569db6
begin
	using Pkg
	Pkg.activate(mktempdir())
end

# ╔═╡ bcdf3958-9a53-437f-8c0e-529b37e3e833
begin
	Pkg.add(["Plots", "PlutoUI","StatsBase", "DataStructures", "Unitful", "UnitfulRecipes", "PhysicalConstants", "UnitfulEquivalences", "DataFrames", "CSV", "Dates", "TimeZones", "StatsPlots", "ImageFiltering", "OffsetArrays", "FileIO", "StaticArrays", "FastIOBuffers", "TranscodingStreams", "CodecBzip2", "Tokenize", "DataInterpolations", "GR", "Chain", "RigidBodyDynamics", "Rotations"])
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
	using Chain
	using RigidBodyDynamics
	using Rotations
	TableOfContents(aside=true)
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

# ╔═╡ de3afecc-d891-406b-914f-11c8725f2493
begin
	include("ExtraMessages2.jl")
end

# ╔═╡ b3664899-6b56-4131-a0e3-aa4af4d511a4
md"ExtraMessages has definitions for apriltag msgs"

# ╔═╡ 1ac597a8-c569-4ab9-83a0-448c806b3e89
md"## load data"

# ╔═╡ ebbe541a-7ae5-4b18-b079-239bd733c5fb
bag = load("/home/kris/learning/robotont/bagfiles/bagfiles/new-square-10-tagged.bag", ExtraMessages2)

# ╔═╡ a3730cdc-ad7e-4456-85f9-d963f0fde827
tags = bag["/tag_detections"]

# ╔═╡ 5ccd0f1b-5aa5-44c5-8fb0-8a5790472e31
odom = bag["/robotont/odom"];

# ╔═╡ d82e6569-f507-4374-bf85-56338a6af284
md"## get time and coordinates"

# ╔═╡ 58cb28fd-84c1-4bf2-80dd-ae42dd75f316
oxy = [(convert(DateTime, o.data.header.time), o.data.pose.pose.position, o.data.pose.pose.orientation) for o = odom];

# ╔═╡ 3640759c-ae5d-43b1-8c69-d32f9f79a4c7
doxy = DataFrame(NamedTuple{(:time, :pos, :ori)}.(oxy));

# ╔═╡ 433f3fe3-45c6-43c4-84f1-7b54178ed34a
bag.topic_map

# ╔═╡ 71ffb0e5-4c68-4e40-b8d5-b3819892c837
md"### check if x and y are correctly mapped"

# ╔═╡ fc9de0b3-4972-4cde-adaa-f26d59bb540b
test = convert.(SVector{3}, getproperty.(oxy, 2))

# ╔═╡ 40717ac7-a36c-46f6-a647-018a2cfb980c
tx = [t[1] for t = test]

# ╔═╡ b07516f9-b63d-47d2-82da-efbe533dd26b
ty = [t[2] for t = test]

# ╔═╡ 1cbbafe0-5466-4c3e-8d9e-c6f1332ee0fd
plot(tx, ty)

# ╔═╡ edc82591-dffd-48a2-b497-5dec88db9a5a
md"## extract tags"

# ╔═╡ 2193ceda-3bd0-4de3-b2ad-2c60a227927e
md"## define frames"

# ╔═╡ 91b69545-7aaf-45b6-90b7-c64bf78d64b2
base = CartesianFrame3D("base")

# ╔═╡ 62e2af49-601e-4455-a689-7a5c4a81c950
body = CartesianFrame3D("body")

# ╔═╡ 0361853d-7852-4fe6-a85f-471e2c2b9c34
camera = CartesianFrame3D("camera")

# ╔═╡ 4965214b-4ba5-4f8b-a9d7-67e72c5d62fd
frame_tag0 = CartesianFrame3D("tag0")

# ╔═╡ a651733a-7e7d-4c4e-9832-17549c11ad16
frame_tag9 = CartesianFrame3D("tag9")

# ╔═╡ c0ed5601-be65-41e5-97de-aa4bba084be2
tag_detections = @chain tags begin 
	filter(x -> length(x.data.detections) > 0, _)
	map(x -> x.data.detections[1], _)
	map(_) do x
		if x.id[1] == 0
			tag_frame = frame_tag0
		elseif x.id[1] == 9
			tag_frame = frame_tag9
		end
		time = convert(DateTime, x.pose.header.time)
		quat = convert(UnitQuaternion, x.pose.pose.pose.orientation)
		pos = convert(SVector{3},x.pose.pose.pose.position)
		t = (time, x.id[1], x.size[1], Transform3D(tag_frame, body, quat, pos))
		nt = NamedTuple{(:time, :id, :size, :tf)}(t)
	end
	DataFrame()
	
end

# ╔═╡ af3d8601-0e42-479f-9961-f8f220ebabf9
(tag_detections[1, :tf])

# ╔═╡ fbe186b5-73fe-409d-98d1-c6bf03a592a4
inv(tag_detections[1, :tf])

# ╔═╡ c3ffcb78-1bcd-4008-9824-363aa2e8a0ff
tag_detections[70, :tf]

# ╔═╡ f0931cb7-b884-4878-abbc-3416445018d1
md"## transform transforms"

# ╔═╡ 18efebd3-3a87-4951-ad83-63f99f224bd0
body_movement = [Transform3D(base, body, convert(UnitQuaternion, o[3]), SVector{3}(o[2].x, o[2].y, o[2].z)) for o = oxy]

# ╔═╡ ef7a0975-3720-4438-ba9c-21ee707f3690
begin
	@df tag_detections scatter(:time, [:id])
	@df tag_detections plot!(:time, [:id])
end

# ╔═╡ b005aa32-2c82-41ac-be36-d8b6861e89a1
md"## extract example transforms"

# ╔═╡ 1cc6c448-0761-4694-b604-1686da221085


# ╔═╡ 855f5d1e-5d51-4248-98a3-5e3751b54f57
T = rand(Twist{Float64}, odomf, basef, camera)

# ╔═╡ d4a52be8-fc1f-46e8-b5d4-b32b6d307032
Ṫ = rand(SpatialAcceleration{Float64}, odomf, basef, camera)

# ╔═╡ 7bd64888-6914-4207-adf6-d73b886930b3
p = Point3D(camera, rand(SVector{3}))

# ╔═╡ 5ec2e068-3da1-4240-83d7-87a0975aa9ed
ṗ = point_velocity(T, p)

# ╔═╡ 28428ab1-4e64-4c8d-96ff-1d3e6746aa3a
p̈ = point_acceleration(T, Ṫ, p)

# ╔═╡ b1cfb6a8-a9ed-4b54-909d-a1ae2e4b0420


# ╔═╡ 23ca5cdc-6479-4917-b5cb-b71efce2ffb7
different_tags = unique(tag_ids)

# ╔═╡ d1929e40-a617-4577-a875-0b7e2f8878e6
# RobotOSData.gen_module(:ExtraMessages2, ["/home/kris/learning/docker-ros-realsense/src/apriltag_ros/apriltag_ros"], ".", :(RobotOSData.StdMsgs), :(RobotOSData.CommonMsgs))

# ╔═╡ 2056f5a5-e54e-485a-8bf0-072559a98fc4
md"# util"

# ╔═╡ 74a171b8-0515-4890-b188-55f58a9cb4b9
between(x,y,ϵ=Second(1)) = Nanosecond(0) < y-x < ϵ

# ╔═╡ eaae32ff-01a4-4f3c-a939-29d5e3c70418
function body_transform_near(time::DateTime, tag_trans::Transform3D)
	near_time = map(x -> between(x, time), doxy.time)
	trans_ = doxy[near_time, [:pos, :ori]][1, :]
	
	orientation = convert(UnitQuaternion, trans_.ori)
	pos = convert(SVector{3},trans_.pos)
	
	body_tag_trans = Transform3D(base, body, orientation, pos)
	inv(inv(body_tag_trans) * tag_trans)
end

# ╔═╡ de3feaeb-9f85-4a89-819e-70acea5ab003
tag_transforms = @chain tag_detections begin
	DataFrames.transform([:time, :tf] => ByRow(body_transform_near) => :tf)
	groupby(:id)
	combine(x -> first(x))
	#DataFrames.transform(:tf => 
	# time, transform = tag_detections[_.id .== 0, [:time, :transform]]
end

# ╔═╡ 47e9f660-94ab-4455-913e-6d0481aa31a0
tf1 = tag_transforms[1, :tf]

# ╔═╡ 2ea86b37-c132-4566-b716-92b403bf6601
tf2 = tag_transforms[2, :tf]

# ╔═╡ 248cbf4e-b7ca-4e2d-a296-93ed38676406
point(frame::CartesianFrame3D, point::RobotOSData.CommonMsgs.geometry_msgs.Point) = Point3D(frame, SVector{3}(point.x, point.y, point.z))

# ╔═╡ 029ac539-a36e-4b80-89d3-1f514529c7a2
Base.convert(::Type{SVector{3}}, point::RobotOSData.CommonMsgs.geometry_msgs.Point) = SVector{3}(point.x, point.y, point.z)

# ╔═╡ bebe3472-ff5b-4fc5-b1ef-af8c25a62ba9
Base.convert(::Type{UnitQuaternion}, quat::RobotOSData.CommonMsgs.geometry_msgs.Quaternion) = UnitQuaternion(quat.w, quat.x, quat.y, quat.z)

# ╔═╡ 4f8a20c3-979b-4c0c-89d3-70beda4e2f06


# ╔═╡ d9c1168f-b2d5-4d1d-aef5-5e1c5ad24e18
rotat

# ╔═╡ Cell order:
# ╠═28dec7bc-c846-11eb-2576-0d28a2569db6
# ╠═bcdf3958-9a53-437f-8c0e-529b37e3e833
# ╠═b3664899-6b56-4131-a0e3-aa4af4d511a4
# ╠═de3afecc-d891-406b-914f-11c8725f2493
# ╠═c13e43d4-b7d6-4d65-996d-b2568d43b9f4
# ╟─1ac597a8-c569-4ab9-83a0-448c806b3e89
# ╠═ebbe541a-7ae5-4b18-b079-239bd733c5fb
# ╠═a3730cdc-ad7e-4456-85f9-d963f0fde827
# ╠═5ccd0f1b-5aa5-44c5-8fb0-8a5790472e31
# ╟─d82e6569-f507-4374-bf85-56338a6af284
# ╠═58cb28fd-84c1-4bf2-80dd-ae42dd75f316
# ╠═3640759c-ae5d-43b1-8c69-d32f9f79a4c7
# ╠═433f3fe3-45c6-43c4-84f1-7b54178ed34a
# ╟─71ffb0e5-4c68-4e40-b8d5-b3819892c837
# ╠═fc9de0b3-4972-4cde-adaa-f26d59bb540b
# ╠═40717ac7-a36c-46f6-a647-018a2cfb980c
# ╠═b07516f9-b63d-47d2-82da-efbe533dd26b
# ╠═1cbbafe0-5466-4c3e-8d9e-c6f1332ee0fd
# ╟─edc82591-dffd-48a2-b497-5dec88db9a5a
# ╠═c0ed5601-be65-41e5-97de-aa4bba084be2
# ╠═af3d8601-0e42-479f-9961-f8f220ebabf9
# ╠═fbe186b5-73fe-409d-98d1-c6bf03a592a4
# ╠═c3ffcb78-1bcd-4008-9824-363aa2e8a0ff
# ╟─2193ceda-3bd0-4de3-b2ad-2c60a227927e
# ╟─91b69545-7aaf-45b6-90b7-c64bf78d64b2
# ╟─62e2af49-601e-4455-a689-7a5c4a81c950
# ╟─0361853d-7852-4fe6-a85f-471e2c2b9c34
# ╟─4965214b-4ba5-4f8b-a9d7-67e72c5d62fd
# ╟─a651733a-7e7d-4c4e-9832-17549c11ad16
# ╠═f0931cb7-b884-4878-abbc-3416445018d1
# ╠═18efebd3-3a87-4951-ad83-63f99f224bd0
# ╠═eaae32ff-01a4-4f3c-a939-29d5e3c70418
# ╠═de3feaeb-9f85-4a89-819e-70acea5ab003
# ╠═ef7a0975-3720-4438-ba9c-21ee707f3690
# ╟─b005aa32-2c82-41ac-be36-d8b6861e89a1
# ╠═47e9f660-94ab-4455-913e-6d0481aa31a0
# ╠═2ea86b37-c132-4566-b716-92b403bf6601
# ╠═1cc6c448-0761-4694-b604-1686da221085
# ╠═855f5d1e-5d51-4248-98a3-5e3751b54f57
# ╠═d4a52be8-fc1f-46e8-b5d4-b32b6d307032
# ╠═7bd64888-6914-4207-adf6-d73b886930b3
# ╠═5ec2e068-3da1-4240-83d7-87a0975aa9ed
# ╠═28428ab1-4e64-4c8d-96ff-1d3e6746aa3a
# ╠═b1cfb6a8-a9ed-4b54-909d-a1ae2e4b0420
# ╠═23ca5cdc-6479-4917-b5cb-b71efce2ffb7
# ╠═d1929e40-a617-4577-a875-0b7e2f8878e6
# ╟─2056f5a5-e54e-485a-8bf0-072559a98fc4
# ╠═74a171b8-0515-4890-b188-55f58a9cb4b9
# ╠═248cbf4e-b7ca-4e2d-a296-93ed38676406
# ╠═029ac539-a36e-4b80-89d3-1f514529c7a2
# ╠═bebe3472-ff5b-4fc5-b1ef-af8c25a62ba9
# ╠═4f8a20c3-979b-4c0c-89d3-70beda4e2f06
# ╠═d9c1168f-b2d5-4d1d-aef5-5e1c5ad24e18
