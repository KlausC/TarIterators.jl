
using Test
using TarIterators
using .BoundedStreams
using Tar
using CodecZlib

@testset "BoundedStreams" begin include("boundedstreams.jl"); end
@testset "TarIterators" begin include("tariterators.jl"); end

