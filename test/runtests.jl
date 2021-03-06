using Test
using ASME_Materials
using ColorSchemes, DataFrames, GLMakie, Interpolations, Latexify, NativeFileDialog, PrettyTables, Term, XLSX

include("readtest.jl")
include("transformtest.jl")
include("writetest.jl")
include("plottest.jl")
include("verification.jl")
