# B-Hasher

Have lots of cores? Run lots of file checksums! Here's an example workflow, which can be run with this repo as the project root directory. First, install the required dependencies:
```
Pkg.activate(".")
```

Make sure you've started Julia with available threads, either using `julia --threads auto` or by changing the `JULIA_NUM_THREADS` environment variable.

And then, do something like this:
```julia
using Base.Threads: @threads
using ResultTypes: @try
using Maybe: @?
using Pipe: @pipe
using DataFrames, CSV, MD5, JuliaFormatter, Revise

using BHasher

# workflow
# Constants that will be outsourced to command line arguments
const manifest_path::String = "path/to/your/transfer_manifest.txt"
const delimiter::String = "  "

manifest_df = @try read_manifest(manifest_path, delimiter)
run_prechecks(manifest_df)

# check files
@try check_all_files(manifest_df)
```

Note that the package assumes your transfer manifest has two, unnamed columns, the first being md5 hashes, and the second being the file names or paths.
