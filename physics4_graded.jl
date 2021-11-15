### A Pluto.jl notebook ###
# v0.12.4

using Markdown
using InteractiveUtils

# ╔═╡ bb6cae46-4108-11eb-2309-3d11f13a19fa
begin
	using Pkg
	Pkg.activate(mktempdir())
end

# ╔═╡ d8b334ae-4108-11eb-2546-99e75efc18d6
begin
	Pkg.add(["Plots", "PlutoUI","StatsBase", "DataStructures", "Unitful", "PhysicalConstants", "UnitfulEquivalences"])

	using Plots
	plotly()
	using PlutoUI
	using StatsBase
	using DataStructures
	using Unitful
	using PhysicalConstants.CODATA2018: c_0, h, ħ
	using UnitfulEquivalences
end

# ╔═╡ 56127994-4129-11eb-1b74-e92215af5b82
energy1 = 6.2u"keV"

# ╔═╡ 54d9f070-4129-11eb-13f6-2b138f584c42
wavelength1 = uconvert(u"pm", energy1, Spectral())

# ╔═╡ 83bc9488-4129-11eb-3c64-d71221b14aeb
freq1 = uconvert(u"Hz", energy1, Spectral())

# ╔═╡ 5990a14a-410b-11eb-086a-f129b7fdf82c
refracted_speed2 = uconvert(u"Mm/s", c_0 / 1.33)

# ╔═╡ 6209ea56-410c-11eb-0bb3-ff80947cdcb0
wavelength2 = 1.5u"μm"

# ╔═╡ a78b9c3a-4109-11eb-26ca-1556cfeb2b8c
quantum_energy2 = uconvert(u"eV", wavelength2, Spectral())

# ╔═╡ 84c21a6c-4109-11eb-166e-151c460d28c8
md"""
## E2

Light, which possesses in vacuum the frequency of 500 THz and quantum energy of $quantum_energy2, passes through
sheet of glass with the refractive index of 1.5. The speed of such light in glass is $refracted_speed2, the frequency is
500 THz, the wavelength is $wavelength2 and quantum energy is 2.07 eV.
"""

# ╔═╡ 1fd66092-412a-11eb-3468-bf3c5c496686
freq2 = uconvert(u"THz", wavelength2, Spectral())

# ╔═╡ fdae38fe-410c-11eb-18dd-9bae51fb4e00
freq3 = 350u"THz"

# ╔═╡ 220ec448-410d-11eb-17c3-d1682a1588c9
refractive3 = 1.5

# ╔═╡ fdbe0894-410c-11eb-0ace-3d269b2942aa
n = refractive3 ^2

# ╔═╡ 74fa7748-410c-11eb-0688-a37608618c96
md"""
## E3.1

The electric field strength that oscillates with the frequency of **$freq3** is reduced **$n** times in some substance
with respect to the vacuum. The refractive index of this substance is **$refractive3**
"""

# ╔═╡ 31bce1b8-410d-11eb-008b-bf04b66bf555
slit_length4 = 0.03u"mm"

# ╔═╡ 2e0551ea-410d-11eb-176c-650b9c498d25
distance_from_slit = 2u"m"

# ╔═╡ 0aaf6748-410e-11eb-035a-8be0950091d6
minima_distance = 8u"cm"

# ╔═╡ 0aa8bb82-410e-11eb-163c-6de6eda9e616
minima_angle = uconvert(u"rad", atan(minima_distance/2, distance_from_slit))

# ╔═╡ 70a82a76-410e-11eb-2f0e-295b06d5d8fb
wavelength4 = uconvert(u"nm", sin(minima_angle) * slit_length4)

# ╔═╡ 3bb15c6c-410d-11eb-1b1b-4b13708ceb70
md"""
## E4.1

The monochromatic light is penetrating a single **$slit_length4** wide vertical slit. On the screen positioned perpendicular to the light propagating direction at the distance of **$distance_from_slit** behind the slit, a diffraction pattern appears in which the two first minima are located at the distance of **$minima_distance** from each other. The first minimum is located at the angle of **$minima_angle** with respect to the diffraction pattern centre. The wavelength of the light used was **$wavelength4**
"""

# ╔═╡ 0d5b2ca4-412f-11eb-2dec-d1d78f201ff5
wavelength42 = 600u"nm"

# ╔═╡ 0d6c3466-412f-11eb-2ed7-6311848972ed
distance_from_grate = 4u"m"

# ╔═╡ 564061be-412f-11eb-13e1-894885ffb2be
maxima_distance = 24u"cm"

# ╔═╡ 0c352744-412f-11eb-37ae-ff4b3812f6c2
md"""
## E4.2
Red light, which possesses in vacuum the wavelength of **$wavelength42** is penetrating a diffraction grating. On the screen positioned perpendicular to the light propagating direction at the distance of **$distance_from_grate** from the grating, the two first order maxima in the diffraction pattern are located at the distance of **$maxima_distance** from each other.

"""

# ╔═╡ 97321f46-412f-11eb-2cda-b7e915c51a5b
maxima_angle = uconvert(u"rad", atan(maxima_distance/2, distance_from_grate))

# ╔═╡ cb110218-4130-11eb-1284-0fce3810c11f
grating_period = uconvert(u"mm", wavelength42/sin(maxima_angle))

# ╔═╡ c08c3f10-4117-11eb-059e-1fa7c75e4240
absorption_coef_blue = 0.02u"cm^-1"

# ╔═╡ ffd6d630-4117-11eb-2200-a147d74af92f
absorbtion_coef_green = 4u"cm^-1"

# ╔═╡ 38b97e80-4118-11eb-34c5-65de18666aed
absorption_coef_red = 7u"cm^-1"

# ╔═╡ 45bb6c38-4118-11eb-0ba5-f55cde355ccd
green_layer_thickness = uconvert(u"cm", 1/absorbtion_coef_green) 

# ╔═╡ 40d8a62c-4118-11eb-15c3-e9e0c5d87609
n_intensity_reduced = 7

# ╔═╡ 793b338a-4119-11eb-1916-6513f6eed696
ℯ

# ╔═╡ afcc4710-4119-11eb-28db-fdf5aa042d8e
substance_color1 = "blue" 

# ╔═╡ d0340d2e-4119-11eb-209d-7dcf7fa4c2e7
substance_color2 = "black"

# ╔═╡ c094cb3a-4117-11eb-168a-df762ad5739e
md"""
## E5
For some substance, the absorption coefficient for the blue light is **$absorption_coef_blue**. For the green light, it is **$absorbtion_coef_green** and for the red light **$absorption_coef_red**. This means that the intensity of the green light will be reduced Euler number (e = 2.7183..) times by passing through the **$green_layer_thickness** thick layer of the substance. The layer with the thickness of 1 cm reduces the intensity of green light e **$n_intensity_reduced** times. If we illuminate this substance with the white light, the colour of the substance will be **$substance_color1**. If we illuminate the substance with the blue light, the colour of the substance will be **$substance_color2**.

"""

# ╔═╡ 80572be0-411b-11eb-3f15-fbf4e6ed7cf3
electron_speed = 364.7u"km/s"

# ╔═╡ 5788010a-411e-11eb-2c69-bd73c5cd6d3f
ground_speed = 2188u"km/s"

# ╔═╡ 7fe77a98-411b-11eb-1835-75b0687dedfd
n6 = round(ground_speed / electron_speed)

# ╔═╡ 9f78c474-412b-11eb-1cf0-d7f1a152ffcf
reduced_planck = 1.05E-34u"kg*m^2*s^-1"

# ╔═╡ 7fc27112-411b-11eb-3b4b-97599735cd31
angular_momentum = uconvert(u"kg*m^2*s^-1", reduced_planck * n6)

# ╔═╡ 224bba9e-411f-11eb-2901-87f766e95a56
ground_frequency = 6580u"THz"

# ╔═╡ 3ed8da6c-411e-11eb-3a35-4164dfd2aa54
imagined_rotation_frequency = uconvert(u"THz", ground_frequency / n6 ^3)

# ╔═╡ 91b1a86c-411f-11eb-0700-a30281bd1f40
ground_energy = -13.60u"eV"

# ╔═╡ 8a2e2e76-411f-11eb-0da9-ed7c9382599f
net_energy = ground_energy / n6^2

# ╔═╡ 0396e5f2-4120-11eb-1502-f358ec34acd9
ground_radius = 0.529u"Å"

# ╔═╡ 03d6d638-4120-11eb-20d0-0fa5cffc6d3d
mean_distance = ground_radius * n6^2

# ╔═╡ 296b84ce-4121-11eb-2c07-1b1ff4cac46c
emitted_photon_wavelength = 410.6u"nm"

# ╔═╡ f74d6ff0-4120-11eb-2de1-9d7c40c9354c
quantum_energy6 = uconvert(u"eV", emitted_photon_wavelength, Spectral())

# ╔═╡ 66942310-4121-11eb-063c-37022902216f
energy_after_photon = net_energy - quantum_energy6

# ╔═╡ 81bc1422-4121-11eb-0cb5-215e6fb5c308
qn = round(sqrt(ground_energy/energy_after_photon))

# ╔═╡ 8238f47e-4121-11eb-06a7-a3f1bf8887cb
imag_rot_freq2 = uconvert(u"THz", ground_frequency / qn ^3)

# ╔═╡ 0e7c4e68-4122-11eb-3b1a-8f9808df6829
mean_distance2 = ground_radius * qn^2

# ╔═╡ 7fec90b4-411b-11eb-04db-a913940a9f22
md"""
## E6
In the atom of hydrogen, the electron moves according to the Bohr model. Its speed is **$electron_speed**. The angular momentum of this electron is **$angular_momentum**, the frequency of imagined rotation is **$imagined_rotation_frequency**, the net energy is **$net_energy** and the mean distance from the nucleus is **$mean_distance**. The electron comes closer to the nucleus and a photon with the wavelength of **$emitted_photon_wavelength** is emitted. The quantum energy of this radiation is **$quantum_energy6**. At the end of the transition, the frequency of the imagined rotation of the electron is **$imag_rot_freq2** and its mean distance from the nucleus is **$mean_distance2**.
"""

# ╔═╡ 46652b7e-4122-11eb-1576-29e34caf1b03
mass = 20u"mg"

# ╔═╡ 78e0e354-4122-11eb-1a11-0b1d36a38b70
diam = 5u"mm"

# ╔═╡ 46798970-4122-11eb-31a8-ab967162b1ae
h_bar = 1E-34u"J*s"

# ╔═╡ 4691ff34-4122-11eb-1614-b5df5b328525
speed_increase = uconvert(u"m/s", h_bar / (mass * diam))

# ╔═╡ c9767010-4125-11eb-3529-43e03fc0ed7b
time_for_diam = uconvert(u"s", diam / speed_increase)

# ╔═╡ 63ef8d68-412e-11eb-15fd-79cc263180f7
seconds_in_year = (365 * 24 * 60 * 60)u"s"

# ╔═╡ c9680bce-4125-11eb-1a30-93e346ab5ef8
time2 = uconvert(u"s", time_for_diam)

# ╔═╡ 451edba2-4122-11eb-0ea9-b3e5a7021bd1
md"""
# E7

The uranium atom (a microscopic object) with the mass of **$mass** and diameter of **$diam** moves in a certain direction. The location of the atom is fixed by its passing through the slit possessing the width almost equal to the atom diameter. The screen containing this slit is positioned perpendicular to the velocity of the atom. As a result of penetrating this slit, the speed of the atom receives some unpredictable increase perpendicular to the direction of previous motion. Using the reduced Planck constant 10–34 J*s as a typical value of impact uncertainty, we can conclude that the increase of the speed is **$speed_increase**. After **$time_for_diam** seconds, the atom deviates from its classical straight trajectory by its own diameter. This result means that we can predict the motion of uranium atom in a classical way for maximally **$time2** nanoseconds.

"""

# ╔═╡ 571de63e-412e-11eb-3b48-d9192483a1de
time2_years = time2 / seconds_in_year

# ╔═╡ aa066c66-4126-11eb-1909-713aeda74edc
mass8 = 9E-31u"kg"

# ╔═╡ c4375a50-4126-11eb-2667-7b693682e9a8
well_width = 2u"Å"

# ╔═╡ aa323b5c-4126-11eb-18fa-a5aa100d0678
qn8 = 5

# ╔═╡ aa487444-4126-11eb-306c-1d98f391cfc6
planck8 = 6.6E-34u"J*s"

# ╔═╡ aa708326-4126-11eb-2129-df2f5666aa93
wavelength = 2*well_width / qn8

# ╔═╡ aa9ab420-4126-11eb-206b-2bd429f38b13
lin_momentum = uconvert(u"kg*m/s", planck8 / wavelength)

# ╔═╡ aa805792-4126-11eb-20eb-b127d6ae2898
energy8 = uconvert(u"eV", lin_momentum^2/(2*mass8))

# ╔═╡ c98691d4-4125-11eb-3e71-d1ffa4fc0f3a
md"""
## E8

An electron with the mass of **$mass8** is located in a single-dimensional potential well with the width of **$well_width** (approximate diameter of the atom). Let us describe this electron according to the laws of quantum mechanics as a standing wave in the string, whereas the length of the string is equal to the width of the potential well. In the state described by the quantum number **$qn8**, the wavelength of the electron is **$wavelength**, its
linear momentum is **$lin_momentum** and its energy is **$energy8**.

"""

# ╔═╡ aa5f27d4-4126-11eb-19db-9b02f89cf0f0
md"""

## E9

An incandescent lamp has the nominal power of 60 W and the nominal voltage of 220 V. The cylindrical
filament of this lamp operating at the absolute temperature of 2650 K is made from tungsten (W). The
resistivity of tungsten at 2650 K is 0.64 μΩ*m. The electric field strength inside the filament is 500 V/m.
The resistance of the filament is 807 ohms, its length is 44 cm, the cross-sectional area of the filament is
3.49 *10–10 m2 and its radius is 10.5 micrometers. The cylinder surface area of the filament is 29.0 mm2.
The surface radiance of the filament is 2.07 MW/m2. If we describe the filament as a blackbody, its radiance
will be 2.80 MW/m2. The maximum of the spectral radiance of the lamp will be located in the spectrum at
the wavelength of 1094 nm.

"""

# ╔═╡ aa1d3ab8-4126-11eb-11d9-ab8a72c7e68f
power = 21u"W"

# ╔═╡ 244d7438-4131-11eb-1b84-c37c9c688b08
voltage = 12u"V"

# ╔═╡ 2d25a12a-4131-11eb-0cf6-7f77bfcf2071
temp = 2750u"K"

# ╔═╡ 3860b1f6-4131-11eb-198e-f3f101300a20
resistivity = 0.67u"μΩ*m"

# ╔═╡ 53aad108-4131-11eb-393a-3b7c4707017a
efs = 350u"V/m"

# ╔═╡ 624d2ab2-4131-11eb-0d4d-1f55c87e0abb
resistance = uconvert(u"Ω", voltage^2/power)

# ╔═╡ 7be2c68c-4131-11eb-3e4f-41b7e535bd69
length = uconvert(u"cm", voltage / efs)

# ╔═╡ b418c7fc-4131-11eb-36ad-0bcaf71c41b3
cross_section = uconvert(u"m^2", (resistivity * length) /  resistance)

# ╔═╡ 038ff9c2-4132-11eb-3ccb-eb745f9d9827
radius = uconvert(u"μm", sqrt(cross_section/pi))

# ╔═╡ 3c07c514-4132-11eb-0a3e-8b13abce99bb
silinder_surface = uconvert(u"mm^2", 2*pi*radius*length)

# ╔═╡ 9cbd7b60-4132-11eb-0692-67048ff2a347
wien_displacement = 2896u"μm*K"

# ╔═╡ 103478d8-4132-11eb-116e-6137e6dde875
radiant_exitance = uconvert(u"MW/m^2", power / silinder_surface)

# ╔═╡ Cell order:
# ╠═bb6cae46-4108-11eb-2309-3d11f13a19fa
# ╠═d8b334ae-4108-11eb-2546-99e75efc18d6
# ╠═56127994-4129-11eb-1b74-e92215af5b82
# ╠═54d9f070-4129-11eb-13f6-2b138f584c42
# ╠═83bc9488-4129-11eb-3c64-d71221b14aeb
# ╟─84c21a6c-4109-11eb-166e-151c460d28c8
# ╠═a78b9c3a-4109-11eb-26ca-1556cfeb2b8c
# ╠═5990a14a-410b-11eb-086a-f129b7fdf82c
# ╠═6209ea56-410c-11eb-0bb3-ff80947cdcb0
# ╠═1fd66092-412a-11eb-3468-bf3c5c496686
# ╟─74fa7748-410c-11eb-0688-a37608618c96
# ╠═fdae38fe-410c-11eb-18dd-9bae51fb4e00
# ╠═fdbe0894-410c-11eb-0ace-3d269b2942aa
# ╠═220ec448-410d-11eb-17c3-d1682a1588c9
# ╠═3bb15c6c-410d-11eb-1b1b-4b13708ceb70
# ╠═31bce1b8-410d-11eb-008b-bf04b66bf555
# ╠═2e0551ea-410d-11eb-176c-650b9c498d25
# ╠═0aaf6748-410e-11eb-035a-8be0950091d6
# ╠═0aa8bb82-410e-11eb-163c-6de6eda9e616
# ╠═70a82a76-410e-11eb-2f0e-295b06d5d8fb
# ╠═0c352744-412f-11eb-37ae-ff4b3812f6c2
# ╠═0d5b2ca4-412f-11eb-2dec-d1d78f201ff5
# ╠═0d6c3466-412f-11eb-2ed7-6311848972ed
# ╠═564061be-412f-11eb-13e1-894885ffb2be
# ╠═97321f46-412f-11eb-2cda-b7e915c51a5b
# ╠═cb110218-4130-11eb-1284-0fce3810c11f
# ╠═c094cb3a-4117-11eb-168a-df762ad5739e
# ╠═c08c3f10-4117-11eb-059e-1fa7c75e4240
# ╠═ffd6d630-4117-11eb-2200-a147d74af92f
# ╠═38b97e80-4118-11eb-34c5-65de18666aed
# ╠═45bb6c38-4118-11eb-0ba5-f55cde355ccd
# ╠═40d8a62c-4118-11eb-15c3-e9e0c5d87609
# ╠═793b338a-4119-11eb-1916-6513f6eed696
# ╠═afcc4710-4119-11eb-28db-fdf5aa042d8e
# ╠═d0340d2e-4119-11eb-209d-7dcf7fa4c2e7
# ╟─7fec90b4-411b-11eb-04db-a913940a9f22
# ╠═80572be0-411b-11eb-3f15-fbf4e6ed7cf3
# ╠═5788010a-411e-11eb-2c69-bd73c5cd6d3f
# ╠═7fe77a98-411b-11eb-1835-75b0687dedfd
# ╠═9f78c474-412b-11eb-1cf0-d7f1a152ffcf
# ╠═7fc27112-411b-11eb-3b4b-97599735cd31
# ╠═224bba9e-411f-11eb-2901-87f766e95a56
# ╠═3ed8da6c-411e-11eb-3a35-4164dfd2aa54
# ╠═91b1a86c-411f-11eb-0700-a30281bd1f40
# ╠═8a2e2e76-411f-11eb-0da9-ed7c9382599f
# ╠═0396e5f2-4120-11eb-1502-f358ec34acd9
# ╠═03d6d638-4120-11eb-20d0-0fa5cffc6d3d
# ╠═296b84ce-4121-11eb-2c07-1b1ff4cac46c
# ╠═f74d6ff0-4120-11eb-2de1-9d7c40c9354c
# ╠═66942310-4121-11eb-063c-37022902216f
# ╠═81bc1422-4121-11eb-0cb5-215e6fb5c308
# ╠═8238f47e-4121-11eb-06a7-a3f1bf8887cb
# ╠═0e7c4e68-4122-11eb-3b1a-8f9808df6829
# ╟─451edba2-4122-11eb-0ea9-b3e5a7021bd1
# ╠═46652b7e-4122-11eb-1576-29e34caf1b03
# ╠═78e0e354-4122-11eb-1a11-0b1d36a38b70
# ╠═46798970-4122-11eb-31a8-ab967162b1ae
# ╠═4691ff34-4122-11eb-1614-b5df5b328525
# ╠═c9767010-4125-11eb-3529-43e03fc0ed7b
# ╠═571de63e-412e-11eb-3b48-d9192483a1de
# ╠═63ef8d68-412e-11eb-15fd-79cc263180f7
# ╠═c9680bce-4125-11eb-1a30-93e346ab5ef8
# ╠═c98691d4-4125-11eb-3e71-d1ffa4fc0f3a
# ╠═aa066c66-4126-11eb-1909-713aeda74edc
# ╠═c4375a50-4126-11eb-2667-7b693682e9a8
# ╠═aa323b5c-4126-11eb-18fa-a5aa100d0678
# ╠═aa487444-4126-11eb-306c-1d98f391cfc6
# ╠═aa708326-4126-11eb-2129-df2f5666aa93
# ╠═aa9ab420-4126-11eb-206b-2bd429f38b13
# ╠═aa805792-4126-11eb-20eb-b127d6ae2898
# ╠═aa5f27d4-4126-11eb-19db-9b02f89cf0f0
# ╠═aa1d3ab8-4126-11eb-11d9-ab8a72c7e68f
# ╠═244d7438-4131-11eb-1b84-c37c9c688b08
# ╠═2d25a12a-4131-11eb-0cf6-7f77bfcf2071
# ╠═3860b1f6-4131-11eb-198e-f3f101300a20
# ╠═53aad108-4131-11eb-393a-3b7c4707017a
# ╠═624d2ab2-4131-11eb-0d4d-1f55c87e0abb
# ╠═7be2c68c-4131-11eb-3e4f-41b7e535bd69
# ╠═b418c7fc-4131-11eb-36ad-0bcaf71c41b3
# ╠═038ff9c2-4132-11eb-3ccb-eb745f9d9827
# ╠═3c07c514-4132-11eb-0a3e-8b13abce99bb
# ╠═9cbd7b60-4132-11eb-0692-67048ff2a347
# ╠═103478d8-4132-11eb-116e-6137e6dde875
