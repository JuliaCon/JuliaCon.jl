using JuliaCon
using Test
using Distributed

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
end
