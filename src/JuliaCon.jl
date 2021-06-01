module JuliaCon

using Base: String, alignment
using Distributed
using Dates: Dates, Date, DateTime, Time, Hour, Minute
using JSON3
using UrlDownload
using PrettyTables

include("countries.jl")
include("schedule.jl")

function juliacon2021()
    if myid() == 1
        return println(
            "Welcome to JuliaCon 2021! Find more information on https://juliacon.org/2021/."
        )
    else
        return println("Greetings from ", rand(countries), "!")
    end
    return nothing
end

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
