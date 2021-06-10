module TarIterators

export TarIterator

using Tar
using BoundedStreams

   
struct TarIterator{T,F<:Function}
    stream::T
    filter::F
    closestream::Bool
end

"""
    TarIterator(io[, predicate])

Iterator over an input stream open for reading. `io` may also be pathname of an existing 
tar file. The data in the stream or file must obey the `tar` file format understood by
package `Tar`.

If `predicate` is given, only tar elements with matching header data are processed.
* `String` or `Regex`: `predicate` is applied to the element names.
* `Symbol`: it must coincide with field `type` of `Tar.Header`.
* boolean function: it is applied to the `Tar.Header` of the elements.
* `Tuple`: AND of all predicates contained in tuple
* `Vector`: OR of all predicates contained in vector

Examples:
```
    io = open("/tmp/abc.tar") 
    TarIterator(io)              # all entries 
    TarIterator(io, :file)       # all entries of file type 
    TarIterator(io, "y")         # only entry with name "y" 
    TarIterator(io, r".*[.]txt") # all entries with name ending in ".txt"
    TarIterator(io, h -> h.size > 100) # only entries with data size > 100
```
"""
function TarIterator(source::T, a::F=nothing; close_stream::Bool=false) where {T,F}
    TarIterator(source, selector(a), close_stream)
end
function TarIterator(file::AbstractString, f=nothing; close_stream::Bool=false)
    TarIterator(open(file), f, close_stream=close_stream)
end

function Base.iterate(ti::TarIterator, status=nothing)
    stream = ti.stream
    status !== nothing && close(status)
    h = Tar.read_header(stream)
    while h !== nothing
        s = align(h.size)
        if ti.filter(h)
            closeop = ti.closestream ? BoundedStreams.CLOSE : s
            io = BoundedInputStream(stream, h.size, close=closeop)
            return (h, io), io
        end
        skip(stream, s)
        h = Tar.read_header(stream)
    end
    nothing
end

# align to TAR block size
align(pos::Integer) = mod(-pos, 512) + pos

# predicates processing
selector(f::Function) = f
selector(a::Tuple) = function AND(h::Tar.Header)
    for f in a
        if !selector(f)(h)
            return false
        end
    end
    true
end
selector(a::AbstractVector) = function OR(h::Tar.Header)
    for f in a
        if selector(f)(h)
            return true
        end
    end
    false
end
selector(a::Union{AbstractString,Nothing,Symbol,Regex}) = h::Tar.Header -> predicate(h, a)
predicate(h::Tar.Header, ::Nothing) = true
predicate(h::Tar.Header, a::AbstractString) = h.path == a
predicate(h::Tar.Header, s::Symbol) = h.type == s
function predicate(h::Tar.Header, r::Regex)
    fn = h.path
    m = match(r, fn)
    m !== nothing && m.match == fn
end

"""
    open(ti::TarIterator)::BoundedInputStream

Skip to the first entry in tar stream according to predicates of `ti` and return
an open input stream, which allows to read data part of this entry.
"""
function Base.open(ti::TarIterator)
    s = iterate(ti)
    s === nothing && throw(EOFError())
    s[1][2]
end

"""
    open(ti::TarIterator) do h, io; ... end

Process all tar entries selected by `ti` and provide `h::Tar.Header` and
`io::BoundedInputStream` to the called function. 
"""
function Base.open(f::Function, ti::TarIterator)
    for (h, io) in ti
        f(h, io)
    end
end

Base.close(ti::TarIterator) = close(ti.stream)
Base.seekstart(ti::TarIterator) = seekstart(ti.stream)

end # module
