"""
Get the conference schedule as a nested JSON object.
On first call, the schedule is downloaded from Pretalx and cached for further usage.
"""
function get_conference_schedule()
    isassigned(jcon) || update_schedule()
    return jcon[]
end

"""
Explicitly trigger a schedule update.
"""
function update_schedule(; verbose=false)
    local file
    to = TimerOutput()
    try
        verbose && @info "Downloading $(default_json_url())"
        @timeit to "download" file = download(default_json_url())
    catch err
        error("Couldn't download schedule.json from $(default_json_url()).")
        println(err)
    end

    try
        @timeit to "parse2json" data = JSON.parsefile(file)
        @timeit to "json2struct" jcon[] = json2struct(data["schedule"]["conference"])
    catch err
        error("Couldn't parse JSON schedule.")
        println(err)
    end
    verbose && @info string("Timings:\n", to)
    return nothing
end

"""
Given a track (i.e. a fixed day), it finds the talks that are running now (it only compares times).
"""
function _find_current_talk_in_track(track::JuliaConTrack; now=default_now())
    for talk in track.talks
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
Given a fixed day, it finds the talks in all tracks that are running now (it only compares times).

Returns a vector of tuples of the type `(track::String, talk::JuliaConTalk)`.
"""
function _find_current_talks_on_day(
    d::JuliaConDay; now=default_now()
)::Vector{Tuple{String,JuliaConTalk}}
    query_result = Vector{Tuple{String,JuliaConTalk}}(undef, length(d.tracks))
    for (i, track) in enumerate(d.tracks)
        query_result[i] = (track.name, _find_current_talk_in_track(track; now=now))
    end
    return filter(x -> !isnothing(x[2]), query_result)
end

function get_running_talks(; now=default_now())
    jcon = get_conference_schedule()

    dayidx = findfirst(d -> d.date == Date(now), jcon.days)
    if isnothing(dayidx)
        @info "There is no JuliaCon program today!"
        return nothing
    end

    d = jcon.days[dayidx]
    if !(d.start <= now <= d.stop)
        @info "There is no JuliaCon program now!"
        return nothing
    end

    current_talks = _find_current_talks_on_day(d; now=now)
    return current_talks
end

function _track2color(track::String)
    if track == "Red Track"
        return :red
    elseif track == "Green Track"
        return :green
    elseif track == "Purple Track"
        return :magenta
    else
        return :default
    end
end

function _print_running_talks(current_talks; now=default_now())
    !isnothing(current_talks) || return nothing
    # println()
    # println(Dates.format(default_now(), "HH:MM dd-mm-YYYY"))
    for (track, talk) in current_talks
        println()
        printstyled(track; bold=true, color=_track2color(track))
        println()
        println("\t", talk.title, " (", talk.type, ")")
        println("\t", "├─ ", speakers2str(talk.speaker))
        println("\t", "└─ ", talk.url)
    end
    println("\n")
    println("(Full schedule: https://pretalx.com/juliacon2021/schedule)")
    return nothing
end

function now(; now=default_now())
    current_talks = get_running_talks(; now=now)
    _print_running_talks(current_talks; now=now)
    return nothing
end

function get_today(; now=default_now())
    jcon = get_conference_schedule()

    dayidx = findfirst(d -> d.date == Date(now), jcon.days)
    if isnothing(dayidx)
        @info "There is no JuliaCon program today!"
        return nothing
    end

    d = jcon.days[dayidx]

    schedule = Vector{Tuple{String,Matrix{String}}}(undef, length(d.tracks))
    i = 1
    for track in d.tracks
        timetable = Matrix{String}(undef, length(track.talks), 5)
        for (j, talk) in enumerate(track.talks)
            timetable[j, 1] = talk.start
            timetable[j, 2] = talk.title
            timetable[j, 3] = abbrev(talk.type) # string(talk.type)
            timetable[j, 4] = speakers2str(talk.speaker)
            timetable[j, 5] = talk.duration
        end
        schedule[i] = (track.name, timetable)
        i += 1
    end
    return schedule
end

speakers2str(speaker::Vector{String}) = join(speaker, ", ")

function today(; now=default_now(), track=nothing)
    track_schedules = get_today(; now=now)
    isnothing(track_schedules) && return nothing
    header = (["Time", "Title", "Type", "Speaker"],)
    header_crayon = crayon"dark_gray bold"
    border_crayon = crayon"dark_gray"
    h_times = Highlighter((data, i, j) -> j == 1, crayon"white bold")
    for (tr, sched) in track_schedules
        !isnothing(track) && tr != track && continue
        h_current = _get_current_talk_highlighter(sched; now=now)
        println()
        pretty_table(
            @view sched[:, 1:4];
            title=tr,
            title_crayon=Crayon(; foreground=_track2color(tr), bold=true),
            header=header,
            header_crayon=header_crayon,
            border_crayon=border_crayon,
            highlighters=(h_times, h_current),
            tf=tf_unicode_rounded,
            alignment=[:c, :l, :c, :l],
        )
    end
    println()
    printstyled("Currently running talks are highlighted in ")
    printstyled("yellow"; color=:yellow)
    printstyled(".")
    println()
    println()
    print(abbrev(Talk), " = Talk, ")
    print(abbrev(LightningTalk), " = Lightning Talk, ")
    print(abbrev(SponsorTalk), " = Sponsor Talk, ")
    println(abbrev(Keynote), " = Keynote, ")
    print(abbrev(Workshop), " = Workshop, ")
    print(abbrev(Minisymposia), " = Minisymposia, ")
    println(abbrev(BoF), " = Birds of Feather")
    println()
    println("Check out https://pretalx.com/juliacon2021/schedule for more information.")
    return nothing
end

function _get_current_talk_highlighter(sched; now=default_now())
    for (i, talk) in enumerate(eachrow(sched))
        start_time = Time(talk[1])
        dur = Time(talk[5])
        end_time = start_time + Hour(dur) + Minute(dur)
        if start_time <= Time(now) <= end_time
            return Highlighter((data, m, n) -> m == i, crayon"yellow")
        end
    end
    return nothing
end
