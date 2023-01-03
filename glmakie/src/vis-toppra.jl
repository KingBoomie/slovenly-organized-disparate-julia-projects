module toppra

using GLMakie
using Chain
using DelimitedFiles
using SmoothingSplines

scene = Scene()
path = readdlm("/home/kris/dev/yanu-workspace/src/robobar/toppra_trajectory/src/path.csv", ',', Float64)

##
path_points = Vector{Point3f}(undef, size(path, 1))
for i in 1:size(path, 1)
    path_points[i] = Point3f(path[i, 1], path[i, 2], path[i, 3])
end

dirs = map(p -> Quaternion(p[4], p[5], p[6], p[7]) * Point3f(1, 1, 1) .* 0.005 , eachrow(path))

spl = fit(SmoothingSpline, path[:, 1], path[:, 2], 250.0)
Ypred = predict(spl)

spl2 = fit(SmoothingSpline, path[:, 1], path[:, 3], 250.0)
Zpred = predict(spl2)

begin
    f = Figure()
    a = Axis3(f[1,1], viewmode=:fit)
	lines!(a, path[:, 1], path[:, 2], path[:, 3])
    # lines!(a, path[:, 1], Ypred, Zpred)

	scatter!(a, [path[1, 1:3]...])
    #arrows!(path_points[1:10:end], dirs[1:10:end]; linewidth = 0.02, arrowsize = Vec3f(0.02, 0.02, 0.03), align = :center, linecolor = :gray) 
    DataInspector(f)
    # Camera3D(scene)
    # update_cam!(scene)
	f
end

points = [
    Point3f(0, -0.6, 0),

]

end # module
