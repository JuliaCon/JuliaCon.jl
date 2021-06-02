module JuliaCon

import Base: show
using Distributed
using Dates: Dates, Date, DateTime, Time, Hour, Minute
using JSON
using Downloads: download
using PrettyTables

include("countries.jl")
include("schedule_structs.jl")
include("schedule.jl")
include("tshirtcode.jl")
include("debugmode.jl")

const PRETALX_JSON_URL = "https://pretalx.com/juliacon2020/schedule/export/schedule.json"
const DATA_ARCHIVE_JSON_URL = "https://raw.githubusercontent.com/JuliaCon/JuliaConDataArchive/master/juliacon2020_schedule/schedule.json"
const jcon = Ref{JuliaConSchedule}()

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

export juliacon2021, now, today

end
