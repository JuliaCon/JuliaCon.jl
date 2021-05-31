module JuliaCon

using Distributed

include("countries.jl")

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
                orig_io = Pkg.DEFAULT_IO[]
                Pkg.DEFAULT_IO[] = IOBuffer()
                with_logger(NullLogger()) do
                    Pkg.REPLMode.pkgstr("activate $env")
                end
                Pkg.DEFAULT_IO[] = orig_io
            end
        end
        # load JuliaCon.jl on all workers
        @eval Main @everywhere using JuliaCon
    end
end

export juliacon2021

end
