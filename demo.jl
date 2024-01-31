#!/usr/bin/env -S julia -t auto --gcthreads 3

using Base.Threads: @threads
using ResultTypes: @try
using Maybe: @?
using Pipe: @pipe
using DataFrames, CSV, MD5, JuliaFormatter, Revise

using BHasher

# workflow
# Constants that will be outsourced to command line arguments
const manifest_path::String = "sandbox/test_manifest.txt"

manifest_df = @try read_manifest(manifest_path)
run_prechecks(manifest_df)

# check files
@try check_all_files(manifest_df)
