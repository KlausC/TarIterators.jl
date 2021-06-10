# TarIterators.jl

[![Build Status][gha-img]][gha-url]     [![Coverage Status][codecov-img]][codecov-url]

The `TarIterators` package can read from individual elements of POSIX TAR archives ("tarballs") as specified in [POSIX 1003.1-2001](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/pax.html).

## API & Usage

The public API of `TarIterators` includes only standard functions and one type:

* `TarIterator` — struct representing a file stream opened for reading a TAR file, may be restricted by predicates

* `iterate` — deliver pairs of `Tar.header` and `BoundedInputStream` for each element

* `close` - close wrapped stream
* `open`  - deliver `BoundedInputStream` for the next element of tar file or process all elements in a loop
* `seekstart` - reset input to start

### Usage Example

```julia

    using TarIterators

    ti = TarIterator("/tmp/AB.tar", :file)
    for (h, io) in ti
        x = read(io, String)
        println(x)
    end

    # reset to start
    seekstart(ti)

    # or equivalently
    open(ti) do h, io
        x = read(io, String)
        println(x)
    end

    using CodecZlib
    cio = GzipDecompressorStream(open("/tmp/AB.tar.gz"))

    # process first file named "B"
    io = open(TarIterator(cio, "B", close_stream=true))
    x = read(io, 10)
    close(io) # cio is closed implicitly
```

[gha-img]: https://github.com/KlausC/TarIterators.jl/workflows/CI/badge.svg
[gha-url]: https://github.com/KlausC/TarIterators.jl/actions?query=workflow%3ACI
[codecov-img]: https://codecov.io/gh/KlausC/TarIterators.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/KlausC/TarIterators.jl
