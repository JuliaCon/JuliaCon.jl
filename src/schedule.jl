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

function get_today(; now=Dates.now())
    conf = getschedulejson()
    days = [Date(d.date) for d in conf.days]

    dayidx = findfirst(isequal(Date(now)), days)
    if isnothing(dayidx)
        @info "There is no JuliaCon program today!"
        return nothing
    end

    d = conf.days[dayidx]
    schedule = Vector{Tuple{String, Matrix{String}}}(undef, length(d.rooms))
    i = 1
    for (track, talks) in d.rooms
        timetable = Matrix{String}(undef, length(talks), 4)
        for (j, talk) in enumerate(talks)
            timetable[j,1] = talk.start
            timetable[j,2] = talk.title
            timetable[j,3] = talk.type
            timetable[j,4] = talk.duration
        end
        schedule[i] = (string(track), timetable)
        i+=1
    end
    return schedule
end

function today(; now=Dates.now(), track=nothing)
    track_schedules = get_today(; now=now)
    header = (["Time", "Title", "Type"],)
    header_crayon = crayon"dark_gray bold"
    border_crayon = crayon"dark_gray"
    h_times = Highlighter((data, i, j) -> j == 1, crayon"white bold")
    for (tr, sched) in track_schedules
        !isnothing(track) && tr != track && continue
        h_current = _get_current_talk_highlighter(sched; now=now)
        println()
        pretty_table(@view sched[:,1:3];
            title = tr,
            title_crayon = Crayon(foreground = _track2color(Symbol(tr)), bold = true),
            header = header,
            header_crayon = header_crayon,
            border_crayon = border_crayon,
            highlighters = (h_times, h_current),
            tf = tf_unicode_rounded,
            alignment = :l,
        )
    end
    println()
    println("Check out https://pretalx.com/juliacon2021/schedule for more information.")
    println()
    printstyled("(Currently running talks are highlighted in ")
    printstyled("yellow", color=:yellow)
    printstyled(".)")
    println()
    return nothing
end

function _get_current_talk_highlighter(sched; now=Dates.now())
    for (i, talk) in enumerate(eachrow(sched))
        start_time = Time(talk[1])
        dur = Time(talk[4])
        end_time = start_time + Hour(dur) + Minute(dur)
        if start_time <= Time(now) <= end_time
            return Highlighter((data, m, n) -> m == i, crayon"yellow")
        end
    end
    return nothing
end