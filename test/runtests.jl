using JuliaCon
using Test
using Distributed
import Dates

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
            fakenow = Dates.DateTime("2020-07-29T16:30:00.000")
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
    end

    @testset "Schedule" begin
        @test !isassigned(JuliaCon.jcon)
        JuliaCon.update_schedule()
        @test isassigned(JuliaCon.jcon)

        JuliaCon.debugmode()
        @test isnothing(JuliaCon.now())
        @test isnothing(JuliaCon.now())
        @test isnothing(JuliaCon.today())
        @test isnothing(JuliaCon.today())
        @test isnothing(JuliaCon.today(track="BoF"))
        JuliaCon.debugmode(false)
    end

end
