function juliacon2021(::Val{:terminal})
    if myid() == 1
        return println(
            "Welcome to JuliaCon 2021! Find more information on https://juliacon.org/2021/."
        )
    else
        return println("Greetings from ", rand(countries), "!")
    end
    return nothing
end

# TODO: needs love for a distributed version based on the :terminal method (no hurry though)
function juliacon2021(::Val{:text})
    return "Welcome to JuliaCon 2021! Find more information on https://juliacon.org/2021/."
end

juliacon2021(; output=:terminal) = juliacon2021(Val(output))
