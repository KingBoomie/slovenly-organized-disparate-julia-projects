### A Pluto.jl notebook ###
# v0.14.1

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
	Pkg.activate(mktempdir())
end

# ╔═╡ d8b334ae-4108-11eb-2546-99e75efc18d6
begin
	Pkg.add(["Plots", "PlutoUI","StatsBase", "DataStructures", "Unitful", "PhysicalConstants", "UnitfulEquivalences", "DataFrames", "CSV", "Dates", "TimeZones", "StatsPlots", "ImageFiltering", "OffsetArrays"])

	using Plots
	plotly()
	using PlutoUI
	using StatsBase
	using DataStructures
	using Unitful
	using PhysicalConstants.CODATA2018: c_0, h, ħ
	using UnitfulEquivalences
	using DataFrames
	using CSV
	using TimeZones
	using Dates
	using StatsPlots
	using ImageFiltering
	using OffsetArrays
end

# ╔═╡ e6b122ce-5548-11eb-3980-53dfd8e5897c
begin
	frmt = dateformat"yyyy-mm-dd HH:MM:SS"
	column_types = Dict(:ResultTime=>DateTime, :AnalysisInsertTime=>DateTime)
	df = CSV.read("/home/kris/Downloads/opendata_covid19_test_results.csv", DataFrame, types=column_types, dateformat=frmt)
	dropmissing!(df)
end

# ╔═╡ eaab22ca-5b2c-11eb-1eb6-cf73054ee98e
begin
	inimarv_raw = CSV.read("/home/kris/Downloads/RV0222U_20012021163956877.csv", DataFrame)
	inimarv = Dict(eachrow(inimarv_raw[!, [:Maakond, :Value]]));
end

# ╔═╡ 6fcdea12-35f3-4648-8ba0-cfd6e89547ef
counties = collect(setdiff(keys(inimarv), ["..Tallinn", "..Tartu linn", "Maakond teadmata"]))

# ╔═╡ 2a795f4a-6bca-11eb-2b3f-b385b41d4759
@bind selectedCounty MultiSelect(counties)

# ╔═╡ ed6d5c68-5b1f-11eb-134b-57fcc502469c
selected_df = filter(x -> x[:County] ∈ selectedCounty, df);

# ╔═╡ 2c31d1ca-5b20-11eb-1f1b-db947a36b2c6
selected_df_p = filter(x -> x[:ResultValue] == "P", selected_df);

# ╔═╡ fc91c29a-6bca-11eb-1cd7-132e515bcc53
all = combine(groupby(selected_df_p, [:StatisticsDate, :County]), nrow => :count);

# ╔═╡ 7b2f2674-5b22-11eb-225c-cbd01d9b1058
begin
	smooth_range = -7:0
	n = size(smooth_range)[1]
	kernel = OffsetArray(fill(1/n, n), smooth_range)
end;

# ╔═╡ baf09934-5b20-11eb-3283-d9b7bdfb5a90
allSelected = transform(combine(groupby(selected_df_p, [:StatisticsDate]), nrow => :count), (arr -> imfilter(arr[!, :count], kernel)));

# ╔═╡ dc1fdc56-6bcd-11eb-32c7-f3515450573c
dates = allSelected[!, :StatisticsDate];

# ╔═╡ f9b7501b-abb7-4998-bf5a-787cba8355d6
@df allSelected plot(:StatisticsDate, [:count, :x1], ticks=:native, legend=:topleft)

# ╔═╡ 74295a2c-6bc9-11eb-1474-9befdff2e2bf
next = transform( groupby(all, [:County]), (arr -> imfilter(arr[!, :count], kernel) / inimarv[arr[1,:County]] * 10000))

# ╔═╡ 080ecf02-5549-11eb-06cd-b10c7ed4e1e4
groups = groupby(df, [:ResultValue]);

# ╔═╡ 0f8d9246-6bd2-11eb-3c89-7dcd26ee5f0e
tartu_p = filter(x -> x[:County] ∈ selectedCounty && x[:ResultValue] == "P" , df);

# ╔═╡ 742c4eaa-7fe5-11eb-37e5-b96d6d7d86cd
@df next plot(:StatisticsDate, [:x1], group=:County, title="New infections per 10000", legend=:topleft)

# ╔═╡ d49f6f5e-5cb5-11eb-14e1-45d31ab53e89
function week_multi(week_p)
	week_multiplier = zeros(size(week_p)[1])
	for i = 2:size(week_p)[1]
		prev = week_p[i-1, :count_in_week]
		current = week_p[i, :count_in_week]
		week_multiplier[i] = current/prev
	end
	week_multiplier
end;

# ╔═╡ d212b59e-810d-11eb-3b97-5dd770b3c949
function multi_smooth(next) # Not used, but it's a nice function and I spent time on it, so it should stay for now
	weeks = reshape(next[1:size(next, 1)÷7*7], 7, :)
	sums = sum(weeks, dims=1)
	res = map(zip(sums[:], sums[2:end])) do (prev, cur)
		cur/prev
	end
	prepend!(res, 1)
	append!(res, 1)
	repeat(res, inner=7)[1:size(next,1)]
end;

# ╔═╡ ef39fc56-554b-11eb-3082-77349ed217d4
counts = combine(groups, nrow => :count)

# ╔═╡ c85e156e-554a-11eb-218b-df5eabe2d8ab
@df counts bar(:ResultValue, :count)

# ╔═╡ 5123d73c-6c9b-11eb-0231-675c2b98d0d3
yearweek(date) = (year(date) - 2020)*52 + dayofyear(date) ÷ 7

# ╔═╡ 15f92d78-5b26-11eb-0050-27f2434d1f75
week_p = combine(groupby(transform(tartu_p, :StatisticsDate => ByRow(x -> yearweek(x)) => :week), [:week, :County]), nrow => :count_in_week);

# ╔═╡ dcba4866-5b26-11eb-3e27-8fc9dd4bae77
@df week_p plot(:week, [:count_in_week], group=:County, title="New infections in week")

# ╔═╡ 1889b0c6-6c97-11eb-1577-3ba3e8940484
transform!(groupby(week_p, [:County]), week_multi);

# ╔═╡ d7a78b2e-5cb7-11eb-1967-1b3dc0a388bd
begin
	@df week_p plot(:week, [:x1], group=:County, title="New infections multiplier in county", )
	hline!([1])
end

# ╔═╡ 446f8889-a549-4fd2-b3e4-c09af9961405
no_county = transform(combine(groupby(week_p, [:week]), :count_in_week => sum => :count_in_week), week_multi);

# ╔═╡ 65004f86-3c67-43a6-bb01-16df98e58148
begin
	begin
		@df no_county plot(:week, [:x1], title="Combined new infections multiplier")
		hline!([1])
	end
end

# ╔═╡ 6eccfc72-cf1f-4259-942d-5898c83f4df7
no_county

# ╔═╡ 15499246-5cb6-11eb-2683-d34604bf5914
size(no_county)

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
df[!, :population] = inimarv.. df[!, :County];

# ╔═╡ dd2bc6ca-5a87-11eb-1cfd-9bbf310b48fa
md"""
# Functions in physics
1. In the figure below you see a graph of some function. It is a square function.
"""

# ╔═╡ 9b1d7a9a-5a8b-11eb-3721-510c5ee70087
md"""
### 2. Physical example

This function could be the function of velocity with regards to time with a constant _jerk_. 

$$v(t) = \frac{jt^2}{2} + a_0t + v_0$$
$$1 \frac{m}{s} = \frac{1 \frac{m}{s^3} \cdot (1 s)^2}{2} + 1 \frac{m}{s^2} \cdot 1s + 1 \frac{m}{s}$$

* _$v$_ velocity - it's the first deriative of position, showing the change of change of postion. 
* __$v_0$__ starting velocity
* __$a_0$__ starting acceleration. acceleration is the first deriative of velocity and the second deriative of position. 
* __$j$__ jerk - the third deriative of position. constantly changing velocity. 
* __$t$__ time 
"""

# ╔═╡ 15a2336e-5a91-11eb-3f7b-a3e55c5a3be4
md"""
### 3. Integral

$$v(t) = \frac{jt^2}{2} + a_0t + v_0$$
$$ds = v\ dt =  \left( \frac{jt^2}{2} + a_0t + v_0 \right) dt$$
$$\int_{s_0}^s ds = \int_0^t \left( \frac{jt^2}{2} + a_0t + v_0 \right) dt$$
$$\int_{s_0}^s ds = \int_0^t \left( \frac{jt^2}{2} + a_0t + v_0 \right) dt$$
$$s-s_0 = \frac{jt^3}{6} + \frac{a_0t^2}{2} + v_0t $$
$$s = \frac{jt^3}{6} + \frac{a_0t^2}{2} + v_0t + s_0$$

I chose to derive this integral with the limits of $(s_0, s)$ to get the positional displacement in familiar terms. (where $s_0$ is the starting positional displacement and $s$ is the final displacement)

The integral of the constant jerk velocity function with regards to time is the positional displacement physical quantity. 
"""

# ╔═╡ 935814f4-5a91-11eb-2dc7-a9db013f9d95
md"""

### 4. Property of Nature

The square function describes the concept of compound growth. How even a linearly changing variable, when summed up over time, changes polynominally. This can happen when measuring speed and the jerk increases linearly. 

"""

# ╔═╡ 02b9ba5c-5a8b-11eb-39b1-0d23e4c12f0b
square(a,x,c) = a*x^2 + x

# ╔═╡ 4d0b47b8-5a88-11eb-094a-1d816b3d3a9b
x = 0:1:50

# ╔═╡ d78890c6-5a88-11eb-3601-13e50420b603
@bind j_ Slider(0:10, show_value=true)

# ╔═╡ e7510d12-5a88-11eb-0536-8de677458800
@bind a_0 Slider(-50:50, show_value=true)

# ╔═╡ ee2ef6ca-5a89-11eb-0b85-0d59759a8bac
@bind s_0 Slider(-500:500, show_value=true)

# ╔═╡ de09158c-5a89-11eb-23d3-adc6acc42782
@bind v_0 Slider(-200:200, show_value=true)

# ╔═╡ 5b8a2d9a-5a88-11eb-1193-998aca8aa0a0
jitter(j, a_0, v_0, s_0, t) = j*t^3 / 6 + a_0*t^2/2 + v_0*t + s_0

# ╔═╡ b0a9669c-5a88-11eb-34ee-cd73f0892f7f
jitter(j,t) = jitter(j, 0, 0, 0, t)

# ╔═╡ b2ddbdf0-5a88-11eb-3dba-03b51da9048e
s = jitter.(j_,a_0, v_0, s_0, x)

# ╔═╡ 84c21a6c-4109-11eb-166e-151c460d28c8
md"""
## E2.1.1

In region AB car covered the distance of 25 m, in region BC the distance of 15 m and in CD the distance of 20 m. The acceleration of the car in the region AB was 2.5 m/s2, in the region BC 0 m/s2 and in the region CD -5 m/s2. During the whole trip the car was affected by the drag force of 2 kN. Motor's traction force in region AB was 7 kN
; in region BC 8) Answer
2 kN


. In region CD driver hit the brakes. Braking affected the car with the force of 9) Answer
10 kN


. The work done by motor in the region AB was 10) Answer
14 kJ


, in the region BC 11) Answer
2 kJ


. In the end of the region AB motor reached the power of 12) Answer
7 kW


 and in the region BC the power of 13) Answer
2 kW


. 
"""

# ╔═╡ 50b8ef74-5591-11eb-26bf-9feb4bba0ca3
v_A = 10u"m/s"

# ╔═╡ 7b147c4e-559f-11eb-37ce-075bf3998087
v_B = 15u"m/s"

# ╔═╡ f690e870-5591-11eb-0a58-6faf52de3fec
t_AB = 1u"s"

# ╔═╡ 57c9516e-5591-11eb-226e-f163d5df253d
v_C = 15u"m/s"

# ╔═╡ 070ea700-5592-11eb-1334-abb3cb13262a
t_BC = 2u"s"

# ╔═╡ 5def440c-5591-11eb-05b9-0dfd6d2952c8
v_D = 5u"m/s"

# ╔═╡ 18c7119e-5592-11eb-1afb-e71d7e7b9ca8
t_CD = 2u"s"

# ╔═╡ b29c4136-55a1-11eb-0f19-85789ee1a471


# ╔═╡ 7f1987a6-55a1-11eb-2e64-631c13345a8f


# ╔═╡ ed11f462-55a0-11eb-364b-6b9fd7282d48


# ╔═╡ 3d797c44-55a0-11eb-2490-d98ffcf5f006
drag = 6u"kN"

# ╔═╡ 61e0edf6-55a0-11eb-0d43-69315ade5c2e
mass = 4000u"kg"

# ╔═╡ 71d73800-55a0-11eb-28aa-895ff4f0a36b
force(a) = uconvert(u"kN", mass*a + drag)

# ╔═╡ a76941d0-559f-11eb-2412-bbdefbbfeb04
distance(v1, v2, t) = (v1 + v2) / 2 * t

# ╔═╡ 6edc69c2-5591-11eb-0b05-b35d24abe8aa
s_AB = distance(v_A, v_B, t_AB)

# ╔═╡ c135bbca-559f-11eb-21d0-81f51845afcb
s_BC = distance(v_B, v_C, t_BC)

# ╔═╡ ec9ee372-559f-11eb-3e88-3f4a9cd4c0ec
s_CD = distance(v_C, v_D, t_CD)

# ╔═╡ fe32a588-559f-11eb-25c8-25c3fdb3fb3f
acc(v1, v2, t) = (v2-v1) / t

# ╔═╡ 3ad405cc-55a0-11eb-169a-43cfdaa2d3af
a_AB = acc(v_A, v_B, t_AB)

# ╔═╡ 3be46f9c-55a0-11eb-1e67-f9c641ab7eaf
f_AB = force(a_AB)

# ╔═╡ 42b15790-55a0-11eb-0a84-a79553b87993
a_BC = acc(v_B, v_C, t_BC)

# ╔═╡ cc0c493c-55a0-11eb-37ee-dff68db5868b
f_BC = force(a_BC)

# ╔═╡ 1f54ed0c-55a0-11eb-14bd-01ed4f5743e7
a_CD = acc(v_C, v_D, t_CD)

# ╔═╡ ecfdecf4-55a0-11eb-0427-d9eacdea896c
f_CD = force(a_CD)

# ╔═╡ 045ab740-55a1-11eb-0751-a59eb196863e
work(f, s) = uconvert(u"kJ", f*s)

# ╔═╡ c98e09ac-55a0-11eb-29d3-b12c978f1e57
w_AB = work(f_AB, s_AB)

# ╔═╡ cc6a6710-55a0-11eb-1da6-45a6bb3bb173
w_BC = work(f_BC, s_BC)

# ╔═╡ 962f7d2e-55a1-11eb-3299-215a5c9504c5
power(w, t) = uconvert(u"kW", w/t)

# ╔═╡ 3198fbb0-55a1-11eb-016e-712a7d8f07f1
p_AB = power(w_AB, t_AB)

# ╔═╡ 74fa7748-410c-11eb-0688-a37608618c96
md"""
## E2


"""

# ╔═╡ fdae38fe-410c-11eb-18dd-9bae51fb4e00
t2 = 14u"s"

# ╔═╡ fdbe0894-410c-11eb-0ace-3d269b2942aa
grav = 10u"m/s^2"

# ╔═╡ 220ec448-410d-11eb-17c3-d1682a1588c9
v_2 = grav *t2

# ╔═╡ 4b4e5710-55a3-11eb-2f5d-3df5543e480c
x2 = 0u"s":0.5u"s":30u"s"

# ╔═╡ 5a8d3296-55a3-11eb-3d1c-65245f677262
vs2 = map(x -> v_2 - x*grav, x2)

# ╔═╡ 75ef05aa-55a3-11eb-1c89-fd0fb600608f
plot(ustrip(x2),ustrip(vs2))

# ╔═╡ 22b3b39e-55a4-11eb-3d8e-a18fe4e18872
hs2 = cumsum(vs2 .* 0.5u"s")

# ╔═╡ 6e1b79c0-55a4-11eb-2d3f-296762a8604f
plot(ustrip(x2),ustrip(hs2))

# ╔═╡ 7c3d0eb0-55a4-11eb-3ed0-81c97785c7f0
maximum(ustrip(hs2))

# ╔═╡ 7f1fb2fe-55a4-11eb-1b91-3bd39c4872fe


# ╔═╡ 3bb15c6c-410d-11eb-1b1b-4b13708ceb70
md"""
## E3


"""

# ╔═╡ 0f68fa64-55a5-11eb-24ed-fd2b3fc9ed68
v_e = v_0 + ((a_0 + a_1) / 2)*t3

# ╔═╡ 528ef22e-55a5-11eb-2b03-3d92a4b9c3c6
j = 0.5u"m/s^3"

# ╔═╡ 3de00658-55a5-11eb-102e-3103b223001d
s_e = j*t3^3 / 6 + a_0*t3^2/2 + v_0*t3

# ╔═╡ c094cb3a-4117-11eb-168a-df762ad5739e
md"""
## E4


"""

# ╔═╡ a837ef5c-55a5-11eb-06f5-cb27048bc9a4
t4 = 3u"s"

# ╔═╡ c5cecd9e-55a5-11eb-343a-a3c29893be1f
d4 = 0.4u"s^-1"

# ╔═╡ cff2f4c4-55a5-11eb-32c2-1db64f8ea677
one = d4^-1

# ╔═╡ 74480530-55a6-11eb-0a7b-8b30ed458234
two = d4 * t4

# ╔═╡ b0f10e8e-55a6-11eb-34a1-755dceb63e08
thr = 1.44 * one

# ╔═╡ ef0bdbcc-55a6-11eb-114f-7d43ab25736a


# ╔═╡ 7fec90b4-411b-11eb-04db-a913940a9f22
md"""
## E5

The time counting is started when a mass-spring oscillator passes the equilibrium state. The oscillator stops at the distance of 5 cm from equilibrium state. The system makes one oscillation during time interval of 1.57 seconds. The  amplitude of the oscillator is 1) 


5.00 cm

, oscillation period is 2) 


1.57 s

 and angular frequency is 3)


4.00 rad/s

. The maximal value of acceleration is 4) 


80.00 cm/s2

. Assume that at the start of clock, the deviation is increasing in the positive direction. In this case, the pendulum will reach its maximum negative acceleration 5) 


0.39

 seconds after the clock started. At this moment, pendulum will pass the phase angle of 6)


1.57

 radians. The pendulum will reach its maximum positive acceleration 7)


1.18

 seconds after the clock started. At this moment, pendulum will pass the phase angle of 8)


4.71

 radians. The maximal value of velocity is 9) 


20.00 cm/s

. The oscillator will reach the maximum negative velocity 10) 


0.78

 seconds after the clock started. At this moment, the oscillator will pass the phase angle of 11) 


3.14

 radians.

[NB: give answers with precision of 2 characters after dot]
[NB: case insensitive!]

"""

# ╔═╡ 46652b7e-4122-11eb-1576-29e34caf1b03
d = 4u"cm"

# ╔═╡ 78e0e354-4122-11eb-1a11-0b1d36a38b70
T = 3.14u"s"

# ╔═╡ 46798970-4122-11eb-31a8-ab967162b1ae
ω = 2*pi / T

# ╔═╡ 451edba2-4122-11eb-0ea9-b3e5a7021bd1
md"""
# E5

The time counting is started when a mass-spring oscillator passes the equilibrium state. The oscillator stops at the distance of 5 cm from equilibrium state. The system makes one oscillation during time interval of 1.57 seconds. The  amplitude of the oscillator is 1) 


$d

, oscillation period is 2) 


$T

 and angular frequency is 3)


$ω rad/s

. The maximal value of acceleration is 4) 


80.00 cm/s2

. Assume that at the start of clock, the deviation is increasing in the positive direction. In this case, the pendulum will reach its maximum negative acceleration 5) 


0.39

 seconds after the clock started. At this moment, pendulum will pass the phase angle of 6)


1.57

 radians. The pendulum will reach its maximum positive acceleration 7)


1.18

 seconds after the clock started. At this moment, pendulum will pass the phase angle of 8)


4.71

 radians. The maximal value of velocity is 9) 


20.00 cm/s

. The oscillator will reach the maximum negative velocity 10) 


0.78

 seconds after the clock started. At this moment, the oscillator will pass the phase angle of 11) 


3.14

 radians.

"""

# ╔═╡ 20c55224-55a7-11eb-2490-010a8c63cd4b
v5 = ω*d/2

# ╔═╡ aa066c66-4126-11eb-1909-713aeda74edc
speed6 = 314u"m/s"

# ╔═╡ c4375a50-4126-11eb-2667-7b693682e9a8
freq6 = 125u"Hz"

# ╔═╡ aa323b5c-4126-11eb-18fa-a5aa100d0678
period6 = uconvert(u"ms", 1/freq6)

# ╔═╡ aa487444-4126-11eb-306c-1d98f391cfc6
wavelength6 = uconvert(u"cm", speed6*period6)

# ╔═╡ aa708326-4126-11eb-2129-df2f5666aa93
wave_n = uconvert(u"m^-1", 2*pi/wavelength6)

# ╔═╡ c98691d4-4125-11eb-3e71-d1ffa4fc0f3a
md"""
## E6

Sound plane wave propagates in the cold air with the speed of 314 m/s and frequency 500 Hz. Sound wave oscillation period is 1) 
 $period6
 ms, wavelength 2) 


$wavelength6

 cm and wave number is 3) 


$wave_n

 m-1.  At the start of time counting, the deviation of the sound wave source was minimal (-A). After 3.5 ms from the start and at the distance of 15.7 cm from the wave source the deviation is 4)


maximal

(maximal or A, minimal or –A or zero)."

"""

# ╔═╡ Cell order:
# ╠═bb6cae46-4108-11eb-2309-3d11f13a19fa
# ╠═d8b334ae-4108-11eb-2546-99e75efc18d6
# ╠═e6b122ce-5548-11eb-3980-53dfd8e5897c
# ╠═eaab22ca-5b2c-11eb-1eb6-cf73054ee98e
# ╠═9e3c3714-5b2d-11eb-2a50-413ab7ed65d1
# ╠═6fcdea12-35f3-4648-8ba0-cfd6e89547ef
# ╠═2a795f4a-6bca-11eb-2b3f-b385b41d4759
# ╠═ed6d5c68-5b1f-11eb-134b-57fcc502469c
# ╠═2c31d1ca-5b20-11eb-1f1b-db947a36b2c6
# ╠═baf09934-5b20-11eb-3283-d9b7bdfb5a90
# ╠═dc1fdc56-6bcd-11eb-32c7-f3515450573c
# ╠═f9b7501b-abb7-4998-bf5a-787cba8355d6
# ╠═fc91c29a-6bca-11eb-1cd7-132e515bcc53
# ╠═74295a2c-6bc9-11eb-1474-9befdff2e2bf
# ╠═7b2f2674-5b22-11eb-225c-cbd01d9b1058
# ╠═080ecf02-5549-11eb-06cd-b10c7ed4e1e4
# ╠═0f8d9246-6bd2-11eb-3c89-7dcd26ee5f0e
# ╠═742c4eaa-7fe5-11eb-37e5-b96d6d7d86cd
# ╠═15f92d78-5b26-11eb-0050-27f2434d1f75
# ╠═dcba4866-5b26-11eb-3e27-8fc9dd4bae77
# ╠═d49f6f5e-5cb5-11eb-14e1-45d31ab53e89
# ╠═d212b59e-810d-11eb-3b97-5dd770b3c949
# ╠═1889b0c6-6c97-11eb-1577-3ba3e8940484
# ╠═d7a78b2e-5cb7-11eb-1967-1b3dc0a388bd
# ╠═65004f86-3c67-43a6-bb01-16df98e58148
# ╠═446f8889-a549-4fd2-b3e4-c09af9961405
# ╠═6eccfc72-cf1f-4259-942d-5898c83f4df7
# ╠═15499246-5cb6-11eb-2683-d34604bf5914
# ╠═ef39fc56-554b-11eb-3082-77349ed217d4
# ╠═c85e156e-554a-11eb-218b-df5eabe2d8ab
# ╠═7f5be60a-5b23-11eb-3d24-d17513534e16
# ╠═5123d73c-6c9b-11eb-0231-675c2b98d0d3
# ╠═d8ed8d5c-6c9b-11eb-2215-2fb6b80d30e2
# ╠═d5b5cf78-5a87-11eb-1d85-176632857548
# ╠═620a967e-5b2f-11eb-3dc5-6108d315124b
# ╟─dd2bc6ca-5a87-11eb-1cfd-9bbf310b48fa
# ╟─9b1d7a9a-5a8b-11eb-3721-510c5ee70087
# ╠═15a2336e-5a91-11eb-3f7b-a3e55c5a3be4
# ╠═935814f4-5a91-11eb-2dc7-a9db013f9d95
# ╠═02b9ba5c-5a8b-11eb-39b1-0d23e4c12f0b
# ╠═4d0b47b8-5a88-11eb-094a-1d816b3d3a9b
# ╠═d78890c6-5a88-11eb-3601-13e50420b603
# ╠═e7510d12-5a88-11eb-0536-8de677458800
# ╠═ee2ef6ca-5a89-11eb-0b85-0d59759a8bac
# ╠═de09158c-5a89-11eb-23d3-adc6acc42782
# ╟─b2ddbdf0-5a88-11eb-3dba-03b51da9048e
# ╠═5b8a2d9a-5a88-11eb-1193-998aca8aa0a0
# ╠═b0a9669c-5a88-11eb-34ee-cd73f0892f7f
# ╠═84c21a6c-4109-11eb-166e-151c460d28c8
# ╠═50b8ef74-5591-11eb-26bf-9feb4bba0ca3
# ╠═7b147c4e-559f-11eb-37ce-075bf3998087
# ╠═f690e870-5591-11eb-0a58-6faf52de3fec
# ╠═57c9516e-5591-11eb-226e-f163d5df253d
# ╠═070ea700-5592-11eb-1334-abb3cb13262a
# ╠═5def440c-5591-11eb-05b9-0dfd6d2952c8
# ╠═18c7119e-5592-11eb-1afb-e71d7e7b9ca8
# ╠═6edc69c2-5591-11eb-0b05-b35d24abe8aa
# ╠═3ad405cc-55a0-11eb-169a-43cfdaa2d3af
# ╠═3be46f9c-55a0-11eb-1e67-f9c641ab7eaf
# ╠═c98e09ac-55a0-11eb-29d3-b12c978f1e57
# ╠═3198fbb0-55a1-11eb-016e-712a7d8f07f1
# ╠═b29c4136-55a1-11eb-0f19-85789ee1a471
# ╠═c135bbca-559f-11eb-21d0-81f51845afcb
# ╠═42b15790-55a0-11eb-0a84-a79553b87993
# ╠═cc0c493c-55a0-11eb-37ee-dff68db5868b
# ╠═cc6a6710-55a0-11eb-1da6-45a6bb3bb173
# ╠═7f1987a6-55a1-11eb-2e64-631c13345a8f
# ╠═ec9ee372-559f-11eb-3e88-3f4a9cd4c0ec
# ╠═1f54ed0c-55a0-11eb-14bd-01ed4f5743e7
# ╠═ecfdecf4-55a0-11eb-0427-d9eacdea896c
# ╠═ed11f462-55a0-11eb-364b-6b9fd7282d48
# ╠═3d797c44-55a0-11eb-2490-d98ffcf5f006
# ╠═61e0edf6-55a0-11eb-0d43-69315ade5c2e
# ╠═71d73800-55a0-11eb-28aa-895ff4f0a36b
# ╠═a76941d0-559f-11eb-2412-bbdefbbfeb04
# ╠═fe32a588-559f-11eb-25c8-25c3fdb3fb3f
# ╠═045ab740-55a1-11eb-0751-a59eb196863e
# ╠═962f7d2e-55a1-11eb-3299-215a5c9504c5
# ╠═74fa7748-410c-11eb-0688-a37608618c96
# ╠═fdae38fe-410c-11eb-18dd-9bae51fb4e00
# ╠═fdbe0894-410c-11eb-0ace-3d269b2942aa
# ╠═220ec448-410d-11eb-17c3-d1682a1588c9
# ╠═4b4e5710-55a3-11eb-2f5d-3df5543e480c
# ╠═5a8d3296-55a3-11eb-3d1c-65245f677262
# ╠═75ef05aa-55a3-11eb-1c89-fd0fb600608f
# ╠═22b3b39e-55a4-11eb-3d8e-a18fe4e18872
# ╠═6e1b79c0-55a4-11eb-2d3f-296762a8604f
# ╠═7c3d0eb0-55a4-11eb-3ed0-81c97785c7f0
# ╠═7f1fb2fe-55a4-11eb-1b91-3bd39c4872fe
# ╠═3bb15c6c-410d-11eb-1b1b-4b13708ceb70
# ╠═0f68fa64-55a5-11eb-24ed-fd2b3fc9ed68
# ╠═528ef22e-55a5-11eb-2b03-3d92a4b9c3c6
# ╠═3de00658-55a5-11eb-102e-3103b223001d
# ╠═c094cb3a-4117-11eb-168a-df762ad5739e
# ╠═a837ef5c-55a5-11eb-06f5-cb27048bc9a4
# ╠═c5cecd9e-55a5-11eb-343a-a3c29893be1f
# ╠═cff2f4c4-55a5-11eb-32c2-1db64f8ea677
# ╠═74480530-55a6-11eb-0a7b-8b30ed458234
# ╠═b0f10e8e-55a6-11eb-34a1-755dceb63e08
# ╠═ef0bdbcc-55a6-11eb-114f-7d43ab25736a
# ╠═7fec90b4-411b-11eb-04db-a913940a9f22
# ╠═451edba2-4122-11eb-0ea9-b3e5a7021bd1
# ╠═46652b7e-4122-11eb-1576-29e34caf1b03
# ╠═78e0e354-4122-11eb-1a11-0b1d36a38b70
# ╠═46798970-4122-11eb-31a8-ab967162b1ae
# ╠═20c55224-55a7-11eb-2490-010a8c63cd4b
# ╠═c98691d4-4125-11eb-3e71-d1ffa4fc0f3a
# ╠═aa066c66-4126-11eb-1909-713aeda74edc
# ╠═c4375a50-4126-11eb-2667-7b693682e9a8
# ╠═aa323b5c-4126-11eb-18fa-a5aa100d0678
# ╠═aa487444-4126-11eb-306c-1d98f391cfc6
# ╠═aa708326-4126-11eb-2129-df2f5666aa93
