function juliacon2025(::Val{:terminal})
    if myid() == 1
        return println(
            "Welcome to JuliaCon 2025! Find more information on https://juliacon.org/2025/."
        )
    else
        return println("Greetings from ", rand(countries), "!")
    end
    return nothing
end

# TODO: needs love for a distributed version based on the :terminal method (no hurry though)
function juliacon2025(::Val{:text})
    return "Welcome to JuliaCon 2025! Find more information on https://juliacon.org/2025/."
end

juliacon2025(; output=:terminal) = juliacon2025(Val(output))
