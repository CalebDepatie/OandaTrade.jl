using Test

#TODO: More comprehensive testing

@testset "account" begin
    include("account_test.jl")
end

@testset "order" begin
    include("order_test.jl")
end

@testset "pricing" begin
    include("pricing_test.jl")
end
