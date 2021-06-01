function juliacon2021()
    if myid() == 1
        return println(
            "Welcome to JuliaCon 2021! Find more information on https://juliacon.org/2021/."
        )
    else
        return println("Greetings from ", rand(countries), "!")
    end
    return nothing
end