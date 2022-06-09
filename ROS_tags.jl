### A Pluto.jl notebook ###
# v0.17.3

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

# ╔═╡ 28dec7bc-c846-11eb-2576-0d28a2569db6
begin
	using Pkg
	Pkg.activate(mktempdir())
end

# ╔═╡ bcdf3958-9a53-437f-8c0e-529b37e3e833
begin
	Pkg.add(["Plots", "PlutoUI","StatsBase", "DataStructures", "Unitful", "UnitfulRecipes", "PhysicalConstants", "UnitfulEquivalences", "DataFrames", "CSV", "Dates", "TimeZones", "StatsPlots", "ImageFiltering", "OffsetArrays", "FileIO", "StaticArrays", "FastIOBuffers", "TranscodingStreams", "CodecBzip2", "Tokenize", "DataInterpolations", "GR", "Chain", "RigidBodyDynamics", "Rotations", "Plotly", "Javis", "JavisNB", "Animations"])
	Pkg.develop(["RobotOSData"])

	using Plots
	gr()
	#plotly()
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
	using FileIO
	using StaticArrays
	using DataInterpolations
	using Chain
	using RigidBodyDynamics
	using Rotations
	using Base.Iterators: flatten
	using LinearAlgebra
	using Javis, JavisNB
	using Animations
	TableOfContents(aside=true)
end

# ╔═╡ b3664899-6b56-4131-a0e3-aa4af4d511a4
md"ExtraMessages has definitions for apriltag msgs"

# ╔═╡ 1ac597a8-c569-4ab9-83a0-448c806b3e89
md"## load data"

# ╔═╡ ebbe541a-7ae5-4b18-b079-239bd733c5fb
# bag = load("/home/kris/learning/robotont/bagfiles/new_square10_ukf.bag", ExtraMessages2)

# ╔═╡ b02b8ac7-bc32-4b90-8427-33b0e1896da6
corridor2filenames = [
"corridor2_ekf_10.bag",
"corridor2_ekf_11.bag",
"corridor2_ekf_12.bag",
"corridor2_ekf_13.bag",
"corridor2_ekf_14.bag",
"corridor2_ekf_15.bag",
"corridor2_ekf_16.bag",
"corridor2_ekf_17.bag",
"corridor2_ekf_18.bag",
"corridor2_ekf_19.bag",
"corridor2_ekf_20.bag",
"corridor2_ekf_2.bag",
"corridor2_ekf_3.bag",
"corridor2_ekf_4.bag",
"corridor2_ekf_5.bag",
"corridor2_ekf_6.bag",
"corridor2_ekf_7.bag",
"corridor2_ekf_8.bag",
"corridor2_ekf_9.bag",
"corridor2_ekf.bag",
]

# ╔═╡ d5e79a7e-c9e7-4709-9af8-2e3059c16398
corridorbags = [load("/home/kris/learning/robotont/bagfiles/$filename") for filename in corridor2filenames]

# ╔═╡ d82e6569-f507-4374-bf85-56338a6af284
md"## get time and coordinates"

# ╔═╡ 71ffb0e5-4c68-4e40-b8d5-b3819892c837
md"### check if x and y are correctly mapped"

# ╔═╡ 6531448b-cacb-4fcb-a05e-6851aae14f43
@bind bag_id Slider(1:20)

# ╔═╡ 39193c89-ebb4-4dde-91cc-948cc5847e1b
bag = corridorbags[bag_id]

# ╔═╡ a3730cdc-ad7e-4456-85f9-d963f0fde827
tags = bag["/tag_detections"]

# ╔═╡ 5ccd0f1b-5aa5-44c5-8fb0-8a5790472e31
odom = bag["/robotont/odom"];

# ╔═╡ 6d8377d9-c027-49cd-beca-22501f19a1e0
ekf_odom = bag["/ekf_map"]

# ╔═╡ 433f3fe3-45c6-43c4-84f1-7b54178ed34a
bag.topic_map

# ╔═╡ d0a4fa3c-602d-48e8-9c74-320a466cb975
md"## animate"

# ╔═╡ edc82591-dffd-48a2-b497-5dec88db9a5a
md"## extract tags"

# ╔═╡ b622cff0-9cd5-4cbe-b360-0633d858adc9
dts = tags[1].data.detections

# ╔═╡ 7aec20b5-a768-48bc-a488-f7433ba056bb
dts[1].id[1]

# ╔═╡ 0574a966-28ea-44f5-b802-8e69b74c579a
ids = [detection.id[1] for tag in tags for detection in tag.data.detections]

# ╔═╡ 56aa41ab-35a1-4706-9203-c5ebf70084d9
countmap(ids)

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

# ╔═╡ 6ee93ec4-0260-4109-a348-3fed2c2606a6
frame_tag5 = CartesianFrame3D("tag5")

# ╔═╡ f0931cb7-b884-4878-abbc-3416445018d1
md"## transform transforms"

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


# ╔═╡ d1929e40-a617-4577-a875-0b7e2f8878e6
# RobotOSData.gen_module(:ExtraMessages2, ["/home/kris/learning/docker-ros-realsense/src/apriltag_ros/apriltag_ros"], ".", :(RobotOSData.StdMsgs), :(RobotOSData.CommonMsgs))

# ╔═╡ 00f370f0-a154-4224-b70c-d7ca9d6f41b5
ys = 0:0.3:10 |> collect

# ╔═╡ 9121ff6b-8f6c-458f-bf2f-6d2521a0f960
9*0.3 + 3.44

# ╔═╡ 2056f5a5-e54e-485a-8bf0-072559a98fc4
md"# util"

# ╔═╡ 74a171b8-0515-4890-b188-55f58a9cb4b9
between(x,y,ϵ=Second(1)) = Nanosecond(0) < y-x < ϵ

# ╔═╡ 4f8a20c3-979b-4c0c-89d3-70beda4e2f06
function ingredients(path::String)
	# this is from the Julia source code (evalfile in base/loading.jl)
	# but with the modification that it returns the module instead of the last object
	name = Symbol(basename(path))
	m = Module(name)
	Core.eval(m,
        Expr(:toplevel,
             :(eval(x) = $(Expr(:core, :eval))($name, x)),
             :(include(x) = $(Expr(:top, :include))($name, x)),
             :(include(mapexpr::Function, x) = $(Expr(:top, :include))(mapexpr, $name, x)),
             :(include($path))))
	m
end

# ╔═╡ de3afecc-d891-406b-914f-11c8725f2493
begin
	using RobotOSData
	EM = ingredients("ExtraMessages2.jl")
	import .EM: ExtraMessages2
end

# ╔═╡ bfa73724-abc4-43b4-bb3e-fa022e6fe908
tag_bag = load("/home/kris/robot-backup2/2022-05-05-11-36-02.bag", ExtraMessages2)

# ╔═╡ b3b8c057-a117-4963-8294-cb984ae5308e
ds = tag_bag["/tag_detections"]

# ╔═╡ 248cbf4e-b7ca-4e2d-a296-93ed38676406
point(frame::CartesianFrame3D, point::RobotOSData.CommonMsgs.geometry_msgs.Point) = Point3D(frame, SVector{3}(point.x, point.y, point.z))

# ╔═╡ 029ac539-a36e-4b80-89d3-1f514529c7a2
Base.convert(::Type{SVector{3}}, point::RobotOSData.CommonMsgs.geometry_msgs.Point) = SVector{3}(point.x, point.y, point.z)

# ╔═╡ bebe3472-ff5b-4fc5-b1ef-af8c25a62ba9
Base.convert(::Type{UnitQuaternion}, quat::RobotOSData.CommonMsgs.geometry_msgs.Quaternion) = UnitQuaternion(quat.w, quat.x, quat.y, quat.z)

# ╔═╡ 58cb28fd-84c1-4bf2-80dd-ae42dd75f316
oxy = [(convert(DateTime, o.data.header.time), o.data.pose.pose.position, o.data.pose.pose.orientation) for o = odom];

# ╔═╡ 3640759c-ae5d-43b1-8c69-d32f9f79a4c7
doxy = DataFrame(NamedTuple{(:time, :pos, :ori)}.(oxy));

# ╔═╡ fc9de0b3-4972-4cde-adaa-f26d59bb540b
test = convert.(SVector{3}, getproperty.(oxy, 2))

# ╔═╡ 40717ac7-a36c-46f6-a647-018a2cfb980c
tx = [t[1] for t = test]

# ╔═╡ 963e5e1c-d16c-47ca-9ac1-717f6c8de2f4
maximum(tx)

# ╔═╡ b07516f9-b63d-47d2-82da-efbe533dd26b
ty = [t[2] for t = test]

# ╔═╡ 1cbbafe0-5466-4c3e-8d9e-c6f1332ee0fd
plot(tx, ty, label="robot wheel path", xlabel="x [m]", ylabel="y [m]")

# ╔═╡ 6e32e9b6-07ef-45e2-aa6f-c5285602df1c
begin
	function ground(args...)
	    background("white")
	    sethue("black")
	end
	
	function circle_with_color(pos, radius, color)
	    sethue(color)
	    circle(pos, radius, :fill)
	end
	readpng()
	
	# the safest option is to declare the Video first all the time
	video = Video(800, 600)

	points = [Point(round(Int, t[1]*15), round(Int, t[2]*15)) for t in test]
	npoints = length(points)
	
	Background(1:1000, ground)
	
	# # generate the bezier path
	# bezierpath = makebezierpath(points)
	# bezierpathpoly = bezierpathtopoly(bezierpath)
	
	# # let the bezier path appear and disappear in the end
	#bezier_object = Object( (args...) -> drawbezierpath(bezierpath, :stroke))
	
	# let a red circle appear and follow the bezier path polygon
	red_circle = Object(20:970, (args...) -> circle_with_color(first(points), 10, "red"))
	act!(red_circle, Action(1:20, appear(:fade)))
	act!(red_circle, Action(21:970, sineio(), follow_path(points .- first(points))))
	act!(red_circle, Action(971:980, disappear(:fade)))
	
	embed(video; pathname="test.gif")
end

# ╔═╡ a8c29f90-855a-4e60-964e-5b67c1f4c027
test[17]*100

# ╔═╡ 2dc04f51-772b-4c53-992b-c5333da6a432
test[15][2]

# ╔═╡ c0ed5601-be65-41e5-97de-aa4bba084be2
tag_detections = @chain tags begin 
	filter(x -> length(x.data.detections) > 0, _)
	flatten(map(_) do tag
		ds = tag.data.detections
		# filter(d -> d.id[1] == 5, ds) 
	end)
	map(_) do x
		# if x.id[1] == 5
		# 	tag_frame = frame_tag5
		# end
		time = convert(DateTime, x.pose.header.time)
		quat = convert(UnitQuaternion, x.pose.pose.pose.orientation)
		pos = convert(SVector{3},x.pose.pose.pose.position)
		id = x.id[1]
		size = x.size[1]
		#t = (time, x.id[1], x.size[1], Transform3D(tag_frame, body, quat, pos))
		t =  (;time, id, size, body, quat, pos)
		t
	end
end

# ╔═╡ 44b217ff-ba79-4958-b3cb-631c2998e80c
tag_detections

# ╔═╡ 5224bd6d-84d6-424a-b4e1-b537c41846ed
tag_times = map(tag_detections) do ds ds.time end

# ╔═╡ c92ddf35-feb8-44b2-9bd4-c4ccd755c474
length(tag_times)

# ╔═╡ a40d6f5a-4786-4668-a5e9-7ff3fbef0b01
tag_times

# ╔═╡ 4481f712-5db5-4fbe-bc2e-0c191ec71636
tag_ids = map(tag_detections) do ds ds.id end |> unique

# ╔═╡ af3d8601-0e42-479f-9961-f8f220ebabf9
(tag_detections[1, :tf])

# ╔═╡ fbe186b5-73fe-409d-98d1-c6bf03a592a4
inv(tag_detections[1, :tf])

# ╔═╡ c3ffcb78-1bcd-4008-9824-363aa2e8a0ff
tag_detections[70, :tf]

# ╔═╡ ef7a0975-3720-4438-ba9c-21ee707f3690
begin
	@df tag_detections scatter(:time, [:id])
	@df tag_detections plot!(:time, [:id])
end

# ╔═╡ 23ca5cdc-6479-4917-b5cb-b71efce2ffb7
different_tags = @chain tag_detections begin
	map(_) do td td.id end
	unique(_)
end

# ╔═╡ 7235a12e-7e31-4a1e-aa59-cf8d1557e97f
pose_time = @chain bag["/ar_pose"] begin
	map(_) do ps 
		ps
		covs = ps.data.pose.covariance
		var = covs[1] + covs[8] + covs[15] + covs[36]
		time = convert(DateTime, ps.time)
		time
	end
end

# ╔═╡ d337c9eb-56d1-4750-a058-8b62812dfac8
pose_cov = @chain bag["/ekf_map"] begin
	map(_) do ps 
		ps
		covs = ps.data.pose.covariance
		var = covs[1] + covs[8] + covs[15] + covs[36]
		time = convert(DateTime, ps.time)
		(;time, var)
	end
end

# ╔═╡ 18efebd3-3a87-4951-ad83-63f99f224bd0
body_movement = [Transform3D(base, body, convert(UnitQuaternion, o[3]), SVector{3}(o[2].x, o[2].y, o[2].z)) for o = oxy]

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

# ╔═╡ 4ac3049e-56f9-4ddf-b46e-58128f7cefa6
with_terminal() do 
	@chain ds begin
		map(_) do d d.data.detections end
		filter(!isempty, _)
		map(_) do t
			id = t[1].id[1]
			pos = convert(SVector{3},t[1].pose.pose.pose.position)
			(;id,pos)
		end
		unique(_) do t t.id end
		map(zip(_, _[2:end])) do (t1, t2)
			t1.id# , norm(t1.pos - t2.pos)
		end
		map(zip(_[10:end], ys)) do (id, y)
			println("$id: pq_to_se3(np.array([-0.1, $(round(-2.26 + y, digits=3)), 0.12]), np.array([1., 0., 0., 0.])),")
		end
	end
end

# ╔═╡ ce55d232-5550-4626-afba-84bb23453457
unzip(a) = (getfield.(a, x) for x in fieldnames(eltype(a)))

# ╔═╡ dbe861b9-2498-47c1-9e44-0f6123b1bcc2
begin
	exy = [(convert(DateTime, o.data.header.time), o.data.pose.pose.position, o.data.pose.pose.orientation) for o = ekf_odom];
	exyz = convert.(SVector{3}, getproperty.(exy, 2))

	dots = Vector{NTuple{2, Float64}}()
	#dot_texts = Vector{String}()
	
	tagtimes = pose_time
	odomtimes = getproperty.(exy, 1)
	
	local next_tag = 1
	local next_odom = 1
	while next_tag <= length(tagtimes) && next_odom <= length(odomtimes)
		tagtime = tagtimes[next_tag]
		odomtime = odomtimes[next_odom]
		
		if (tagtime - odomtime).value > 100
			next_odom += 1
		else
			push!(dots, (exyz[next_odom][1], exyz[next_odom][2]))
			# push!(dot_texts, string(tagtimes[next_tag].id))
			next_tag += 1
		end
	end

	dotsx, dotsy = unzip(dots)
	px, py = unzip(getproperty.(exyz, :data))
	
	plot(px, py, label="EKF path", xlabel="x [m]", ylabel="y [m]")
	scatter!(dotsx, dotsy, label="markers", legend=:topleft, opacity=0.5)
end

# ╔═╡ 319b52bd-dc9b-4295-ab15-1d774b587cf8
dots

# ╔═╡ 34abd545-9bc6-4cbb-9bd3-cb799c5768e7
function plot_ekf(ekf_odom)
	exy = [(convert(DateTime, o.data.header.time), o.data.pose.pose.position, o.data.pose.pose.orientation) for o = ekf_odom];
	exyz = convert.(SVector{3}, getproperty.(exy, 2))

	dots = Vector{NTuple{2, Float64}}()
	#dot_texts = Vector{String}()
	
	tagtimes = pose_time
	odomtimes = getproperty.(exy, 1)
	
	local next_tag = 1
	local next_odom = 1
	while next_tag <= length(tagtimes) && next_odom <= length(odomtimes)
		tagtime = tagtimes[next_tag]
		odomtime = odomtimes[next_odom]
		
		if (tagtime - odomtime).value > 100
			next_odom += 1
		else
			push!(dots, (exyz[next_odom][1], exyz[next_odom][2]))
			# push!(dot_texts, string(tagtimes[next_tag].id))
			next_tag += 1
		end
	end

	dotsx, dotsy = unzip(dots)
	px, py = unzip(getproperty.(exyz, :data))
	
	plot(px, py, label="EKF path", xlabel="x [m]", ylabel="y [m]")
	scatter!(dotsx, dotsy, label="markers", legend=:topleft, opacity=0.5)
end
	

# ╔═╡ d9c1168f-b2d5-4d1d-aef5-5e1c5ad24e18
rotat

# ╔═╡ Cell order:
# ╠═28dec7bc-c846-11eb-2576-0d28a2569db6
# ╠═bcdf3958-9a53-437f-8c0e-529b37e3e833
# ╠═b3664899-6b56-4131-a0e3-aa4af4d511a4
# ╠═de3afecc-d891-406b-914f-11c8725f2493
# ╟─1ac597a8-c569-4ab9-83a0-448c806b3e89
# ╠═ebbe541a-7ae5-4b18-b079-239bd733c5fb
# ╠═b02b8ac7-bc32-4b90-8427-33b0e1896da6
# ╠═d5e79a7e-c9e7-4709-9af8-2e3059c16398
# ╠═bfa73724-abc4-43b4-bb3e-fa022e6fe908
# ╠═39193c89-ebb4-4dde-91cc-948cc5847e1b
# ╠═a3730cdc-ad7e-4456-85f9-d963f0fde827
# ╠═5ccd0f1b-5aa5-44c5-8fb0-8a5790472e31
# ╠═6d8377d9-c027-49cd-beca-22501f19a1e0
# ╟─d82e6569-f507-4374-bf85-56338a6af284
# ╠═58cb28fd-84c1-4bf2-80dd-ae42dd75f316
# ╠═3640759c-ae5d-43b1-8c69-d32f9f79a4c7
# ╠═433f3fe3-45c6-43c4-84f1-7b54178ed34a
# ╟─71ffb0e5-4c68-4e40-b8d5-b3819892c837
# ╠═fc9de0b3-4972-4cde-adaa-f26d59bb540b
# ╠═963e5e1c-d16c-47ca-9ac1-717f6c8de2f4
# ╠═40717ac7-a36c-46f6-a647-018a2cfb980c
# ╠═b07516f9-b63d-47d2-82da-efbe533dd26b
# ╠═6531448b-cacb-4fcb-a05e-6851aae14f43
# ╠═1cbbafe0-5466-4c3e-8d9e-c6f1332ee0fd
# ╠═dbe861b9-2498-47c1-9e44-0f6123b1bcc2
# ╠═34abd545-9bc6-4cbb-9bd3-cb799c5768e7
# ╠═c92ddf35-feb8-44b2-9bd4-c4ccd755c474
# ╠═a40d6f5a-4786-4668-a5e9-7ff3fbef0b01
# ╠═319b52bd-dc9b-4295-ab15-1d774b587cf8
# ╠═d0a4fa3c-602d-48e8-9c74-320a466cb975
# ╠═6e32e9b6-07ef-45e2-aa6f-c5285602df1c
# ╠═a8c29f90-855a-4e60-964e-5b67c1f4c027
# ╠═2dc04f51-772b-4c53-992b-c5333da6a432
# ╟─edc82591-dffd-48a2-b497-5dec88db9a5a
# ╠═b622cff0-9cd5-4cbe-b360-0633d858adc9
# ╠═7aec20b5-a768-48bc-a488-f7433ba056bb
# ╠═0574a966-28ea-44f5-b802-8e69b74c579a
# ╠═56aa41ab-35a1-4706-9203-c5ebf70084d9
# ╠═c0ed5601-be65-41e5-97de-aa4bba084be2
# ╠═7235a12e-7e31-4a1e-aa59-cf8d1557e97f
# ╠═d337c9eb-56d1-4750-a058-8b62812dfac8
# ╠═44b217ff-ba79-4958-b3cb-631c2998e80c
# ╠═5224bd6d-84d6-424a-b4e1-b537c41846ed
# ╠═4481f712-5db5-4fbe-bc2e-0c191ec71636
# ╠═af3d8601-0e42-479f-9961-f8f220ebabf9
# ╠═fbe186b5-73fe-409d-98d1-c6bf03a592a4
# ╠═c3ffcb78-1bcd-4008-9824-363aa2e8a0ff
# ╟─2193ceda-3bd0-4de3-b2ad-2c60a227927e
# ╟─91b69545-7aaf-45b6-90b7-c64bf78d64b2
# ╟─62e2af49-601e-4455-a689-7a5c4a81c950
# ╟─0361853d-7852-4fe6-a85f-471e2c2b9c34
# ╟─4965214b-4ba5-4f8b-a9d7-67e72c5d62fd
# ╠═a651733a-7e7d-4c4e-9832-17549c11ad16
# ╠═6ee93ec4-0260-4109-a348-3fed2c2606a6
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
# ╠═00f370f0-a154-4224-b70c-d7ca9d6f41b5
# ╠═b3b8c057-a117-4963-8294-cb984ae5308e
# ╠═4ac3049e-56f9-4ddf-b46e-58128f7cefa6
# ╠═9121ff6b-8f6c-458f-bf2f-6d2521a0f960
# ╟─2056f5a5-e54e-485a-8bf0-072559a98fc4
# ╠═74a171b8-0515-4890-b188-55f58a9cb4b9
# ╠═248cbf4e-b7ca-4e2d-a296-93ed38676406
# ╠═029ac539-a36e-4b80-89d3-1f514529c7a2
# ╠═bebe3472-ff5b-4fc5-b1ef-af8c25a62ba9
# ╠═4f8a20c3-979b-4c0c-89d3-70beda4e2f06
# ╠═ce55d232-5550-4626-afba-84bb23453457
# ╠═d9c1168f-b2d5-4d1d-aef5-5e1c5ad24e18
