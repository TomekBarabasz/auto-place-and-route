module SVG

export parse_path, read_paths

using LightXML

include("geometry.jl")

function read_paths(filename)    
    paths = Dict{String, String}()

    # Parse the XML file
    xdoc = parse_file(filename)
    root = LightXML.root(xdoc)

    function find_paths(element)
        # Check if current element is a path
        if LightXML.name(element) == "path"
            pid = attribute(element, "id")
            d_attr = attribute(element, "d")
            
            if !isnothing(d_attr) && !isempty(d_attr) && !isnothing(pid)
                paths[pid] = d_attr
            end
        end
        
        # Recursively check children
        for child in child_elements(element)
            find_paths(child)
        end
    end
    
    # Start recursive search from root
    find_paths(root)

    # Clean up
    free(xdoc)

    paths
end

function tokenize_path(d::String)
    tokens = String[]
    
    # Replace command letters with space + letter + space for easy splitting
    s = d
    for cmd in ['M', 'm', 'L', 'l', 'C', 'c', 'Z', 'z']
        s = replace(s, cmd => " $cmd ")
    end
    
    # Replace commas with spaces
    s = replace(s, ',' => ' ')
    
    # Split by whitespace and filter empty strings
    raw_tokens = split(s)
    tokens = filter(!isempty, raw_tokens)
    
    return tokens
end

mutable struct TokenIterator
    tokens::Vector{SubString{String}}
    pos::Int
end

TokenIterator(tokens) = TokenIterator(tokens,1)

tokens_left(iter::TokenIterator) = iter.pos < length(iter.tokens)

get_one_token!(iter::TokenIterator) = (tok = iter.tokens[iter.pos]; iter.pos += 1; tok)
peek_next_token(iter::TokenIterator) = iter.tokens[iter.pos]

function parse_path(::Type{T}, path::String) where T<:AbstractFloat
    Pt = Point{T}
    curves = Curve{T}[]
    
    # Current position
    current = Pt(0.0, 0.0)
    # Start of current subpath (for Z command)
    subpath_start = Pt(0.0, 0.0)
    
    # Tokenize the path string
    iter = TokenIterator(tokenize_path(path))
    
    parse_point!(iter::TokenIterator) = Pt( parse(T, get_one_token!(iter)), parse(T,get_one_token!(iter)) )
    
    cmd = nothing

    while tokens_left(iter)
        tok = peek_next_token(iter)
        if length(tok) == 1 && tok[1] ∈ "MmCcLlZz"
            cmd = get_one_token!(iter)[1]
        end

        if cmd == 'M'  # Absolute moveto
            current = parse_point!(iter)
            subpath_start = current
            
        elseif cmd == 'm'  # Relative moveto
            current = parse_point!(iter) + current
            subpath_start = current
            
        elseif cmd == 'L'  # Absolute lineto
            end_pt = parse_point!(iter)
            # Convert line to cubic bezier (control points on the line)
            push!(curves, Curve(current, current, end_pt, end_pt))
            current = end_pt
            
        elseif cmd == 'l'  # Relative lineto
            end_pt = parse_point!(iter) + current
            push!(curves, Curve(current, current, end_pt, end_pt))
            current = end_pt
            
        elseif cmd == 'C'  # Absolute cubic bezier
            c1 = parse_point!(iter)
            c2 = parse_point!(iter)
            end_pt = parse_point!(iter)
            push!(curves, Curve(current, c1, c2, end_pt))
            current = end_pt
            
        elseif cmd == 'c'  # Relative cubic bezier
            c1 = parse_point!(iter) + current
            c2 = parse_point!(iter) + current
            end_pt = parse_point!(iter) + current
            push!(curves, Curve(current, c1, c2, end_pt))
            current = end_pt
            
        elseif cmd == 'Z' || cmd == 'z'  # Close path
            if current != subpath_start
                push!(curves, Bezier(current, current, subpath_start, subpath_start))
                current = subpath_start
            end
        end
    end
    curves
end

end #module