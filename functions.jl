### A Pluto.jl notebook ###
# v0.16.0

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

# ╔═╡ f4653ca6-5cba-11eb-0935-4d963ea430c8
begin
	using Pkg
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

# ╔═╡ cd4fe1e2-5cbb-11eb-392d-37cd89200e04
md"""
__Author__: Kristjan Laht, B59990
"""

# ╔═╡ e0f2ceba-5cba-11eb-1f14-ad4ef1619c20
md"""
# Functions in physics
1. In the figure below you see a graph of some function. It is a square function.
"""

# ╔═╡ b9290aee-5cba-11eb-16e7-c92402c6f6b8
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

# ╔═╡ cc76810a-5cba-11eb-3784-e9ccb5bc8ce2
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

# ╔═╡ ccc56cde-5cba-11eb-0601-bf2f29d0639a
md"""

### 4. Property of Nature

The square function describes the concept of compound growth. How even a linearly changing variable, when summed up over time, changes polynominally. This can happen when measuring speed and the jerk increases linearly. 

"""

# ╔═╡ ccf312c4-5cba-11eb-24dc-c53f2185596b
square(a,x,c) = a*x^2 + x;

# ╔═╡ 282bfa7a-5cbb-11eb-3e20-818cbc5cadbb
@bind j Slider(2:50, show_value=true)

# ╔═╡ 72d21bfc-5cd1-11eb-2a88-5b7e0e16a951
@bind v_0 Slider(0:50, show_value=true)

# ╔═╡ 327c1456-5cbb-11eb-2537-29ee89edf2be
@bind s_0 Slider(-500:500, show_value=true);

# ╔═╡ 2aa87dd4-5cbb-11eb-3465-fbfff6973a43
x = 0:1:50;

# ╔═╡ e42deb9e-5cba-11eb-05bc-f99846852e79
begin
	plot(x,square.(j, x, v_0), xlabel="t (second)", ylabel="v (m/s)", label="v(t)")
	plot!([0], [v_0], seriestype = :scatter, label="v₀")
end

# ╔═╡ 687a0c52-5cbb-11eb-3b69-d3f0ba61397d
md"""
# Second function
#### 1. 
In the figure below you see a graph of some function. It is an exponential decay function.
"""

# ╔═╡ 47a12e5c-5cc3-11eb-38c0-13546d4e6b2a
md"""
### 3. Derivative

The derivative of the discharge function is:

$$\frac{dV}{dt} = -\frac{V_0}{RC} e^{ \frac{-t}{RC}}$$

Which, if we move the $$C$$ to the other side, gets us the __current__ in the capacitor:

$$I(t) = C \frac{dV}{dt} = -\frac{V_0}{R} e^{\frac{-t}{RC}}$$

This only makes sense with regards to positive time t ∈ (0;∞) and positive voltage V ∈ (0;∞).

"""

# ╔═╡ d9b2a2f6-5da5-11eb-137a-1b28fc1e8851
md"""
### 4. Property of Nature

The energy stored inside a charged capactitor is potential energy. That is, it only exists as a relation to some other state (a discharged capacitor, perhaps). An ideal capacitor can be modeled with a constant *capacitance* $$C = \frac{Q}{V}$$. Therefore the voltage at any single time point is $$V(t) = \frac{Q(t)}{C}$$. That is, the voltage is linearly related to the charge stored inside the capacitor. Since the energy stored is potential energy, by way of positive charge on one plate and negative charge on the other plate, that energy/charge "wants" to settle back down onto a balanced equilibrium. The size of that "want" is proportional to how much imbalance there is.

That means that the discharge starts out fast, but slows down as the amount of imbalance drops off. 
"""

# ╔═╡ 83c2566e-5cbd-11eb-073f-1d4a3d5518b8
exponential_decay(A, b, x) = A / exp(b*x)

# ╔═╡ 444988e0-5cbf-11eb-2406-f169032118cf
@bind V_0 Slider(0.2:0.2:4, show_value=true, default=3.4)

# ╔═╡ 5925a4d6-5cbf-11eb-3eeb-53518a7955eb
@bind RC Slider(0.2:0.2:10, show_value=true, default=5)

# ╔═╡ 68c1c22c-5cbb-11eb-3eb0-330e89f3f39d
begin
	plot(x, exponential_decay.(V_0, 1/RC, x), ylabel="V (volt)", xlabel="t (second)", label="V₀ e^(-t/RC)")
	plot!([0], [V_0], seriestype = :scatter, label="V₀")
end

# ╔═╡ a3077b76-5cc4-11eb-040f-251e086b20e3
RC_circuit_url = "https://upload.wikimedia.org/wikipedia/commons/a/a4/Discharging_capacitor.svg"

# ╔═╡ 1a449718-5cc1-11eb-1946-f114a25dc73d
md"""
### 2. Physical example
An example of exponential decay is the voltage of a simple __resistor-capacitor__ circuit, where the capacitor starts out charged and once the circuit is closed, the capacitor discharges its energy through the resistor. 

$(Resource(RC_circuit_url, :width => 150))

$$V(t) = \frac{V_0}{ e^{\frac{t}{RC}}}$$


* __V(t)__ - function of voltage (V) over time (t)
* __V₀__ - voltage of capacitor at t = 0
* __t__ - time (in seconds)
* __R__ - resistance of resistor (in Ω)
* __C__ - capacitance of capaciotr (in farads)
* __e__ - the base of the natural logarithm

RC is the __exponential time constant__ τ.

"""

# ╔═╡ Cell order:
# ╟─f4653ca6-5cba-11eb-0935-4d963ea430c8
# ╟─cd4fe1e2-5cbb-11eb-392d-37cd89200e04
# ╟─e0f2ceba-5cba-11eb-1f14-ad4ef1619c20
# ╠═e42deb9e-5cba-11eb-05bc-f99846852e79
# ╟─b9290aee-5cba-11eb-16e7-c92402c6f6b8
# ╟─cc76810a-5cba-11eb-3784-e9ccb5bc8ce2
# ╟─ccc56cde-5cba-11eb-0601-bf2f29d0639a
# ╠═ccf312c4-5cba-11eb-24dc-c53f2185596b
# ╠═282bfa7a-5cbb-11eb-3e20-818cbc5cadbb
# ╠═72d21bfc-5cd1-11eb-2a88-5b7e0e16a951
# ╟─327c1456-5cbb-11eb-2537-29ee89edf2be
# ╠═2aa87dd4-5cbb-11eb-3465-fbfff6973a43
# ╟─687a0c52-5cbb-11eb-3b69-d3f0ba61397d
# ╠═68c1c22c-5cbb-11eb-3eb0-330e89f3f39d
# ╟─1a449718-5cc1-11eb-1946-f114a25dc73d
# ╟─47a12e5c-5cc3-11eb-38c0-13546d4e6b2a
# ╟─d9b2a2f6-5da5-11eb-137a-1b28fc1e8851
# ╠═83c2566e-5cbd-11eb-073f-1d4a3d5518b8
# ╠═444988e0-5cbf-11eb-2406-f169032118cf
# ╠═5925a4d6-5cbf-11eb-3eeb-53518a7955eb
# ╟─a3077b76-5cc4-11eb-040f-251e086b20e3
