### A Pluto.jl notebook ###
# v0.19.5

#> [frontmatter]
#> title = "Thesis defence"
#> date = "2022-06-07"

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

# ╔═╡ 79c24db8-1b26-4ee3-ab05-b54dfe23f31a
# ╠═╡ show_logs = false
begin
	using Pkg
	Pkg.activate(mktempdir())
end

# ╔═╡ fe541191-aeaa-4a59-9943-314f0e8dc923
# ╠═╡ show_logs = false
begin
	Pkg.add(["Plots", "PlutoUI","StatsBase", "DataStructures", "Unitful", "UnitfulRecipes", "PhysicalConstants", "UnitfulEquivalences", "DataFrames", "CSV", "Dates", "TimeZones", "StatsPlots", "ImageFiltering", "OffsetArrays", "FileIO", "StaticArrays", "FastIOBuffers", "TranscodingStreams", "CodecBzip2", "Tokenize", "DataInterpolations", "GR", "Chain", "RigidBodyDynamics", "Rotations", "Plotly", "HypertextLiteral", "PlutoHooks", "Animations", "ProgressLogging"])
	Pkg.develop(["RobotOSData"])
end

# ╔═╡ b0006767-f9e2-4711-af2a-e839dd1d47d4
begin
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
	using HypertextLiteral
	using PlutoHooks
	using Animations
	using ProgressLogging
end

# ╔═╡ 295d90d6-cfda-457b-86e5-cb4213187528
html"<button onclick='present()'>present</button>"

# ╔═╡ 1bfe89ca-f8c8-4375-84d8-c6b500be45e7
# TableOfContents()

# ╔═╡ 1e2a1eae-4e93-44d8-887a-181b3bf65a6c
md"""
# Introduction
### Robot localization

##### finding one's position relative to a map or environment
* allows for moving **inside** an environment
* allows for interacting **with** an environment
"""

# ╔═╡ 335ac1cc-57c6-43b5-828d-18dec17e11e2
md"# 1. Motivation"

# ╔═╡ 190b29b3-939c-4bd0-8d81-39c7ddae868a
md"""
# 2. Design

"""

# ╔═╡ 15173f9c-6b1a-4961-a8c2-439ac7d43dc1
# md"""
# ## 2.3 environment  
# 
# ### 1 - proof of concept
# 
# ### 2 - corridor with corner
# 
# """

# ╔═╡ 80b4e6ab-8827-4191-83ce-bb3ff964b547
# myvideo = Video(500,500)

# ╔═╡ 42b8bae1-73c0-4beb-afa2-35d5e1073f85


# ╔═╡ b3c8cd24-3b97-4d1c-a42a-f0d075a63bb3
md"""
# 4. Conclusion
### Things that fell short of a robust abstraction
- Marker ambiguity (orientation)
- unscented or extended Kalman filters and irregular data rates didn't work well
- robot camera overheats in Estonian summers
- physical connections acting up
- wireless connections not configured
- firmware bugs
- ROS environment, packages, messaging, message recording, GUIs, 
"""

# ╔═╡ ce934b4e-0203-44b2-a15c-017cf3909536
md"""# Thank you"""

# ╔═╡ c46efa0f-c52c-43f9-8c56-06f1f74b3cc2
yanu_robot_ok = html"""
<iframe width="400" height="710" src="https://www.youtube.com/embed/EdVhLYA9Mr0?start=102" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
"""

# ╔═╡ 8043cbaf-cae1-49f6-b37d-fc10a3ea7b8c
md"""## Yanu robot 

$yanu_robot_ok
"""

# ╔═╡ 8b9199a9-08c6-4b5c-804e-b3273be28334


# ╔═╡ 8aa41d32-66a3-4d79-8382-95d8679778e1
# @bind ticks Clock(0, true)

# ╔═╡ 51d51e16-c0f7-4c88-99c9-62c77946bdfd
ticks = 0

# ╔═╡ c9270623-ca58-4df0-8b61-3f1da2dd4920
md"manual test selector: $(@bind bag_id Slider(1:20))"

# ╔═╡ 60f312ee-ca6d-425d-9197-705856e49528
sw1 = let
    PlutoUI.LocalResource(joinpath(split(@__FILE__, '#')[1] * ".assets", "image9.png"))
end

# ╔═╡ c7e43924-4e0d-4641-ad96-1f81467e5819
e1_path = let
    PlutoUI.LocalResource(joinpath(split(@__FILE__, '#')[1] * ".assets", "PXL_20210611_100925899_annotated.jpg"))
end;

# ╔═╡ 9f7a76f3-b46f-4c42-95ac-7a59d2d8fd1a
sw2 = let
    PlutoUI.LocalResource(joinpath(split(@__FILE__, '#')[1] * ".assets", "image11.png"))
end

# ╔═╡ 9e621e8f-16cd-4a35-9923-f4ce900bd1fc
sw3 = let
    PlutoUI.LocalResource(joinpath(split(@__FILE__, '#')[1] * ".assets", "image15.png"))
end

# ╔═╡ e44d2685-c67b-413a-85bc-07ed0e3a3f3e
sw4 = let
    PlutoUI.LocalResource(joinpath(split(@__FILE__, '#')[1] * ".assets", "image26.png"))
end

# ╔═╡ 95c439b3-3124-485f-8210-a08966fb7d63
markers = let
    PlutoUI.LocalResource(joinpath(split(@__FILE__, '#')[1] * ".assets", "pasted image 0.png"))
end;

# ╔═╡ 95900352-9f84-43bf-a03d-6aad56af8989
e1_floor = let
    PlutoUI.LocalResource(joinpath(split(@__FILE__, '#')[1] * ".assets", "PXL_20210611_100934475.jpg"))
end;

# ╔═╡ 26c1826a-ffe7-48f6-adab-2b7689c3d8e7
e2_path = let
    PlutoUI.LocalResource(joinpath(split(@__FILE__, '#')[1] * ".assets", "PXL_20220505_194745774_path.jpg"))
end;

# ╔═╡ b4eda53d-8f89-4247-a16f-5056ba77b931
e2_floor = let
    PlutoUI.LocalResource(joinpath(split(@__FILE__, '#')[1] * ".assets", "PXL_20220503_015801418.jpg"))
end;

# ╔═╡ d0c0522b-7cf7-4c7f-8b8d-97bc401c9cc6
sw_all = let
    PlutoUI.LocalResource(joinpath(split(@__FILE__, '#')[1] * ".assets", "nodes seperately software overview(5).png"))
end;

# ╔═╡ 7aa21d46-0ed1-4975-b20f-ba370db91fdf
md"""
## 2.2 software overview

$sw_all

"""

# ╔═╡ b5e722c4-1544-44e2-853e-cd6b9335a9ad
square_gif = let
    PlutoUI.LocalResource(joinpath(split(@__FILE__, '#')[1] * ".assets", "square.gif"))
end;

# ╔═╡ fed1524a-20bd-4b12-b486-e2c8613ba2ba
square_gif

# ╔═╡ a3e469c1-06ac-4f4b-b28c-7b85311da665
industrial_robot_yt = html"""
<iframe width="700" height="410" src="https://www.youtube.com/embed/7-4yOx1CnXE?start=81&mute=1&VQ=HD1080" title="industrial_robot_yt" frameborder="0" allow="encrypted-media;" allowfullscreen></iframe>
""";

# ╔═╡ a73e192f-dbdf-40d1-9fed-12ec290d4642
yanu_robot_spin = html"""
<iframe width="700" height="410" src="https://www.youtube.com/embed/o4dRAG_Nits?mute=1" title="yanu_robot_spin" frameborder="0" allow="encrypted-media;" allowfullscreen></iframe>
""";

# ╔═╡ b2cec10f-50dd-4059-bf4c-fe4c4bde3386
cubebot = html"""
<iframe width="700" height="410" src="https://www.youtube.com/embed/KVEfdyW6Zm4?start=22535&mute=1" title="Cube-O-Bot" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
""";

# ╔═╡ 7e9a09f1-af7b-4d8e-815a-44d48161a4eb
md"""
## 1.1 General purpose robotics ...

... will be as big an innovation as general purpose computers

### but there are problems

$yanu_robot_spin

#### and specifically when a robot fails to map it's environment

$cubebot
The goal here was for the robot to pick up a ball and throw it into the tube on the other side of the field. Notice how the non-gray non-cube robot manages to do that pretty well, but even when the cube-robot finds the ball, and goes to pick it up, it still quickly forgets it and gets confused. The cube robot wasn't mapping it's environment.

### but also notice how there are some robots humanity can make do useful work

$industrial_robot_yt

That is done by removing any possible difference in the environment between one run and the next. Everything will always be in the same place, the robots are always doing the same fixed movement. All the humans are kept out with prejudice. 

---
My work adds some static known quantities (that robots love!) to the dynamic environment humans like to live and work in. All in the name of building a **more robust abstraction**. 
"""

# ╔═╡ 8fafd12c-8c98-45ed-86c4-58c091b5b56b
begin
	struct Foldable{C}
	    title::String
	    content::C
	end
	
	function Base.show(io, mime::MIME"text/html", fld::Foldable)
	    write(io,"<details><summary>$(fld.title)</summary><p>")
	    show(io, mime, fld.content)
	    write(io,"</p></details>")
	end
end

# ╔═╡ 94e8bbd9-2de0-41d1-b019-14eb57765a0f
begin
	struct TwoColumn{L, R}
	    left::L
	    right::R
	end
	
	function Base.show(io, mime::MIME"text/html", tc::TwoColumn)
	    write(io, """<div style="display: flex; justify-content: space-between;"><div style="flex: 50%; margin: 0 0.6em;">""")
	    show(io, mime, tc.left)
	    write(io, """</div><div style="flex: 50%;">""")
	    show(io, mime, tc.right)
	    write(io, """</div></div>""")
	end
end

# ╔═╡ a527c863-ccb6-4f8c-ba38-7d53821632ee
md"""
## 2.1 markers

$(TwoColumn(
md"
BLACK border $br
binary matrix inside $br
4x4 marker == 16 bits of data 
> but since Error Correcting Codes (ECC) are used
> (to work better in low visibility situations)
> there's less bits to actually work with
", markers))
"""

# ╔═╡ 9ebd369b-12f4-46fb-a764-284424871c23
md"""
## 3.2 Experiment 2 - corner corridor

$(TwoColumn(e2_path, e2_floor))

- somewhat more complicated. 
- laps through the corridor, taking the corner, rotating back. 
- increased errors from: bumpy floor, sometimes moving sideways. 
- many more markers. they were regularly placed every 30 cm. (to ease saving their locations in a map and creating the ground truth)

"""

# ╔═╡ 34bc4e7c-55da-4c17-9c2d-f4b711a58328
TwoColumn(md"robot error estimate through time. for position (x,y) and orientation (yew).", md"wheeled and marker position estimates combined. markers in red circles, combined esimate as the blue line")

# ╔═╡ 55fb1168-67ba-49fa-aebb-b6e14a6b3623
SlideNextPrev() = @htl("""
<script id="first">

	var editor = document.querySelector("pluto-editor")
	var prev = document.querySelector("button.changeslide.prev")
	var next = document.querySelector("button.changeslide.next")
	
	const click_background = (e => {
		// debugger;
		if (editor != e.target) return;
		e.preventDefault();		
		console.log(e.button);
		if (e.button === 2 && prev) {
			prev.click();
		} else if (e.button === 0 && next) {
			next.click();
		} 
	})
	editor.addEventListener("click", click_background)
	editor.addEventListener("contextmenu", click_background)

	invalidation.then(() => { 
		editor.removeEventListener("click", click_background);
		editor.removeEventListener("contextmenu", click_background);
	})
	
	return true;
</script>
""")

# ╔═╡ 47558b43-8b33-43ad-a6a8-a46ec176622f
@bind slide SlideNextPrev()

# ╔═╡ 18650c56-ad18-4a78-996f-c1ad05333016


# ╔═╡ 668b0182-9370-45ce-9abb-5b3036a51942
# data loading

# ╔═╡ 0801f6be-1206-4a7a-965c-dfad6b542d82
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

# ╔═╡ b47057a7-bc59-4e1a-8142-71fcd8a212be
corridorbags = [load("/home/kris/learning/robotont/bagfiles/$filename") for filename in corridor2filenames]

# ╔═╡ 7e1594ee-cfbd-468c-ab0b-de30c45c0c31
bag = corridorbags[mod1(bag_id + ticks, end)]

# ╔═╡ 79775b8c-7cc6-4c66-9952-d194a1b6f34b
mod1(bag_id + ticks, )

# ╔═╡ 9a0ea3a4-20cf-426c-b45b-76e74f18741e
bag_id

# ╔═╡ 62fac23f-74d5-4ca6-a8a9-50b64fda88b4
length(corridorbags)

# ╔═╡ 81ef373e-c3cc-4995-9485-f727b59deeb6
tags = bag["/tag_detections"]

# ╔═╡ 83bf6f64-1a0d-460c-b8be-70e9645907cc
odom = bag["/robotont/odom"];

# ╔═╡ 37329ee2-9afc-4836-8df7-c16b65f5a687
ekf_odom = bag["/ekf_map"]

# ╔═╡ 270d4871-be3c-4727-8a66-3c58025caedd
oxy = [(o.data.pose.pose.position, o.data.pose.pose.orientation) for o = odom];

# ╔═╡ 09e983b3-d805-4869-83f2-c56f94038033


# ╔═╡ 90d3b3e4-664a-4080-859e-fe8d008ddba7
ekf_cov = @chain ekf_odom begin
	map(_) do m
		m.data.pose.covariance
	end
	map(_) do cov
		[cov[1] cov[8] cov[36]]
	end
	vcat(_...)
end

# ╔═╡ 03ef9161-a074-435a-b25a-d76bd7c208ac
experiment2_true = 

# ╔═╡ 5c104533-72e0-4d51-82f4-16e74e9dec09
@bind mouse MouseMoveInput()

# ╔═╡ b90a8505-a305-4eb4-b660-9a8b6a8c0097
mouse

# ╔═╡ 9882df47-486d-4a91-8e12-eb0b4c6a2e12
"""
    title(title::String, subtitle::String, author::String, supervisor::String, affiliation::String) :: HypertextLiteral.Result    
    
Makes the title for the report. Must be the last statement in a cell.
"""
function title(title::String, subtitle::String, author::String, supervisor::String, affiliation::String)::HypertextLiteral.Result
	name(str) = @htl """<p style="text-align: right; font-size: 20px; font-variant: small-caps; margin: 0px">$(str)</p>"""
	
    @htl """
        <h1 style="text-align:center">$(title)</h1>
        <div style="text-align:center">
		<p style="font-weight:bold; font-size: 35px; font-variant: small-caps; margin: 0px">$(subtitle)</p>
	
		$(name(author))
		$(name(supervisor))
		<br/>
		<br/>
		<br/>
        <p style="font-size: 20px;">$(affiliation)</p>
        </div>
    """
end

# ╔═╡ 6045e555-fa50-4351-895a-650126689d38
title("Robot Localization with Fiducial Markers", "Bachelor’s Thesis", "Kristjan Laht", "Supervisor: Karl Kruusamäe PhD", "Institute of Computer Science, UNIVERSITY OF TARTU")

# ╔═╡ 70c9b47c-bb9f-4a8b-8a1c-c79a8d0b4317
title("Robot Localization with Fiducial Markers", "Bachelor’s Thesis", "Kristjan Laht", "Supervisor: Karl Kruusamäe PhD", "Institute of Computer Science, UNIVERSITY OF TARTU")

# ╔═╡ 6aa4a550-2014-472e-af81-614fd1cc1fcf
e1_res = let
    PlutoUI.LocalResource(joinpath(split(@__FILE__, '#')[1] * ".assets", "Screenshot from 2021-08-27 05-27-46_units.png"))
end

# ╔═╡ 57ba46db-ea4a-4173-b521-32031b31fea8
md"""
# 3. Results
## 3.1 Experiment 1 - proof of concept

$(TwoColumn(e1_path, e1_floor))

- simple, smooth floor
- robot only does right turns. 
- robot path in depicted in blue. the marker that helps localize is yellow  

$e1_res
$(TwoColumn(md"Robot position by combining wheel and marker data. The position estimate stays consistent throughtout the test.", md"Robot position from only wheel data. By the last lap, the orientation has drifted away from the true value."))

"""

# ╔═╡ efc5a138-784d-4e43-a6a0-fe0e96af1807
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

# ╔═╡ 8fbbc2bd-8043-41aa-a954-4b45c45f9f74
begin
	using RobotOSData
	EM = ingredients("ExtraMessages2.jl")
	import .EM: ExtraMessages2
end

# ╔═╡ 9eccfe54-d6c4-4efb-bf8f-d5099b1ea8ca
Base.convert(::Type{SVector{3}}, point::RobotOSData.CommonMsgs.geometry_msgs.Point) = SVector{3}(point.x, point.y, point.z)

# ╔═╡ f3c6f734-465a-4455-a3b9-05ba5e4a9b6d
Base.convert(::Type{UnitQuaternion}, quat::RobotOSData.CommonMsgs.geometry_msgs.Quaternion) = UnitQuaternion(quat.w, quat.x, quat.y, quat.z)

# ╔═╡ 39540fe6-bc57-4884-ba93-f10fee95e2d1
opos = convert.(SVector{3}, getproperty.(oxy, 1))

# ╔═╡ 022c16b8-07d8-4b7c-82be-dcdff68a2e62
ox = [t[1] for t = opos]

# ╔═╡ 562a030d-49a5-4aab-8461-ffd9ba61b9fa
oy = [t[2] for t = opos]

# ╔═╡ 88c6c780-78d4-461d-b221-9ae145d3caaa
odom_plot = let
	p = plot(ox, oy, label="robot path from wheel recordings", xlabel="x [m]", ylabel="y [m]", xlims=(-10, 10), ylims=(-5,15), dpi = 500)

	@withprogress begin
		imaginary_y = [0., 10., 10., 10., -1.]
		imaginary_x = [0., 0., 2., 0., 0.]
		ts = 0:0.2:20
		anim_y = Animations.Animation([0, 5, 10, 15, 20], imaginary_y, sineio())
		anim_x = Animations.Animation([0, 5, 10, 15, 20], imaginary_x, sineio())
		anim_ys = anim_y.(ts)
		anim_xs = anim_x.(ts)
		
		anim = Plots.Animation()
		
		for i in eachindex(anim_ys)
			
			cur_plot = plot!(deepcopy(p), anim_xs[1:i], anim_ys[1:i], label="imagined perfect path", linewidth=3)
			scatter!(cur_plot, [anim_xs[i]], [anim_ys[i]], label="robot")
			
			frame(anim)
			@logprogress i / length(anim_ys)
		end
		gif(anim, fps=60)
	end
end

# ╔═╡ 184960da-b10a-410d-a3be-f81a2e2856ed
odom_plot

# ╔═╡ 9f12408d-ba31-41c1-b02e-f6ed251cea0e
axes_settings = (xlims=(-10, 10), ylims=(-5,15), size=(300, 300), dpi=500)

# ╔═╡ a3c8d8c7-621e-45da-8fa7-0888739d7bf5
function plot_var(bag)
	@chain bag["/ekf_map"] begin
		map(_) do m
			m.data.pose.covariance
		end
		map(_) do cov
			[cov[1] cov[8] cov[36]]
		end
		vcat(_...)
		plot(_, labels=["x variance" "y variance" "yew variance"], ylabel = "variance [m²]", size=(300, 300), dpi=400, xlabel = "time [s]" )
	end
end

# ╔═╡ 1b9e245a-1bca-4ce1-a216-9995ec33199b
cov_plot = plot_var(bag)

# ╔═╡ 387ae053-ccbf-484a-affa-81c6c33efdd4
# ╠═╡ show_logs = false
cov_plot_gif = let 
	animation = @animate for selected_bag in corridorbags
		plot_var(selected_bag)
	end
	gif(animation, fps=0.3)
end

# ╔═╡ 0e793370-6279-4d75-bc59-c2f55a0b5c8b
unzip(a) = (getfield.(a, x) for x in fieldnames(eltype(a)))

# ╔═╡ f99322e2-6580-4dfc-ae15-fa2ab2c01176
function plot_ekf(bag)
	pose_time = @chain bag["/ar_pose"] begin
		map(_) do ps 
			ps
			covs = ps.data.pose.covariance
			var = covs[1] + covs[8] + covs[15] + covs[36]
			time = convert(DateTime, ps.time)
			time
		end
	end
	
	exy = [(convert(DateTime, o.data.header.time), o.data.pose.pose.position, o.data.pose.pose.orientation) for o = bag["/ekf_map"]];
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
	
	plot(px, py, label="EKF path", xlabel="x [m]", ylabel="y [m]", xlims=(-10, 10), ylims=(-5,15), size=(300, 300), dpi=500)
	scatter!(dotsx, dotsy, label="markers", legend=:topleft, opacity=0.5)
end

# ╔═╡ ff5405a0-4571-4144-b061-daa4cc0c8605
ekf_plot = plot_ekf(bag)

# ╔═╡ ddb13306-fe97-4211-8de7-454e42bdf211
# ╠═╡ show_logs = false
ekf_plot_gif = let 
	animation = @animate for selected_bag in corridorbags
		plot_ekf(selected_bag)
	end
	gif(animation, fps=0.3)
end

# ╔═╡ 02625467-9007-4304-88b3-ef54e3a638e5
TwoColumn(cov_plot_gif, ekf_plot_gif)

# ╔═╡ a5141fe8-5abe-4d19-ac57-df60891f00d5


# ╔═╡ Cell order:
# ╟─79c24db8-1b26-4ee3-ab05-b54dfe23f31a
# ╟─fe541191-aeaa-4a59-9943-314f0e8dc923
# ╟─b0006767-f9e2-4711-af2a-e839dd1d47d4
# ╟─295d90d6-cfda-457b-86e5-cb4213187528
# ╟─1bfe89ca-f8c8-4375-84d8-c6b500be45e7
# ╟─6045e555-fa50-4351-895a-650126689d38
# ╟─1e2a1eae-4e93-44d8-887a-181b3bf65a6c
# ╟─335ac1cc-57c6-43b5-828d-18dec17e11e2
# ╟─7e9a09f1-af7b-4d8e-815a-44d48161a4eb
# ╟─190b29b3-939c-4bd0-8d81-39c7ddae868a
# ╟─a527c863-ccb6-4f8c-ba38-7d53821632ee
# ╟─7aa21d46-0ed1-4975-b20f-ba370db91fdf
# ╟─15173f9c-6b1a-4961-a8c2-439ac7d43dc1
# ╟─57ba46db-ea4a-4173-b521-32031b31fea8
# ╟─fed1524a-20bd-4b12-b486-e2c8613ba2ba
# ╟─9ebd369b-12f4-46fb-a764-284424871c23
# ╟─184960da-b10a-410d-a3be-f81a2e2856ed
# ╟─02625467-9007-4304-88b3-ef54e3a638e5
# ╟─34bc4e7c-55da-4c17-9c2d-f4b711a58328
# ╟─80b4e6ab-8827-4191-83ce-bb3ff964b547
# ╟─42b8bae1-73c0-4beb-afa2-35d5e1073f85
# ╟─b3c8cd24-3b97-4d1c-a42a-f0d075a63bb3
# ╟─ce934b4e-0203-44b2-a15c-017cf3909536
# ╟─8043cbaf-cae1-49f6-b37d-fc10a3ea7b8c
# ╠═c46efa0f-c52c-43f9-8c56-06f1f74b3cc2
# ╠═8b9199a9-08c6-4b5c-804e-b3273be28334
# ╠═8aa41d32-66a3-4d79-8382-95d8679778e1
# ╠═51d51e16-c0f7-4c88-99c9-62c77946bdfd
# ╠═c9270623-ca58-4df0-8b61-3f1da2dd4920
# ╠═60f312ee-ca6d-425d-9197-705856e49528
# ╠═c7e43924-4e0d-4641-ad96-1f81467e5819
# ╠═9f7a76f3-b46f-4c42-95ac-7a59d2d8fd1a
# ╠═9e621e8f-16cd-4a35-9923-f4ce900bd1fc
# ╠═e44d2685-c67b-413a-85bc-07ed0e3a3f3e
# ╠═95c439b3-3124-485f-8210-a08966fb7d63
# ╠═95900352-9f84-43bf-a03d-6aad56af8989
# ╠═26c1826a-ffe7-48f6-adab-2b7689c3d8e7
# ╠═b4eda53d-8f89-4247-a16f-5056ba77b931
# ╠═d0c0522b-7cf7-4c7f-8b8d-97bc401c9cc6
# ╠═b5e722c4-1544-44e2-853e-cd6b9335a9ad
# ╠═a3e469c1-06ac-4f4b-b28c-7b85311da665
# ╠═a73e192f-dbdf-40d1-9fed-12ec290d4642
# ╠═b2cec10f-50dd-4059-bf4c-fe4c4bde3386
# ╠═8fafd12c-8c98-45ed-86c4-58c091b5b56b
# ╠═94e8bbd9-2de0-41d1-b019-14eb57765a0f
# ╠═55fb1168-67ba-49fa-aebb-b6e14a6b3623
# ╠═47558b43-8b33-43ad-a6a8-a46ec176622f
# ╠═18650c56-ad18-4a78-996f-c1ad05333016
# ╠═668b0182-9370-45ce-9abb-5b3036a51942
# ╠═8fbbc2bd-8043-41aa-a954-4b45c45f9f74
# ╠═0801f6be-1206-4a7a-965c-dfad6b542d82
# ╠═b47057a7-bc59-4e1a-8142-71fcd8a212be
# ╠═7e1594ee-cfbd-468c-ab0b-de30c45c0c31
# ╠═79775b8c-7cc6-4c66-9952-d194a1b6f34b
# ╠═9a0ea3a4-20cf-426c-b45b-76e74f18741e
# ╠═62fac23f-74d5-4ca6-a8a9-50b64fda88b4
# ╠═81ef373e-c3cc-4995-9485-f727b59deeb6
# ╠═83bf6f64-1a0d-460c-b8be-70e9645907cc
# ╠═37329ee2-9afc-4836-8df7-c16b65f5a687
# ╠═270d4871-be3c-4727-8a66-3c58025caedd
# ╠═39540fe6-bc57-4884-ba93-f10fee95e2d1
# ╠═022c16b8-07d8-4b7c-82be-dcdff68a2e62
# ╠═562a030d-49a5-4aab-8461-ffd9ba61b9fa
# ╠═88c6c780-78d4-461d-b221-9ae145d3caaa
# ╠═09e983b3-d805-4869-83f2-c56f94038033
# ╠═ff5405a0-4571-4144-b061-daa4cc0c8605
# ╠═90d3b3e4-664a-4080-859e-fe8d008ddba7
# ╠═1b9e245a-1bca-4ce1-a216-9995ec33199b
# ╠═387ae053-ccbf-484a-affa-81c6c33efdd4
# ╠═ddb13306-fe97-4211-8de7-454e42bdf211
# ╠═03ef9161-a074-435a-b25a-d76bd7c208ac
# ╠═5c104533-72e0-4d51-82f4-16e74e9dec09
# ╠═b90a8505-a305-4eb4-b660-9a8b6a8c0097
# ╠═9882df47-486d-4a91-8e12-eb0b4c6a2e12
# ╠═70c9b47c-bb9f-4a8b-8a1c-c79a8d0b4317
# ╠═6aa4a550-2014-472e-af81-614fd1cc1fcf
# ╠═9eccfe54-d6c4-4efb-bf8f-d5099b1ea8ca
# ╠═f3c6f734-465a-4455-a3b9-05ba5e4a9b6d
# ╠═efc5a138-784d-4e43-a6a0-fe0e96af1807
# ╠═f99322e2-6580-4dfc-ae15-fa2ab2c01176
# ╠═9f12408d-ba31-41c1-b02e-f6ed251cea0e
# ╠═a3c8d8c7-621e-45da-8fa7-0888739d7bf5
# ╠═0e793370-6279-4d75-bc59-c2f55a0b5c8b
# ╠═a5141fe8-5abe-4d19-ac57-df60891f00d5
