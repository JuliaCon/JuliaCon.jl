using JuliaCon
using Test
using Distributed
import Dates
using TimeZones

@testset "JuliaCon.jl" begin
    @testset "juliacon2021()" begin
        @info "Local:"
        @test isnothing(juliacon2021())

        @info "Distributed:"
        withenv("JULIA_PROJECT"=>pwd()) do
            addprocs(4)
            @eval Main @everywhere using JuliaCon
            @test isnothing(@everywhere juliacon2021())
            rmprocs(workers())
        end
    end

    @testset "Preferences" begin
        @testset "Debug mode" begin
            fakenow = ZonedDateTime(Dates.DateTime("2021-07-30T21:30:00.000"), tz"MET")
            @test JuliaCon.default_now() != fakenow
            @test isnothing(JuliaCon.debugmode())
            @test JuliaCon.default_now() == fakenow
            @test isnothing(JuliaCon.debugmode(false))
            @test JuliaCon.default_now() != fakenow

            @test JuliaCon.default_json_url() == JuliaCon.DATA_ARCHIVE_JSON_URL
            @test isnothing(JuliaCon.set_json_source(:pretalx))
            @test JuliaCon.default_json_url() == JuliaCon.PRETALX_JSON_URL
            @test isnothing(JuliaCon.set_json_source(:github))
            @test JuliaCon.default_json_url() == JuliaCon.DATA_ARCHIVE_JSON_URL
        end

        @test isnothing(JuliaCon.set_terminallinks(true))
        @test isnothing(JuliaCon.set_cachemode(:NEVER))
        @test isnothing(JuliaCon.set_cachedir(homedir()))
        @test isnothing(JuliaCon.set_timeout(10))
        @test isnothing(JuliaCon.set_timeout(10.2))
        @test isnothing(JuliaCon.set_local_timezone("EST"))
        @test isnothing(JuliaCon.reset_local_timezone())
        @test_throws ArgumentError JuliaCon.set_local_timezone("Carsten")
    end

    @testset "Schedule" begin
        @test !isassigned(JuliaCon.jcon)
        JuliaCon.update_schedule()
        @test isassigned(JuliaCon.jcon)

        JuliaCon.debugmode()

        # output to terminal
        println("\n")
        @info "Testing output to terminal"
        @test isnothing(JuliaCon.now())
        @test isnothing(JuliaCon.now())
        @test isnothing(JuliaCon.today())
        @test isnothing(JuliaCon.today())
        @test isnothing(JuliaCon.today(track="BoF"))
        @test isnothing(JuliaCon.today(terminal_links=true))

        # output to text (Vector{Sting})
        println("\n")
        @info "Testing output to text, i.e. string(s)"

        ## Print output
        foreach(println, JuliaCon.today(output = :text))
        println(JuliaCon.now(output = :text))
        println(juliacon2021(output = :text))

        ## Test output types
        @test eltype(JuliaCon.today(output = :text)) == String
        @test typeof(JuliaCon.now(output = :text)) == String
        @test typeof(juliacon2021(output = :text)) == String

        JuliaCon.debugmode(false)
    end

end
