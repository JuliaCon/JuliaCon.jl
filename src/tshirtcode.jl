function juliacon2026(::Val{:terminal})
    if myid() == 1
        return println(
            "Welcome to JuliaCon 2026! Find more information on https://juliacon.org/2026/."
        )
    else
        return println("Greetings from ", rand(countries), "!")
    end
    return nothing
end

# TODO: needs love for a distributed version based on the :terminal method (no hurry though)
function juliacon2026(::Val{:text})
    return "Welcome to JuliaCon 2026! Find more information on https://juliacon.org/2026/."
end

juliacon2026(; output=:terminal) = juliacon2026(Val(output))
