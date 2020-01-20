
using Test
using TarIterators
using BoundedStreams
using Tar
using CodecZlib

# setup test file
dir = mkpath(abspath(@__FILE__, "..", "data", "ball"))
cd(dir)
mkpath("sub")
mkpath("empty")
for (fn, size) in (("a", 10), ("b", 100), ("c", 0), ("d", 3)), sub in ("", "sub",)
    open(joinpath(sub, fn * ".dat"), "w") do io
        write(io, fn^size)
    end
end
cd(abspath(dir, ".."))
tarfile = "test.tar"
run(`sh -c "tar -cf $tarfile ball"`)
run(`sh -c "gzip <$tarfile >$tarfile.gz"`)

function opener(file::AbstractString, f=nothing; close_stream::Bool=false)
    source = open(file)
    if endswith(file, ".tar.gz") || endswith(file, ".tgz")
        source = GzipDecompressorStream(source)
    end
    TarIterator(source, f, close_stream=close_stream)
end

@testset "reading all elements of $tarfile" for tarfile = (tarfile, tarfile*".gz")
    ti = opener(tarfile)
    @test ti != nothing
    s = iterate(ti)
    @test s isa Tuple
    (h, io), st = s
    @test h isa Tar.Header
    @test io isa BoundedInputStream
    @test h.type == :directory
    @test h.path == "ball/"
    @test close(ti) == nothing
    ti = opener(tarfile)
    @test open(ti) isa BoundedInputStream
    
    seekstart(ti)
    res1 = Any[]
    for (h, io) in ti
        push!(res1, h)
        push!(res1, read(io, String))
    end
    @test !eof(ti.stream)
    @test length(res1) == 22

    seekstart(ti)
    res2 = Any[]
    open(ti) do h, io
        push!(res2, h)
        push!(res2, read(io, String))
    end
    @test length(res2) == 22
    @test res1 == res2
end


@testset "iterations predicate $p" for (p,m) in ((nothing,11),
                                                 ("ball/b.dat", 1),
                                                 (r"^ball/(|.*/)a\.dat",2),
                                                 (:file,8),
                                                 (h->h.type == :file, 8))
    n = 0
    open(TarIterator(tarfile, p)) do h, io
        n += 1
    end
    @test n == m
end
