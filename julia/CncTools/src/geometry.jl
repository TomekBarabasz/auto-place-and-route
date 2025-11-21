import Base: +,-,*,/

struct Point{T<:AbstractFloat}
    x::Float32
    y::Float32
end

+(p1::Point{T}, p2::Point{T}) where T = Point{T}(p1.x + p2.x, p1.y + p2.y)
-(p1::Point{T}, p2::Point{T}) where T = Point{T}(p1.x - p2.x, p1.y - p2.y)
*(p1::Point{T}, scale::T) where T = Point{T}(p1.x * scale, p1.y * scale)
/(p1::Point{T}, scale::T) where T = Point{T}(p1.x / scale, p1.y / scale)
midpoint(p1::Point{T}, p2::Point{T}) where T = (p1 + p2) / T(2)
normalize(p::Point{T}) where T = (len = hypot(p.x, p.y); len != 0 ? p / len : Point{T}(0, 0))
perpendicular(p::Point{T}) where T = Point{T}(-p.y, p.x)
dot(a::Point{T}, b::Point{T}) where T = a.x*b.x + a.y*b.y
copy(p::Point{T}) where T = Point{T}(p.x,p.y)
vdot(a::Point{T},b::Point{T}) where T = a.x * b.y - a.y *b.x
function rotate(p::Point{T}, angle::Real) where T
    cos_a = cos(angle)
    sin_a = sin(angle)
    Point{T}(p.x * cos_a - p.y * sin_a, p.x * sin_a + p.y * cos_a)
end

struct Line{T<:AbstractFloat}
    start_pt::Point{T}
    end_pt::Point{T}
end

function distance(p1::Point{T}, p2::Point{T}) where T
    hypot(p2.x - p1.x, p2.y - p1.y)
end

function distance(p::Point{T}, line::Line{T}) where T
    x0,y0 = p.x, p.y
    x1,y1 = line.start_pt.x, line.start_pt.y
    x2,y2 = line.end_pt.x, line.end_pt.y
    num = abs((y2 - y1) * x0 - (x2 - x1) * y0 + x2*y1 - y2*x1)
    den = hypot(x2 - x1, y2 - y1)
    den != 0 ? T(num / den) : T(0)
end

struct Curve{T<:AbstractFloat} 
    start_pt::Point{T}
    c1::Point{T}
    c2::Point{T}
    end_pt::Point{T}  # 'end' is a keyword in Julia
end

function subdivide(c::Curve{T}) where T
    p01   = midpoint(c.start_pt, c.c1)
    p12   = midpoint(c.c1, c.c2)
    p23   = midpoint(c.c2, c.end_pt)
    p012  = midpoint(p01,p12)
    p123  = midpoint(p12,p23)
    p0123 = midpoint(p012,p123)
    Curve(c.start_pt, p01, p012, p0123), Curve(p0123,p123,p23,c.end_pt)
end

function flatten(c::Curve{T}, max_error) where T
    l = Line(c.start_pt, c.end_pt)
    d1,d2 = distance(c.c1, l), distance(c.c2, l)
    if max(d1,d2) <= max_error
        [c.start_pt,c.end_pt]
    else
        left,right = subdivide(c)
        vcat(flatten(left,max_error)[begin:end-1], flatten(right,max_error))
    end
end

function flatten(vec::Vector{Curve{T}}, max_error) where T
    pts = Point{T}[]
    for c in vec
        append!(pts, flatten(c, max_error))
    end
    pts    
end

const PointF32 = Point{Float32}
const LineF32  = Line{Float32}
const CurveF32 = Curve{Float32}

