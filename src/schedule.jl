is_schedule_json_available() = isfile(joinpath(CACHE_DIR, "schedule.json"))

"""
Get the conference schedule as a nested JSON object.
On first call, the schedule is downloaded from Pretalx and cached for further usage.
"""
function get_conference_schedule()
    isassigned(jcon) || update_schedule()
    return jcon[]
end

"""
    update_schedule(; verbose=false, ignore_timeout=false)

Explicitly trigger a schedule update according to the specified CACHE_MODE.
"""
function update_schedule(; verbose=false, notimeout=false)
    local file
    to = TimerOutput()
    verbose && @info "Cache mode: $CACHE_MODE"
    usecache = CACHE_MODE != :NEVER
    download_dir = usecache ? CACHE_DIR : mktempdir()

    if CACHE_MODE != :ALWAYS
        verbose && @info "Downloading $(default_json_url()) to $download_dir"
        if usecache && !isdir(CACHE_DIR)
            verbose && @info "Cache directory $CACHE_DIR created."
            mkpath(CACHE_DIR)
        end

        timeout =
            (usecache && is_schedule_json_available()) ? (!notimeout ? TIMEOUT : Inf) : Inf
        verbose && @info "Timeout set to $timeout seconds."

        try
            @timeit to "download" file = download(
                default_json_url(), joinpath(download_dir, "schedule.json.tmp"); timeout
            )
            file = mv(
                joinpath(download_dir, "schedule.json.tmp"),
                joinpath(download_dir, "schedule.json");
                force=true,
            )
        catch err
            if usecache
                @warn "Download failed or timed out. Falling back to cached schedule (might be stale). " *
                      "You can try forcing matters with JuliaCon.update_schedule(notimeout=true) or " *
                      "skipping the update altogether via JuliaCon.set_cachemode(:ALWAYS)."
                file = joinpath(CACHE_DIR, "schedule.json")
            else
                error(
                    "Download failed. Not using the cache due to CACHE_MODE = $CACHE_MODE."
                )
            end
        end
    else
        verbose && @info "Loading cached schedule.json"
        is_schedule_json_available() || error(
            "Can't find cached schedule.json. Not downloading due to CACHE_MODE = $CACHE_MODE.",
        )
        file = joinpath(CACHE_DIR, "schedule.json")
    end

    @timeit to "parse2json" data = JSON.parsefile(file)
    @timeit to "json2struct" jcon[] = json2struct(data["schedule"]["conference"])

    verbose && @info string("Timings:\n", to)
    return nothing
end

"""
Given a track (i.e. a fixed day), it finds the talks that are running now (it only compares times).
"""
function _find_current_talk_in_track(track::JuliaConTrack; now=default_now())
    for talk in track.talks
        start_time = Time(talk.start) # time in UTC
        dur = Time(talk.duration)
        end_time = start_time + Hour(dur) + Minute(dur)
        if start_time <= Time(_datetime_to_utc(now)) < end_time
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
    query_result = Vector{Tuple{String,Union{Nothing,JuliaConTalk}}}(
        undef, length(d.tracks)
    )
    for (i, track) in enumerate(d.tracks)
        query_result[i] = (track.name, _find_current_talk_in_track(track; now=now))
    end
    return filter(x -> !isnothing(x[2]), query_result)
end

function get_running_talks(; now=default_now())
    jcon = get_conference_schedule()

    dayidx = findfirst(d -> d.date == Date(_datetime_to_utc(now)), jcon.days)
    if isnothing(dayidx)
        @info "There is no JuliaCon program today!"
        return nothing
    end

    d = jcon.days[dayidx]
    if !(d.start <= DateTime(_datetime_to_utc(now)) <= d.stop)
        @info "There is no JuliaCon program now!"
        return nothing
    end

    current_talks = _find_current_talks_on_day(d; now=now)
    return current_talks
end

function _track2color(track::String)
    if track == "Red"
        return :red
    elseif track == "Green"
        return :green
    elseif track == "Purple"
        return :magenta
    elseif track == "Blue"
        return :blue
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
        println("\t", talk.title, " (", string(talk.type), ")")
        println("\t", "├─ ", speakers2str(talk.speaker))
        println("\t", "└─ ", talk.url)
    end
    println("\n")
    println("(Full schedule: https://pretalx.com/juliacon2021/schedule)")
    return nothing
end

function now(::Val{:text}; now)
    current_talks = get_running_talks(; now=now)
    str = ""
    if !isnothing(current_talks)
        for (track, talk) in current_talks
            str *= """
            $track
            \t$(talk.title) ($(string(talk.type)))
            \t├─ $(JuliaCon.speakers2str(talk.speaker))
            \t└─ $(talk.url)
            """
        end
    end
    str *= "\n(Full schedule: https://pretalx.com/juliacon2021/schedule)"
    return str
end

function now(::Val{:terminal}; now)
    current_talks = get_running_talks(; now=now)
    _print_running_talks(current_talks; now=now)
    return nothing
end

# A dispatcher for the `now` methods. Default to terminal output.
now(; now=default_now(), output=:terminal) = JuliaCon.now(Val(output); now=now)

function get_today(; now=default_now())
    jcon = get_conference_schedule()

    dayidx = findfirst(d -> d.date == Date(_datetime_to_utc(now)), jcon.days)
    if isnothing(dayidx)
        @info "There is no JuliaCon program today!"
        return nothing
    end

    schedule = [(track.name, track.talks) for track in jcon.days[dayidx].tracks]
    return schedule
end

speakers2str(speaker::Vector{String}) = join(speaker, ", ")

_datetime_to_utc(t::ZonedDateTime) = astimezone(t, JULIACON_TIMEZONE)
_datetime_to_utc(t) = ZonedDateTime(t, JULIACON_TIMEZONE)

function _get_current_talk_highlighter(talks; now=default_now())
    for (i, talk) in enumerate(talks)
        start_time = Time(talk.start)
        dur = Time(talk.duration)
        end_time = start_time + Hour(dur) + Minute(dur)
        if start_time <= Time(_datetime_to_utc(now)) < end_time
            return Highlighter((data, m, n) -> m == i, crayon"yellow")
        end
    end
    return Highlighter((data, m, n) -> false, crayon"yellow")
end

function _get_today_tables(;
    now=default_now(), track=nothing, terminal_links=TERMINAL_LINKS
)
    track_schedules = get_today(; now=now)
    isnothing(track_schedules) && return (nothing, nothing, nothing)

    tracks = String[]
    tables = Matrix{Union{String,URLTextCell}}[]
    highlighters = Union{Nothing,Highlighter}[]
    for (tr, talks) in track_schedules
        !isnothing(track) && tr != track && continue
        push!(tracks, tr)

        data = Matrix{Union{String,URLTextCell}}(undef, length(talks), 4)
        for (i, talk) in enumerate(talks)
            data[i, 1] = Dates.format(
                _jcontime_to_localtime(Time(talk.start); now), "HH:MM"
            )
            data[i, 2] = terminal_links ? URLTextCell(talk.title, talk.url) : talk.title
            data[i, 3] = JuliaCon.abbrev(talk.type)
            data[i, 4] = JuliaCon.speakers2str(talk.speaker)
        end
        push!(tables, data)

        h_current = _get_current_talk_highlighter(talks; now=now)
        push!(highlighters, h_current)
    end

    @assert length(tables) == length(highlighters) == length(tracks)
    return (tracks, tables, highlighters)
end

function _jcontime_to_localtime(t; now=default_now())
    jcon_datetime = ZonedDateTime(
        DateTime(TimeZones.today(JULIACON_TIMEZONE), t), JULIACON_TIMEZONE
    )
    local_datetime = astimezone(
        jcon_datetime, typeof(now) == DateTime ? LOCAL_TIMEZONE : timezone(now)
    )
    return Time(local_datetime)
end

# A dispatcher for the `today` methods. Defaults to terminal output.
function today(;
    now=default_now(),
    track=nothing,
    terminal_links=TERMINAL_LINKS,
    output=:terminal, # can take the :text value to output a Vector{String}
)
    return today(Val(output); now, track, terminal_links)
end

function today(::Val{:terminal}; now, track, terminal_links, highlighting=true)
    tracks, tables, highlighters = _get_today_tables(; now, track, terminal_links)
    isnothing(tables) && return nothing

    header = (["Time", "Title", "Type", "Speaker"],)
    header_crayon = crayon"dark_gray bold"
    border_crayon = crayon"dark_gray"
    h_times = Highlighter((data, i, j) -> j == 1, crayon"white bold")

    println()
    println(TimeZones.Date(now))

    for j in eachindex(tracks)
        track = tracks[j]
        data = tables[j]
        h_current = highlighters[j]
        println()
        pretty_table(
            data;
            title=track,
            title_crayon=Crayon(; foreground=_track2color(track), bold=true),
            header=header,
            header_crayon=header_crayon,
            border_crayon=border_crayon,
            highlighters=(h_times, h_current),
            tf=tf_unicode_rounded,
            alignment=[:c, :l, :c, :l],
        )
    end

    println()
    if highlighting
        printstyled("Currently running talks are highlighted in ")
        printstyled("yellow"; color=:yellow)
        printstyled(".")
        println()
        println()
    end
    print(abbrev(Talk), " = Talk, ")
    print(abbrev(LightningTalk), " = Lightning Talk, ")
    print(abbrev(SponsorTalk), " = Sponsor Talk, ")
    println(abbrev(Keynote), " = Keynote, ")
    print(abbrev(Workshop), " = Workshop, ")
    print(abbrev(Minisymposium), " = Minisymposium, ")
    println(abbrev(BoF), " = Birds of Feather, ")
    print(abbrev(Experience), " = Experience, ")
    println(abbrev(VirtualPoster), " = Virtual Poster")
    println()
    println("Check out https://pretalx.com/juliacon2021/schedule for more information.")
    return nothing
end

function today(::Val{:text}; now, track, terminal_links, highlighting=true)
    tracks, tables, highlighters = _get_today_tables(; now, track, terminal_links)
    isnothing(tables) && return nothing

    header = (["Time", "Title", "Type", "Speaker"],)
    header_crayon = crayon"dark_gray bold"
    border_crayon = crayon"dark_gray"
    h_times = Highlighter((data, i, j) -> j == 1, crayon"white bold")

    strings = Vector{String}()
    for j in eachindex(tracks)
        track = tracks[j]
        data = tables[j]
        h_current = highlighters[j]
        str = pretty_table(
            String,
            data;
            title=track,
            title_crayon=Crayon(; foreground=_track2color(track), bold=true),
            header=header,
            header_crayon=header_crayon,
            border_crayon=border_crayon,
            highlighters=(h_times, h_current),
            tf=tf_unicode_rounded,
            alignment=[:c, :l, :c, :l],
        )
        push!(strings, str)
    end

    legend = if highlighting
        """
        Currently running talks are highlighted in yellow (or not cause WIP).

        """
    else
        ""
    end

    legend *= """
    $(JuliaCon.abbrev(JuliaCon.Talk)) = Talk, $(JuliaCon.abbrev(JuliaCon.LightningTalk)) = Lightning Talk, $(JuliaCon.abbrev(JuliaCon.SponsorTalk)) = Sponsor Talk, $(JuliaCon.abbrev(JuliaCon.Keynote)) = Keynote,
    $(JuliaCon.abbrev(JuliaCon.Workshop)) = Workshop, $(JuliaCon.abbrev(JuliaCon.Minisymposium)) = Minisymposium, $(JuliaCon.abbrev(JuliaCon.BoF)) = Birds of Feather,
    $(JuliaCon.abbrev(JuliaCon.Experience)) = Experience, $(JuliaCon.abbrev(JuliaCon.VirtualPoster)) = Virtual Poster

    Check out https://pretalx.com/juliacon2021/schedule for more information.
    """
    push!(strings, legend)
    return strings
end

function tomorrow(;
    now=default_now(),
    track=nothing,
    terminal_links=TERMINAL_LINKS,
    output=:terminal, # can take the :text value to output a Vector{String}
)
    return today(Val(output); now = now + Dates.Day(1), track, terminal_links, highlighting = false)
end
