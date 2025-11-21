using GLMakie

function plot_polyline(points)
    xs, ys = [p.x for p in points], [p.y for p in points]
    fig = Figure()
    ax = Axis(fig[1, 1], aspect = DataAspect())
    lines!(ax, xs, ys)
    scatter!(ax, xs, ys, markersize = 5)
    wait(display(fig))
end

function plot_polylines(polys...)
    fig = Figure()
    ax = Axis(fig[1, 1], aspect = DataAspect())
    for (poly,color) in zip(polys,[:red,:blue,:green])
        xs, ys = [p.x for p in poly], [p.y for p in poly]
        lines!(ax, xs, ys, color = color)
        scatter!(ax, xs, ys, markersize = 5, color = color)
    end
    wait(display(fig))
end
