module JuliaCon

import Base: show
using Preferences
using Distributed
using Dates: Dates, Date, DateTime, Time, Hour, Minute
using JSON
using Downloads: download
using PrettyTables
using TimerOutputs

# remove once PrettyTables has a new tagged release
if !(@isdefined URLTextCell)
    URLTextCell(x,y) = return x
end

include("schedule_structs.jl")
include("preferences.jl")
include("countries.jl")
include("tshirtcode.jl")
include("schedule.jl")

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
