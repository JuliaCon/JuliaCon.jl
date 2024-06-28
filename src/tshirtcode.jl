function juliacon2024(::Val{:terminal})
    if myid() == 1
        return println(
            "Welcome to JuliaCon 2024! Find more information on https://juliacon.org/2024/."
        )
    else
        return println("Greetings from ", rand(countries), "!")
    end
    return nothing
end

# TODO: needs love for a distributed version based on the :terminal method (no hurry though)
function juliacon2024(::Val{:text})
    return "Welcome to JuliaCon 2024! Find more information on https://juliacon.org/2024/."
end

juliacon2024(; output=:terminal) = juliacon2024(Val(output))
