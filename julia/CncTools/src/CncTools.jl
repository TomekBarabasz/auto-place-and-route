module CncTools

include("geometry.jl")
include("svg.jl")
include("poly.jl")
include("utils.jl")

# from geometry
export  Point, PointF32, Line, LineF32, Curve, CurveF32,
        midpoint, normalize, perpendicular, distance,
        subdivide,flatten,flattenr

# from utils
export Utils

# from svg
export SVG
parse_svg_path = SVG.parse_path
read_svg_paths = SVG.read_paths
export parse_svg_path, read_svg_paths

# from poly
offset_polyline = Poly.offset_polyline
remove_duplicate_points = Poly.remove_duplicate_points
export offset_polyline, remove_duplicate_points

end # module CncTools
