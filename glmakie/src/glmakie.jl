module glmakie

using GLMakie
using Chain
using DelimitedFiles

fig = Figure()

menu = Menu(fig, options = ["viridis", "heat", "blues"])

funcs = [sqrt, x->x^2, sin, cos]

menu2 = Menu(fig, options = zip(["Square Root", "Square", "Sine", "Cosine"], funcs))

mouse_pos_str = Observable{String}("1,1")
keys_pressed_str = Observable{String}("")

fig[1, 1] = vgrid!(
    Label(fig, "Colormap", width = nothing),
    menu,
    Label(fig, "Function", width = nothing),
    menu2, 
    Label(fig, mouse_pos_str, width = nothing), 
    Label(fig, keys_pressed_str, width = nothing);
    tellheight = false, width = 200)

ax = Axis(fig[1, 2])

func = Observable{Any}(funcs[1])

ys = lift(func) do f
    f.(0:0.1:10)
end
scat = scatter!(ax, ys, markersize = 10px, color = ys)

cb = Colorbar(fig[1, 3], scat)

on(menu.selection) do s
    scat.colormap = s
end

on(menu2.selection) do s
    func[] = s
    autolimits!(ax)
end

menu2.is_open = true

o1 = on(events(fig).mouseposition, priority = 0) do event
    mouse_pos_str[] = string(event)
end

o2 = on(events(fig).keyboardbutton) do event
    keys_pressed_str[] = string(event.key)
end

fig

end # module
