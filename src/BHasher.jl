module BHasher

using Base.Threads: @threads
using ResultTypes: @try
using Maybe: @?
using Pipe: @pipe
using DataFrames, CSV, MD5, JuliaFormatter, Revise

export read_manifest, run_prechecks, check_all_files

"""
read the provided md5 manifest
"""
function read_manifest(manifest_path::String, delimiter::String)
    manifest = @pipe CSV.read(
        manifest_path,
        DataFrame;
        header = false,
        delim = delimiter,
        stripwhitespace = true,
        stringtype = String,
    ) |> rename(_, [:old_hash, :file])
    return manifest
end

"""
verify that provided hashes are all the same length
"""
function check_hashes(manifest::DataFrame)
    uniq_lens = @pipe manifest[!, 1] |> length.(_) |> unique |> length
    if uniq_lens == 1
        return true
    end
    return false
end

"""
check that the files exist
"""
function check_file_existence(manifest_df::DataFrame)
    test_vec = Vector{Bool}(undef, nrow(manifest_df))
    files = manifest_df[!, 2]
    for (i, file) in enumerate(files)
        @inbounds test_vec[i] = !isfile(file)
    end
    missing_files = manifest_df[test_vec, 2]
    if length(missing_files) > 0
        println(
            "The following files in the manifest are missing in the current directory:\n$missing_files",
        )
        # exit(1)
    else
        println(
            "All files listed in the manifest exist and are ready to be checked.",
        )
    end
end

"""
"""
function run_prechecks(manifest_df::DataFrame)
    @try check_hashes(manifest_df)
    @try check_file_existence(manifest_df)
    return println("All checks passed.")
end

"""
"""
function generate_hash(file::T) where {T <: String}
    hash = open(MD5.md5, file) |> bytes2hex
    return hash
end

"""
"""
function check_all_files(manifest_df::DataFrame)

    # generate vector to store new hashes
    new_hashes = Vector{String}(undef, nrow(manifest_df))

    # Check all files in parallel
    @threads for i in eachindex(manifest_df[!, 2])
        @inbounds file = manifest_df[i, 2]
        hash = @try generate_hash(file)
        @inbounds new_hashes[i] = hash
        println("Finished generating new hash for file $file")
    end
    manifest_df.new_hash = new_hashes

    # collect names of any files that need to be retransferred
    to_retransfer = [
        row.file for row in eachrow(manifest_df) if row.old_hash != row.new_hash
    ]

    # Print an informative message if any files failed the checks
    if length(to_retransfer) > 0
        println(
            "The following files failed the checksum and should be transferred:\n$to_retransfer",
        )
        exit(1)
    end

    return println("All files passed MD5 checks. Goodbye.")
end

end # module BHasher
