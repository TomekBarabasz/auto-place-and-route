module Poly

export make_cnc_path,remove_duplicate_points,make_cnc_drill_path

if !isdefined(Main, :Bezier)
    include("Bezier.jl")
end
using ..Bezier  # Use parent scope (Main.Bezier)
using DataStructures
cast(value::Number, ::Type{T}) where T<:Number = T(value)::T

function offset_polyline_simple(points::Vector{Point{T}}, distance) where T <: AbstractFloat
    n = length(points)
    n < 2 && return points

    offset_points = Point{T}[]

    for i in 1:n
        if i == 1
            # First point
            dir = normalize(points[i+1] - points[i])
        elseif i == n
            # Last point
            dir = normalize(points[i] - points[i-1])
        else
            # Middle points - average direction
            dir1 = normalize(points[i] - points[i-1])
            dir2 = normalize(points[i+1] - points[i])
            dir = normalize(dir1 + dir2)
        end
        
        perp = perpendicular(dir)
        push!(offset_points, points[i] + perp * T(distance))
    end

    offset_points
end

function offset_polyline(points::Vector{Point{T}}, distance_) where T <: AbstractFloat
    n = length(points)
    n < 2 && return points

    offset_points = Point{T}[]
    distance = T(distance_)

    for i in 1:n
        # Get previous, current, and next points
        prev_pt = i > 1 ? points[i-1] : points[i]
        curr_pt = points[i]
        next_pt = i < n ? points[i+1] : points[i]
        
        # Calculate offset direction at current point
        if i == 1
            # First point: use direction to next point
            dir = normalize(next_pt - curr_pt)
            perp = perpendicular(dir)
            offset_pt = curr_pt + perp * distance
        elseif i == n
            # Last point: use direction from previous point
            dir = normalize(curr_pt - prev_pt)
            perp = perpendicular(dir)
            offset_pt = curr_pt + perp * distance
        else
            # Middle points: bisector method
            # Direction vectors
            dir1 = normalize(curr_pt - prev_pt)
            dir2 = normalize(next_pt - curr_pt)
            
            # Perpendicular vectors (pointing right)
            perp1 = perpendicular(dir1)
            perp2 = perpendicular(dir2)
            
            # Bisector (average of perpendiculars)
            bisector = normalize(perp1 + perp2)
            
            # Calculate miter length
            # The offset distance needs to be adjusted by the angle
            cos_half_angle = perp1.x * bisector.x + perp1.y * bisector.y  # dot product
            
            # Avoid division by zero for sharp angles
            if abs(cos_half_angle) > T(0.01)
                miter_length = distance / cos_half_angle
                # Limit miter length to avoid extremely long offsets at sharp angles
                max_miter = distance * T(10)
                miter_length = clamp(miter_length, -max_miter, max_miter)
                offset_pt = curr_pt + bisector * miter_length
            else
                # For very sharp angles, fall back to simple perpendicular offset
                offset_pt = curr_pt + perp1 * distance
            end
        end
        
        push!(offset_points, offset_pt)
    end

    offset_points
end

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

# this requires cw Point order
function make_cnc_path(points::Vector{Point{T}}, tool_dia, max_error) where T <: AbstractFloat
    perp(p1::Point{T},p2::Point{T}) where T = p1-p2|>normalize|>perpendicular
    tool_path = Vector{Point{T}}()
    r = cast(tool_dia,T)
    step_a = 2 * acos( (r - max_error) / r )
    thr_cosa = cos(step_a)
    Nₚᵣₑᵥ = perp(points[begin+1],points[begin])
    push!(tool_path, points[begin] + Nₚᵣₑᵥ * r)
    for i in 2:length(points)-1
        N = perp(points[i+1],points[i])
        cosa = Bezier.dot(Nₚᵣₑᵥ , N)
        convex = Bezier.vdot(Nₚᵣₑᵥ , N) < 0
        if convex
            push!(tool_path, points[i] + Nₚᵣₑᵥ * r)
            if cosa < thr_cosa
                a_end = acos(cosa)
                n_steps = cast(round(a_end / step_a),Int)
                a = a_end / n_steps
                n = Bezier.copy(Nₚᵣₑᵥ)
                for _ in 1:n_steps-1
                    n = Bezier.rot(n,a)
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

function make_cnc_drill_path(points::Vector{PointF32}, tool_dia, max_error, overlap, n_limit_pts=nothing)
    perp(p1::Point{T},p2::Point{T}) = p1-p2|>normalize|>perpendicular
    tool_path = Vector{Point{T}}()
    r = cast(tool_dia,Float32)
    step_a = 2*acos( (r - max_error) / r )
    thr_cosa = cos(step_a)
    
    if distance(points[end], points[begin]) > max_error
        Nₚᵣₑᵥ =  perp(points[end],points[begin])
        NP = length(points)
    else
        Nₚᵣₑᵥ = perp(points[end-1],points[begin])
        NP = length(points)-1
    end
    
    pts = Deque{Point{T}}()
    for i in 1:NP
        push!(pts,points[i])
    end

    while length(pts) > 1
        Pt = popfirst!(pts)
        Ptₙₑₓₜ = first(pts)
        if distance(Pt,Ptₙₑₓₜ) < max_error
            break
        end
        N = perp(Pt, Ptₙₑₓₜ)
        cosa = Bezier.dot(Nₚᵣₑᵥ , N)
        convex = Bezier.vdot(Nₚᵣₑᵥ , N) > 0
        if convex
            push!(tool_path, Pt + Nₚᵣₑᵥ * r)
            if cosa < thr_cosa
                a_end = acos(cosa)
                n_steps = cast(round(a_end / step_a),Int)
                a = - a_end / n_steps
                n = Bezier.copy(Nₚᵣₑᵥ)
                for _ in 1:n_steps-1
                    n = Bezier.rot(n,a)
                    P1 = Pt + n * r
                    push!(tool_path, P1)
                    push!(pts,P1)
                end
            end
            P1 = Pt + N * r
            push!(tool_path, P1)
            push!(pts,P1)
        else
            a2 = acos(cosa) / 2
            n = Nₚᵣₑᵥ + N |> normalize
            P1 = Pt + n * Float32(r / cos(a2))
            push!(tool_path, P1)
            push!(pts,P1)
        end
        Nₚᵣₑᵥ = N
        Ptₚᵣₑᵥ = Pt

        if n_limit_pts ≠ nothing && length(tool_path) > n_limit_pts
            break
        end

        if length(tool_path) == NP
            r *= (1.0 - overlap)
        end
    end
    tool_path
end

end #module