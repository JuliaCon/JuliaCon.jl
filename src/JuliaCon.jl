module JuliaCon

import Base: string
using Preferences
using Distributed
using Dates: Dates, Date, DateTime, Day, Time, Hour, Minute, CompoundPeriod
using TimeZones
using JSON
using Downloads: download
using PrettyTables
using TimerOutputs
using DataFrames
using PrecompileTools


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


@compile_workload begin
    redirect_stdout(Base.DevNull()) do
        JuliaCon.today()
        JuliaCon.tomorrow()
        JuliaCon.now()
        JuliaCon.talksby("Carsten Bauer")
        JuliaCon.jcon[] = nothing
    end
end

export juliacon2024, today, tomorrow, now, talksby

end
