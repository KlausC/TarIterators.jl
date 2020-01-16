# TarIterators.jl

[![Build Status](https://travis-ci.org/JuliaLang/TarIterators.jl.svg?branch=master)](https://travis-ci.org/JuliaLang/TarIterators.jl)
[![Codecov](https://codecov.io/gh/JuliaLang/TarIterators.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaLang/TarIterators.jl)

The `TarIterators` package can read from individual elements of POSIX TAR archives ("tarballs") as specified in [POSIX 1003.1-2001](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/pax.html).

## Design & Features

### File Types

### Time Stamps

### Users & Groups

### Permissions

### Reproducibility

## API & Usage

The public API of `Tar` includes three functions and one type:

* `open` — creates a tarball from an on-disk file tree
* `iterate` — extracts a tarball to an on-disk file tree
* `TarIterator` — struct representing a file stream opened for reading a TAR file  

### Usage Example

```julia
    using TarIterators

    for (h, io) in Tar.Iterator("/tmp/AB.tar.gz")
        if h.type == :file
            x = read(io)
            ...
        end
        close(io)
    end

    using CodecZlib
    io = GzipDecompressorStream(open("/tmp/AB.tar.gz"))

    # process first file according to filter criteria
    open(Tar.Iterator(io, "B", close_stream=true) do tio
        x = read(tio, 10)
        ...
    end
    # `io` is closed together with `tio`

```
<!-- BEGIN: copied from inline doc strings -->

<!-- END: copied from inline doc strings -->
