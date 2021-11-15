### A Pluto.jl notebook ###
# v0.12.18

using Markdown
using InteractiveUtils

# ╔═╡ bb6cae46-4108-11eb-2309-3d11f13a19fa
begin
	using Pkg
	Pkg.activate(mktempdir())
end

# ╔═╡ d8b334ae-4108-11eb-2546-99e75efc18d6
begin
	Pkg.add(["Plots", "PlutoUI","StatsBase", "DataStructures", "Unitful", "PhysicalConstants", "UnitfulEquivalences", "DataFrames", "CSV", "Dates", "TimeZones", "StatsPlots"])

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
end

# ╔═╡ e6b122ce-5548-11eb-3980-53dfd8e5897c
begin
	frmt = dateformat"yyyy-mm-dd HH:MM:SS"
	column_types = Dict(:ResultTime=>DateTime, :AnalysisInsertTime=>DateTime)
	df = CSV.read("/home/kris/Downloads/opendata_covid19_test_results.csv", DataFrame, types=column_types, dateformat=frmt)
	0
end

# ╔═╡ 080ecf02-5549-11eb-06cd-b10c7ed4e1e4
groups = groupby(df, [:ResultValue]);

# ╔═╡ ef39fc56-554b-11eb-3082-77349ed217d4
counts = (combine(groups, nrow => :count));

# ╔═╡ c85e156e-554a-11eb-218b-df5eabe2d8ab
@df counts bar(:ResultValue, :count);

# ╔═╡ 5c0da80e-554d-11eb-000d-c555faffdf97


# ╔═╡ 84c21a6c-4109-11eb-166e-151c460d28c8
md"""
## E3.1.1

The body with the charge of 2 mC is located in the vacuum. It is affected by the electrical force of 10 N. The strength of the electric field at the location of the body is 1)


5

 kV/m. If the body was put into the oil with relative permittivity of 5, then at the same point the body would be affected with the force of 2)


2 N

. If the electric field performs work of 4 J to move the body in vacuum from one point to another, then the voltage between this two points is 3)


2 kV
"""

# ╔═╡ 47c6bb76-5992-11eb-0e18-cde81c30ee77
charge1 = 0.15u"mC"

# ╔═╡ a42e65d0-5992-11eb-2d53-19733c30a873
ϵₚ = 5

# ╔═╡ 41a70312-5993-11eb-1f23-8bb4d06dcf8d
work1 = 60u"J"

# ╔═╡ 4f23225a-5993-11eb-0aa8-7d32c5ad8c4d
voltage_after_work = uconvert(u"kV", work1 / charge1)

# ╔═╡ 6bcd3e82-5992-11eb-1c61-7b80e13da159
field_str = voltage_after_work / 5

# ╔═╡ db828bf4-599e-11eb-0813-6deb3e27ab1a
work12 = uconvert(u"J", field_str * charge1)

# ╔═╡ 71d73800-55a0-11eb-28aa-895ff4f0a36b
force(a) = uconvert(u"kN", mass*a + drag)

# ╔═╡ a76941d0-559f-11eb-2412-bbdefbbfeb04
distance(v1, v2, t) = (v1 + v2) / 2 * t

# ╔═╡ fe32a588-559f-11eb-25c8-25c3fdb3fb3f
acc(v1, v2, t) = (v2-v1) / t

# ╔═╡ 045ab740-55a1-11eb-0751-a59eb196863e
work(f, s) = uconvert(u"kJ", f*s)

# ╔═╡ 962f7d2e-55a1-11eb-3299-215a5c9504c5
power(w, t) = uconvert(u"kW", w/t)

# ╔═╡ 74fa7748-410c-11eb-0688-a37608618c96
md"""
## E2
In the point A of homogeneous electric field, the potential is 16 V. At the distance of 2 cm from it along field force lines at the point B, the potential is 6 V. The strength of this electric field is 1)


500 V/m

. In the point C, located at the distance of 6 cm from point B along field lines, the potential is 2) 


-24 V

"""

# ╔═╡ cd4916f8-5993-11eb-1def-3148b93fd7b4
potentialA = 300u"V"

# ╔═╡ e7a4a224-5993-11eb-1c08-2505f07f4345
potentialB = 50u"V"

# ╔═╡ d64736ae-5993-11eb-1736-c92991477f38
l2 = 5u"cm"

# ╔═╡ e07ed210-5993-11eb-1465-a37a64d77a74
EFS = uconvert(u"V/m", (potentialA - potentialB) / l2)

# ╔═╡ 1bd78dcc-5994-11eb-2fd0-31f9afced995
l22 = 8u"cm"

# ╔═╡ 3e0c0d46-5994-11eb-07b7-0b45134bf027
potentialC = potentialB - uconvert(u"V", EFS * l22)

# ╔═╡ 3bb15c6c-410d-11eb-1b1b-4b13708ceb70
md"""
## E3


"""

# ╔═╡ c094cb3a-4117-11eb-168a-df762ad5739e
md"""
## E4

The battery has the electromotive force (EMF) of 6 V. During 5 seconds, it carries through the electric circuit the charge of 2 C. The current in this circuit is 1)


0.4 A

 and the full resistance of the circuit is 2) 


15

 Ω (ohm). The non-electric forces in the battery perform work of 24 J during 3)


10

 seconds. The same work could be done in 2 seconds if the full resistance of electric circuit would be 4)


3

 Ω (ohm).

"""

# ╔═╡ a837ef5c-55a5-11eb-06f5-cb27048bc9a4
EMF = 6u"V"

# ╔═╡ c9e492ce-5995-11eb-138c-27f8984aa6ac
time = 10u"s"

# ╔═╡ e9a4ffe0-5995-11eb-10dd-5782d6049293
Q4 = 4u"C"

# ╔═╡ f2861d60-5995-11eb-274c-b5808b24f26f
current4 = uconvert(u"A", Q4 / time)

# ╔═╡ 1532b6e8-5996-11eb-2802-d95d5a5f6154
Ω = uconvert(u"Ω", EMF / current4)

# ╔═╡ 33eaa51e-5996-11eb-3a53-7b4ec3984bd4
work4 = 24u"J"

# ╔═╡ 3dd9c42e-5996-11eb-2c50-d17f0d97f8f5
work_duration = uconvert(u"s", work4 / EMF /current4)

# ╔═╡ bd6414e2-5996-11eb-231c-27f1fefe56d9
new_duration = 2u"s"

# ╔═╡ b7942c96-5996-11eb-08e1-5ba18eb8606e
new_current = uconvert(u"A", work4 / EMF / new_duration)

# ╔═╡ cab22148-5996-11eb-2bd4-67e38d07d4b4
new_resistance  = uconvert(u"Ω", EMF / new_current)

# ╔═╡ 38d27f92-5997-11eb-1f3b-a5f9cba02480
work_duration2 = uconvert(u"s", work4 / EMF /new_current)

# ╔═╡ 451edba2-4122-11eb-0ea9-b3e5a7021bd1
md"""
# E5


"""

# ╔═╡ 46652b7e-4122-11eb-1576-29e34caf1b03


# ╔═╡ 78e0e354-4122-11eb-1a11-0b1d36a38b70


# ╔═╡ 46798970-4122-11eb-31a8-ab967162b1ae


# ╔═╡ 20c55224-55a7-11eb-2490-010a8c63cd4b


# ╔═╡ c98691d4-4125-11eb-3e71-d1ffa4fc0f3a
md"""
## E6

The figure shows a DC motor winding located in a magnetic field. The dimensions of the winding are: ab = 5 cm, bc = 6 cm. Magnetic induction is 100 mT and the current flowing through the winding is 4 A. The section ab is affected by the force of 1)


20

 mN. The winding is affected by the torque of 2)


1.2

mN*m. The rotor is spinning with the angular velocity of 200 rad/s. The magnetic flux penetrating the winding in the position showed in the figure is 3)


0

 mWb and the electromotive force of the electromagnetic induction is 4)


60

 mV. When rotor has made one fourth of its full rotation (cycle), the magnetic flux is 5)


0.3

 mWb and the EMF of the electromagnetic induction is 6) 


0

 mV.
"""

# ╔═╡ aa066c66-4126-11eb-1909-713aeda74edc
ab = 5u"cm"

# ╔═╡ 513b3442-599a-11eb-3931-bf734a4d60bb
bc = 6u"cm"

# ╔═╡ 56985c56-599a-11eb-37c8-7f3747a1a06d
B = 100u"mT"

# ╔═╡ 63fd7694-599a-11eb-1bba-23f0bac23715
I = 4u"A"

# ╔═╡ 6dbb8f04-599a-11eb-0768-59e7c5ab71cc
F_ab = uconvert(u"mN", B * ab * I)

# ╔═╡ c681c1ae-599c-11eb-20b1-ffa68c2ad850
torque = uconvert(u"mN * m", F_ab * bc)

# ╔═╡ b402012a-599d-11eb-2551-3df8a06dde90
spin_vel = 200u"rad/s"

# ╔═╡ ed536bf4-599d-11eb-13b7-c740e3b65a6b
EMF6 = uconvert(u"mV", torque / )

# ╔═╡ fa9ead58-599c-11eb-3852-1f7c38a18af7
work6 = 

# ╔═╡ ddcabd5e-599a-11eb-11c4-75dff15dc5f0
cos(pi/2)

# ╔═╡ c4375a50-4126-11eb-2667-7b693682e9a8
freq6 = 125u"Hz"

# ╔═╡ aa323b5c-4126-11eb-18fa-a5aa100d0678
period6 = uconvert(u"ms", 1/freq6)

# ╔═╡ aa487444-4126-11eb-306c-1d98f391cfc6
wavelength6 = uconvert(u"cm", speed6*period6)

# ╔═╡ aa708326-4126-11eb-2129-df2f5666aa93
wave_n = uconvert(u"m^-1", 2*pi/wavelength6)

# ╔═╡ c38bcaf2-559c-11eb-1451-6373541f144c
x = 0:0.05:15

# ╔═╡ 4232c16c-559d-11eb-3a0a-07a5b1b9b154
y = map(x -> sin(x/pi*4*ustrip(period6)-pi/2), x)

# ╔═╡ aaeb2c04-559c-11eb-2e55-d354927af823
plot(x, y)

# ╔═╡ 9b08e2f0-59a1-11eb-1bf9-95b7403cbd8b


# ╔═╡ 9b229b12-59a1-11eb-18ba-a9ff38f60136
U = 220u"V"

# ╔═╡ bfb1e7a4-59a2-11eb-11c7-676852e2123f
P = 100u"W"

# ╔═╡ 9b39747c-59a1-11eb-18fa-5d2307c4cb4b
I8 = uconvert(u"A", P / U)

# ╔═╡ 3ef6f83c-59a4-11eb-03b9-8916d192506e
R8 = uconvert(u"Ω", U / I8)

# ╔═╡ 5cb5321c-59a4-11eb-0593-638e9d86a07f
R_series = uconvert(u"Ω", R8 + R8)

# ╔═╡ 7d967d2e-59a4-11eb-2eda-2b86755706ff
I_series = uconvert(u"A", U / R_series) 

# ╔═╡ cb6a6e72-59a2-11eb-25c5-4fb45b9c17b6
R_all = uconvert(u"Ω", (R8 / 2 + R8))

# ╔═╡ 6a3dc4ce-59a6-11eb-28c0-27974bf8e93b


# ╔═╡ 9b501a9e-59a1-11eb-2079-77b6f8c1a92d
power8(V,I) = uconvert(u"W", V*I)

# ╔═╡ d58ff714-59a2-11eb-177c-1b664fa69aef
power8(U, I_series)

# ╔═╡ 87af6af4-59a5-11eb-254c-85c671d18d3a
all = power8(U, U/R_all)

# ╔═╡ e40c6518-59a5-11eb-3a95-9bf7c660e933
par = power8(U, U/((1/R8 + 1/R8)^-1))

# ╔═╡ 455615b8-59a5-11eb-081f-b5000a172fea
60 / 4

# ╔═╡ Cell order:
# ╠═bb6cae46-4108-11eb-2309-3d11f13a19fa
# ╠═d8b334ae-4108-11eb-2546-99e75efc18d6
# ╠═e6b122ce-5548-11eb-3980-53dfd8e5897c
# ╠═080ecf02-5549-11eb-06cd-b10c7ed4e1e4
# ╠═ef39fc56-554b-11eb-3082-77349ed217d4
# ╠═c85e156e-554a-11eb-218b-df5eabe2d8ab
# ╠═5c0da80e-554d-11eb-000d-c555faffdf97
# ╠═84c21a6c-4109-11eb-166e-151c460d28c8
# ╠═47c6bb76-5992-11eb-0e18-cde81c30ee77
# ╠═6bcd3e82-5992-11eb-1c61-7b80e13da159
# ╠═db828bf4-599e-11eb-0813-6deb3e27ab1a
# ╠═a42e65d0-5992-11eb-2d53-19733c30a873
# ╠═41a70312-5993-11eb-1f23-8bb4d06dcf8d
# ╠═4f23225a-5993-11eb-0aa8-7d32c5ad8c4d
# ╟─71d73800-55a0-11eb-28aa-895ff4f0a36b
# ╟─a76941d0-559f-11eb-2412-bbdefbbfeb04
# ╟─fe32a588-559f-11eb-25c8-25c3fdb3fb3f
# ╟─045ab740-55a1-11eb-0751-a59eb196863e
# ╟─962f7d2e-55a1-11eb-3299-215a5c9504c5
# ╠═74fa7748-410c-11eb-0688-a37608618c96
# ╠═cd4916f8-5993-11eb-1def-3148b93fd7b4
# ╠═e7a4a224-5993-11eb-1c08-2505f07f4345
# ╠═d64736ae-5993-11eb-1736-c92991477f38
# ╠═e07ed210-5993-11eb-1465-a37a64d77a74
# ╠═1bd78dcc-5994-11eb-2fd0-31f9afced995
# ╠═3e0c0d46-5994-11eb-07b7-0b45134bf027
# ╠═3bb15c6c-410d-11eb-1b1b-4b13708ceb70
# ╠═c094cb3a-4117-11eb-168a-df762ad5739e
# ╠═a837ef5c-55a5-11eb-06f5-cb27048bc9a4
# ╠═c9e492ce-5995-11eb-138c-27f8984aa6ac
# ╠═e9a4ffe0-5995-11eb-10dd-5782d6049293
# ╠═f2861d60-5995-11eb-274c-b5808b24f26f
# ╠═1532b6e8-5996-11eb-2802-d95d5a5f6154
# ╠═33eaa51e-5996-11eb-3a53-7b4ec3984bd4
# ╠═3dd9c42e-5996-11eb-2c50-d17f0d97f8f5
# ╠═bd6414e2-5996-11eb-231c-27f1fefe56d9
# ╠═cab22148-5996-11eb-2bd4-67e38d07d4b4
# ╠═b7942c96-5996-11eb-08e1-5ba18eb8606e
# ╠═38d27f92-5997-11eb-1f3b-a5f9cba02480
# ╠═451edba2-4122-11eb-0ea9-b3e5a7021bd1
# ╠═46652b7e-4122-11eb-1576-29e34caf1b03
# ╠═78e0e354-4122-11eb-1a11-0b1d36a38b70
# ╠═46798970-4122-11eb-31a8-ab967162b1ae
# ╠═20c55224-55a7-11eb-2490-010a8c63cd4b
# ╠═c98691d4-4125-11eb-3e71-d1ffa4fc0f3a
# ╠═aa066c66-4126-11eb-1909-713aeda74edc
# ╠═513b3442-599a-11eb-3931-bf734a4d60bb
# ╠═56985c56-599a-11eb-37c8-7f3747a1a06d
# ╠═63fd7694-599a-11eb-1bba-23f0bac23715
# ╠═6dbb8f04-599a-11eb-0768-59e7c5ab71cc
# ╠═c681c1ae-599c-11eb-20b1-ffa68c2ad850
# ╠═b402012a-599d-11eb-2551-3df8a06dde90
# ╠═ed536bf4-599d-11eb-13b7-c740e3b65a6b
# ╠═fa9ead58-599c-11eb-3852-1f7c38a18af7
# ╠═ddcabd5e-599a-11eb-11c4-75dff15dc5f0
# ╠═c4375a50-4126-11eb-2667-7b693682e9a8
# ╠═aa323b5c-4126-11eb-18fa-a5aa100d0678
# ╠═aa487444-4126-11eb-306c-1d98f391cfc6
# ╠═aa708326-4126-11eb-2129-df2f5666aa93
# ╠═aaeb2c04-559c-11eb-2e55-d354927af823
# ╠═c38bcaf2-559c-11eb-1451-6373541f144c
# ╠═4232c16c-559d-11eb-3a0a-07a5b1b9b154
# ╠═9b08e2f0-59a1-11eb-1bf9-95b7403cbd8b
# ╠═9b229b12-59a1-11eb-18ba-a9ff38f60136
# ╠═bfb1e7a4-59a2-11eb-11c7-676852e2123f
# ╠═9b39747c-59a1-11eb-18fa-5d2307c4cb4b
# ╠═3ef6f83c-59a4-11eb-03b9-8916d192506e
# ╠═5cb5321c-59a4-11eb-0593-638e9d86a07f
# ╠═7d967d2e-59a4-11eb-2eda-2b86755706ff
# ╠═d58ff714-59a2-11eb-177c-1b664fa69aef
# ╠═cb6a6e72-59a2-11eb-25c5-4fb45b9c17b6
# ╠═87af6af4-59a5-11eb-254c-85c671d18d3a
# ╠═e40c6518-59a5-11eb-3a95-9bf7c660e933
# ╠═6a3dc4ce-59a6-11eb-28c0-27974bf8e93b
# ╠═9b501a9e-59a1-11eb-2079-77b6f8c1a92d
# ╠═455615b8-59a5-11eb-081f-b5000a172fea
