function juliacon2023(::Val{:terminal})
    if myid() == 1
        return println(
            "Welcome to JuliaCon 2023! Find more information on https://juliacon.org/2023/."
        )
    else
        return println("Greetings from ", rand(countries), "!")
    end
    return nothing
end

# TODO: needs love for a distributed version based on the :terminal method (no hurry though)
function juliacon2023(::Val{:text})
    return "Welcome to JuliaCon 2023! Find more information on https://juliacon.org/2023/."
end

juliacon2023(; output=:terminal) = juliacon2023(Val(output))
