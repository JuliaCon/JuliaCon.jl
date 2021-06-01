module JuliaCon

using Base: String, alignment
using Distributed
using Dates: Dates, Date, DateTime, Time, Hour, Minute
using JSON3
using UrlDownload
using PrettyTables

const CONFERENCE_SCHEDULE_JSON_URL = "https://pretalx.com/juliacon2020/schedule/export/schedule.json"
const conf_json = Ref{JSON3.Object{Vector{UInt8}, SubArray{UInt64, 1, Vector{UInt64}, Tuple{UnitRange{Int64}}, true}}}()

include("countries.jl")
include("schedule.jl")
include("tshirtcode.jl")

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
                    Pkg.activate(env, io=devnull)
                end
            end
        end
        # load JuliaCon.jl on all workers
        @eval Main @everywhere using JuliaCon
    end
end

export juliacon2021, now, today

end
