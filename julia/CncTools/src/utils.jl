module Utils

using ..CncTools: Point
export make_test_shape, make_test_shapes

function make_test_shape(T::Type{<:Number}, name)
    Pt = Point{T}
    if name == "square"
        ret = [Pt(0,0),Pt(0,1),Pt(1,1),Pt(1,0), Pt(0,0)]
    elseif name == "square-2"
        ret = [Pt(0,0),Pt(0.5,0),Pt(1,0),Pt(1,-0.5), Pt(1,-1), Pt(0.5,-1),Pt(0,-1),Pt(0,-0.5),Pt(0,0)]
    elseif name == "star"
        ret = [Pt(0,0),Pt(3,1),Pt(4,4),Pt(5,1),Pt(8,0),Pt(5,-1),Pt(4,-4),Pt(3,-1),Pt(0,0)]
    elseif name == "butterfly"
        ret = [Pt(0,0),Pt(0,3),Pt(2,4),Pt(0,5),Pt(0,8),Pt(3,8),Pt(4,6),Pt(5,8),Pt(8,8),
               Pt(8,5),Pt(6,4),Pt(8,3),Pt(8,0),Pt(5,0),Pt(4,2),Pt(3,0),Pt(0,0)]
    elseif name == "hex"
        ret = [Pt(0,1),Pt(0,3),Pt(1,4),Pt(3,4),Pt(4,3),Pt(4,1),Pt(3,0),Pt(1,0),Pt(0,1)]
    else
        ret = nothing
    end
    ret |> reverse
end

function make_test_shapes(T::Type{<:Number})
    Dict{String, Vector{Point{T}}}(n => make_test_shape(T,n) for n in ["square", "star", "butterfly", "hex"])
end

end # module Utils