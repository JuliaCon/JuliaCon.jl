using JuliaCon
using Test
using Distributed
import Dates

fakenow = Dates.DateTime("2020-07-29T16:30:00.000") # JuliaCon2020

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

    @testset "Schedule" begin
        @test isnothing(JuliaCon.now())
        @test isnothing(JuliaCon.now(; now=fakenow))
        @test isnothing(JuliaCon.today())
        @test isnothing(JuliaCon.today(; now=fakenow))
        @test isnothing(JuliaCon.today(; now=fakenow, track="BoF"))
    end
end
