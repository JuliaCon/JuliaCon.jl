function juliacon2022(::Val{:terminal})
    if myid() == 1
        return println(
            "Welcome to JuliaCon 2022! Find more information on https://juliacon.org/2022/."
        )
    else
        return println("Greetings from ", rand(countries), "!")
    end
    return nothing
end

# TODO: needs love for a distributed version based on the :terminal method (no hurry though)
function juliacon2022(::Val{:text})
    return "Welcome to JuliaCon 2022! Find more information on https://juliacon.org/2022/."
end

juliacon2022(; output=:terminal) = juliacon2022(Val(output))
