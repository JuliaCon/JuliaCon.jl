module JuliaCon

using Base: cache_dependencies, isfile_casesensitive
import Base: show
using Distributed
using Dates: Dates, Date, DateTime, Time, Hour, Minute
using JSON
using Downloads: download
using PrettyTables
using TimerOutputs

include("countries.jl")
include("tshirtcode.jl")
include("schedule_structs.jl")
include("schedule.jl")
include("debug.jl")
include("caching.jl")

const PRETALX_JSON_URL = "https://pretalx.com/juliacon2020/schedule/export/schedule.json"
const DATA_ARCHIVE_JSON_URL = "https://raw.githubusercontent.com/JuliaCon/JuliaConDataArchive/master/juliacon2020_schedule/schedule.json"
const jcon = Ref{JuliaConSchedule}()
const CACHE_DIR = get(
    ENV, "JULIACON_CACHE_DIR", joinpath(DEPOT_PATH[1], "datadeps", "JuliaConSchedule")
)
const CACHE_MODE = Symbol(uppercase(get(ENV, "JULIACON_CACHE_MODE", "DEFAULT"))) # :DEFAULT, :NEVER, :ALWAYS
const TIMEOUT = if haskey(ENV, "JULIACON_TIMEOUT")
    try
        parse(Float64, ENV["JULIACON_TIMEOUT"])
    catch err
        @warn "Couldn't parse JULIACON_TIMEOUT to Float64."
        5.0
    end
else
    5.0
end

default_json_url() = DATA_ARCHIVE_JSON_URL
default_now() = Dates.now()

function __init__()
    if isdefined(Main, :Distributed)
        env = Base.active_project()
        @everywhere env = $env

        # activate local env of the master process on all the workers
        @eval Main @everywhere begin
            if myid() != 1
                # suppress REPL warnings and "activating ..." messages
                using Pkg, Logging
                with_logger(NullLogger()) do
                    Pkg.activate(env; io=devnull)
                end
            end
        end
        # load JuliaCon.jl on all workers
        @eval Main @everywhere using JuliaCon
    end
end

export juliacon2021

end
