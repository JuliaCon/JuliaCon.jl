module JuliaCon

using Requires

juliacon2021() = println("Welcome to JuliaCon 2021! Find more information on https://juliacon.org/2021/.")

function __init__()
    @require Distributed="8ba89e20-285c-5b6f-9357-94700520ee1b" @eval Main @everywhere using JuliaCon
end

export juliacon2021

end
