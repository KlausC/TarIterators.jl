
using Test
using TarIterators
using BoundedStreams
using Tar

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

@testset "reading all elements of tar file" begin
    ti = TarIterator(tarfile)
    @test ti != nothing
    s = iterate(ti)
    @test s isa Tuple
    (h, io), st = s
    @test h isa Tar.Header
    @test io isa BoundedInputStream
    @test h.type == :directory
    @test h.path == "ball/"
    @test close(ti) == nothing
    ti = TarIterator(tarfile)
    @test open(ti) isa BoundedInputStream
    
    @test seekstart(ti) === ti.stream
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


