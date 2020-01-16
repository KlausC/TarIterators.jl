module TarIterators

export TarIterator

using Tar
using BoundedStreams
using CodecZlib

"""
    TarIterator(io[, condition])

Iterator over an input stream open for reading. The data in the stream must obey
the `tar` file format understood by package `Tar`.
If `condition` is given, only tar elements with matching path name are processed.

Examples:
    io = open("/tmp/abc.tar") 
    TarIterator(io, "y")        # only entry with name "y" 
    TarIterator(io, r".*[.]txt") # only entries ending with ".txt"
    TarIterator(io, x -> x < "y") # only entries lexically before "y"
"""
struct TarIterator{T,F<:Function}
    stream::T
    filter::F
    closestream::Bool
end

function TarIterator(source::T, a::F=nothing; close_stream::Bool=false) where {T,F}
    TarIterator(source, selector(a), close_stream)
end
function TarIterator(file::AbstractString, f=nothing; close_stream::Bool=false)
    source = open(file)
    if endswith(file, ".tar.gz") || endswith(file, ".tgz")
        source = GzipDecompressorStream(source)
    end
    TarIterator(source, f, close_stream=close_stream)
end

function Base.iterate(ti::TarIterator, status=nothing)
    stream = ti.stream
    status != nothing && close(status)
    h = Tar.read_header(stream)
    while h !== nothing
        s = ((h.size - 1) >> 9 + 1) << 9 # align to 512 bytes
        if ti.filter(h)
            io = BoundedInputStream(stream, h.size, close=ti.closestream ? BoundedStreams.CLOSE : s)
            return (h, io), io
        end
        skip(stream, s)
        h = Tar.read_header(stream)
    end
    nothing
end

selector(a::Union{AbstractString,Nothing,Symbol,Regex}) = h::Tar.Header -> selected(h, a)
selector(f::Function) = f
selected(h::Tar.Header, ::Nothing) = true
selected(h::Tar.Header, a::AbstractString) = h.path == a
selected(h::Tar.Header, s::Symbol) = h.type == s
function selected(h::Tar.Header, r::Regex)
    fn = h.path
    m = match(r, fn)
    m != nothing && m.match == fn
end

function Base.open(ti::TarIterator)
    s = iterate(ti)
    s == nothing && throw(EOFError())
    s[1][2]
end

function Base.open(f::Function, ti::TarIterator)
    for (h, io) in ti
        f(h, io)
    end
end

Base.close(ti::TarIterator) = close(ti.stream)
Base.seekstart(ti::TarIterator) = seekstart(ti.stream)

end # module
