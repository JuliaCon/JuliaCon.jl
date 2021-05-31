"""
Download the conference schedule as a nested JSON object.
"""
function getschedulejson()
    url = "https://pretalx.com/juliacon2020/schedule/export/schedule.json";
    data = urldownload(url)
    return data.schedule.conference
end

"""
Given a room (i.e. a fixed day and track), it finds the talks that are running now (it only compares times).
"""
function _find_current_talk_in_room(room::JSON3.Array; now=Dates.now())
    for talk in room
        start_time = Time(talk.start)
        dur = Time(talk.duration)
        end_time = start_time + Hour(dur) + Minute(dur)
        if start_time <= Time(now) <= end_time
            return talk
        end
    end
    return nothing
end

"""
Given a fixed day, it finds the talks in all tracks / rooms that are running now (it only compares times).

Returns a vector of tuples of the type `(room::Symbol, talk::JSON3.Object)`.
"""
function _find_current_talks_on_day(d::JSON3.Object; now=Dates.now())
    query_result = [(r, _find_current_talk_in_room(d.rooms[r]; now=now)) for r in keys(d.rooms)]
    return filter(x->!isnothing(x[2]), query_result)
end


# now_fake = DateTime("2020-07-29T16:30:00.000")

function get_running_talks(; now=Dates.now())
    conf = getschedulejson()
    days = [Date(d.date) for d in conf.days]
    
    dayidx = findfirst(isequal(Date(now)), days)
    if isnothing(dayidx)
        @info "There is no JuliaCon program today!"
        return nothing
    end
    
    d = conf.days[dayidx]
    if !(DateTime(d.day_start[1:end-6]) <= now <= DateTime(d.day_end[1:end-6]))
        @info "There is no JuliaCon program now!"
        return nothing
    end
    
    current_talks = _find_current_talks_on_day(d; now=now)
    return current_talks
end

function _track2color(track::Symbol)
    if track == Symbol("Red Track")
        return :red
    elseif track == Symbol("Green Track")
        return :green
    elseif track == Symbol("Purple Track")
        return :magenta
    else
        return :default
    end
end

function _print_running_talks(current_talks; now=Dates.now())
    !isnothing(current_talks) || return nothing
    # println()
    # println(Dates.format(Dates.now(), "HH:MM dd-mm-YYYY"))
    for (track, talk) in current_talks
        println()
        printstyled(track, bold=true, color=_track2color(track))
        println()
        println("\t", talk.title, " (", talk.type,")")
        println("\t", "└─ ", talk.url)
    end
    println("\n")
    println("(Full schedule: https://pretalx.com/juliacon2021/schedule)")
    return nothing
end

function now(; now=Dates.now())
    current_talks = get_running_talks(; now=now)
    _print_running_talks(current_talks; now=now)
    return nothing
end