module Poly

using ..CncTools: Point, distance, normalize, perpendicular, vdot, dot, rotate, copy
export offset_polyline,remove_duplicate_points

using DataStructures
cast(value::Number, ::Type{T}) where T<:Number = T(value)::T

function remove_duplicate_points(points::Vector{Point{T}}, max_dist) where T <: AbstractFloat
    res = Vector{Point{T}}()
    sizehint!(res,length(points))
    push!(res,points[begin])
    for i in 2:length(points)
        d = distance(points[i-1],points[i])
        if d > max_dist
            push!(res,points[i])
        end
    end
    res
end

# assuming standard CCW orientation for points
function offset_polyline(points::Vector{Point{T}}, tool_dia, max_error) where T <: AbstractFloat
    perp(p1::Point{T},p2::Point{T}) where T = p2-p1|>normalize|>perpendicular
    tool_path = Vector{Point{T}}()
    r = cast(tool_dia,T)
    step_a = 2 * acos( (r - max_error) / r )
    thr_cosa = cos(step_a)
    Nₚᵣₑᵥ = perp(points[begin+1],points[begin])
    push!(tool_path, points[begin] + Nₚᵣₑᵥ * r)
    for i in 2:length(points)-1
        N = perp(points[i+1],points[i])
        cosa = dot(Nₚᵣₑᵥ , N)
        convex = vdot(Nₚᵣₑᵥ , N) > 0
        if convex
            push!(tool_path, points[i] + Nₚᵣₑᵥ * r)
            if cosa < thr_cosa
                a_end = acos(cosa)
                n_steps = cast(round(a_end / step_a),Int)
                a = a_end / n_steps
                n = copy(Nₚᵣₑᵥ)
                for _ in 1:n_steps-1
                    n = rotate(n,a)
                    push!(tool_path, points[i] + n * r)
                end
            end
            push!(tool_path, points[i] + N * r)
        else
            a2 = acos(cosa) / 2
            n = Nₚᵣₑᵥ + N |> normalize
            push!(tool_path, points[i] + n * Float32(r / cos(a2)))
        end
        Nₚᵣₑᵥ = N
    end
    push!(tool_path, points[end] + Nₚᵣₑᵥ * r)
    tool_path
end

end # module Poly
