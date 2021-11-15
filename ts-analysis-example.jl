### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ 7f583ea2-f14f-11eb-3f1a-df193d312557
begin
	using Pkg
	Pkg.activate()
end

# ╔═╡ 4ba5f862-0e30-4a37-9dba-a47c4426e552
begin
	Pkg.develop("TSAnalysis")
	using Dates, DataFrames, LinearAlgebra, FredData, Optim, Plots, Measures;
	using TSAnalysis;
	plotlyjs();
	fred = Fred("6d4cdbed05fa2d25c171e82d73c77e64");
end

# ╔═╡ 6f90864a-1d27-45f6-8a1a-73df7442b952
"""
    download_fred_vintage(tickers::Array{String,1}, transformations::Array{String,1})

Download multivariate data from FRED2.
"""
function download_fred_vintage(tickers::Array{String,1}, transformations::Array{String,1})

    # Initialise output
    output_data = DataFrame();

    # Loop over tickers
    for i=1:length(tickers)

        # Download from FRED2
        fred_data = get_data(fred, tickers[i], observation_start="1984-01-01", units=transformations[i]).data[:, [:date, :value]];
        rename!(fred_data, Symbol.(["date", tickers[i]]));

        # Store current vintage
        if i == 1
            output_data = copy(fred_data);
        else
            output_data = join(output_data, fred_data, on=:date, kind = :outer);
        end
    end

    # Return output
    return output_data;
end

# ╔═╡ 9487ce4c-7093-4e7b-8371-c8ebc27e620f
begin
	# Download data of interest
	Y_df = download_fred_vintage(["INDPRO"], ["log"]);
	
	# Convert to JArray{Float64}
	Y = Y_df[:,2:end] |> JArray{Float64};
	Y = permutedims(Y);
end

# ╔═╡ 60c09cf6-fbde-4298-b5f6-a2fafec2e679
names(TSAnalysis)

# ╔═╡ 11904f9f-1004-4635-b6e2-f09ea3d042bb
TSAnalysis

# ╔═╡ 886a4bfb-bd85-42ae-99c5-e8d4e8b49620
begin
	d = 2;
	p = 20;
	q = 7;
	arima_settings = ARIMASettings(Y, d, p, q);
	
	# Estimation
	arima_out = arima(arima_settings, NelderMead(), Optim.Options(iterations=10000, f_tol=1e-2, x_tol=1e-2, g_tol=1e-2, show_trace=true, show_every=500));
end

# ╔═╡ 81485459-b72d-407f-be69-7edd60874e7b
begin
	max_hz = 100;
	fc = forecast(arima_out, max_hz, arima_settings);
end

# ╔═╡ cf73fad4-197b-4fd3-895b-844fb61ce6d5
begin
	# Extend date vector
	date_ext = Y_df[!,:date] |> Array{Date,1};
	
	for hz=1:max_hz
	    last_month = month(date_ext[end]);
	    last_year = year(date_ext[end]);
	
	    if last_month == 12
	        last_month = 1;
	        last_year += 1;
	    else
	        last_month += 1;
	    end
	
	    push!(date_ext, Date("01/$(last_month)/$(last_year)", "dd/mm/yyyy"))
	end
	
	my_font = font(8, "Helvetica Neue")
	
	# Generate plot
	p_arima = plot(date_ext, [Y[1,:]; NaN*ones(max_hz)], label="Data", color=RGB(0,0,200/255),
	               xtickfont=my_font, ytickfont=my_font,
	               title="INDPRO", titlefont=my_font, framestyle=:box,
	               legend=:right, size=(800,250), dpi=300, margin = 5mm);
	
	plot!(date_ext, [NaN*ones(length(date_ext)-size(fc,2)); fc[1,:]], label="Forecast", color=RGB(0,0,200/255), line=:dot)
end

# ╔═╡ Cell order:
# ╠═7f583ea2-f14f-11eb-3f1a-df193d312557
# ╠═4ba5f862-0e30-4a37-9dba-a47c4426e552
# ╠═6f90864a-1d27-45f6-8a1a-73df7442b952
# ╠═9487ce4c-7093-4e7b-8371-c8ebc27e620f
# ╠═60c09cf6-fbde-4298-b5f6-a2fafec2e679
# ╠═11904f9f-1004-4635-b6e2-f09ea3d042bb
# ╠═886a4bfb-bd85-42ae-99c5-e8d4e8b49620
# ╠═81485459-b72d-407f-be69-7edd60874e7b
# ╠═cf73fad4-197b-4fd3-895b-844fb61ce6d5
