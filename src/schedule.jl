abstract type JuliaConTalkType end
struct LightningTalk <: JuliaConTalkType end
struct SponsorTalk <: JuliaConTalkType end
struct Talk <: JuliaConTalkType end
struct Keynote <: JuliaConTalkType end
struct BoF <: JuliaConTalkType end
struct Minisymposium <: JuliaConTalkType end
struct Workshop <: JuliaConTalkType end
struct Experience <: JuliaConTalkType end
struct VirtualPoster <: JuliaConTalkType end

const CONFERENCE_SCHEDULE_URL = "https://live.juliacon.org/agenda"

function json2df(conf)
    df = DataFrame(
        start = ZonedDateTime[],
        duration = CompoundPeriod[],
        title = String[],
        speaker = Vector{String}[],
        type = JuliaConTalkType[],
        url = String[],
        track = String[],
    )

    for day in conf["days"]
        date = Date(day["date"])
        for (track, talks) in day["rooms"]
            for talk in talks
                # parse duration
                tmp = split(talk["duration"], ':')
                dur = Hour(tmp[1]) + Minute(tmp[2])
                
                d = Dict(
                    :start => ZonedDateTime(DateTime(date, Time(talk["start"])), JULIACON_TIMEZONE),
                    :duration => dur,
                    :title => talk["title"],
                    :speaker => String[p["public_name"] for p in talk["persons"]],
                    :type => talktype_from_str(talk["type"]),
                    :url => talk["url"],
                    :track => track,
                )
                push!(df, d)
            end
        end
    end
    
    return df
end

function talktype_from_str(str)
    if str == "Talk"
        return Talk()
    elseif str == "Lightning talk"
        return LightningTalk()
    elseif str == "Sponsor Talk"
        return SponsorTalk()
    elseif str == "Keynote"
        return Keynote()
    elseif str == "Birds of Feather" || str == "BoF (45 mins)"
        return BoF()
    elseif str == "Minisymposium"
        return Minisymposium()
    elseif contains(str, "Workshop")
        return Workshop()
    elseif contains(str, "Experience")
        return Experience()
    elseif contains(str, "Virtual Poster")
        return VirtualPoster()
    else
        error("Unknown JuliaCon talk type \"$str\".")
    end
end

string(x::LightningTalk) = "Lightning Talk"
string(x::SponsorTalk) = "Sponsor Talk"
string(x::Talk) = "Talk"
string(x::Keynote) = "Keynote"
string(x::BoF) = "Birds of Feather"
string(x::Minisymposium) = "Minisymposium"
string(x::Workshop) = "Workshop"
string(x::Experience) = "Experience"
string(x::VirtualPoster) = "Virtual Poster"

abbrev(::Type{LightningTalk}) = "L"
abbrev(::Type{SponsorTalk}) = "S"
abbrev(::Type{Talk}) = "T"
abbrev(::Type{Keynote}) = "K"
abbrev(::Type{BoF}) = "BoF"
abbrev(::Type{Minisymposium}) = "M"
abbrev(::Type{Workshop}) = "W"
abbrev(::Type{Experience}) = "E"
abbrev(::Type{VirtualPoster}) = "P"

abbrev(x::JuliaConTalkType) = abbrev(typeof(x))

is_schedule_json_available() = isfile(joinpath(CACHE_DIR, "schedule.json"))

"""
    get_all_tracks()

Returns a list of strings containing all track names.
"""
function get_tracks()
    cs = get_conference_schedule()
    return unique(cs.track)
end

"""
    print_legend(highlighting)

`highlighting` is a `Bool`.
"""
function print_legend(highlighting)
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
    println("Check out $(CONFERENCE_SCHEDULE_URL) for more information.")
end


"""
    get_conference_schedule(; speaker=nothing)

Get the conference schedule as a DataFrame.
On first call, the schedule is downloaded from Pretalx and cached for further usage.
`speaker` can be a string identifying the speaker to filter the schedule.
"""
function get_conference_schedule(; speaker=nothing)
    isassigned(jcon) || update_schedule()
    # filter for speaker
    jcon_filt = filter(jcon[]) do talk
        return isnothing(speaker) || any(contains.(talk.speaker, speaker))
    end
    return jcon_filt
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
    @timeit to "json2df" jcon[] = json2df(data["schedule"]["conference"])

    verbose && @info string("Timings:\n", to)
    return nothing
end

function get_running_talks(; now=default_now())
    jcon = get_conference_schedule()

    running_talks = filter(jcon; view=true) do talk
        start_time = talk.start
        end_time = start_time + talk.duration
        return start_time <= astimezone(now, JULIACON_TIMEZONE) < end_time
    end
    return running_talks
end

function _print_running_talks(running_talks; now=default_now())
    nrow(running_talks) > 0 || return nothing
    # println()
    # println(Dates.format(default_now(), "HH:MM dd-mm-YYYY"))
    for talk in eachrow(running_talks)
        println()
        printstyled(talk.track; bold=true, color=_track2color(talk.track))
        println()
        println("\t", talk.title, " (", string(talk.type), ")")
        println("\t", "├─ ", _speakers2str(talk.speaker))
        println("\t", "└─ ", talk.url)
    end
    println("\n")
    println("(Full schedule: $(CONFERENCE_SCHEDULE_URL))")
    return nothing
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

function now(::Val{:text}; now)
    running_talks = get_running_talks(; now=now)
    str = ""
    if !isnothing(running_talks)
        for talk in eachrow(running_talks)
            str *= """
            $(talk.track)
            \t$(talk.title) ($(string(talk.type)))
            \t├─ $(JuliaCon._speakers2str(talk.speaker))
            \t└─ $(talk.url)
            """
        end
    end
    str *= "\n(Full schedule: $(CONFERENCE_SCHEDULE_URL))"
    return str
end

function now(::Val{:terminal}; now)
    running_talks = get_running_talks(; now=now)
    _print_running_talks(running_talks; now=now)
    return nothing
end

# A dispatcher for the `now` methods. Default to terminal output.
now(; now=default_now(), output=:terminal) = JuliaCon.now(Val(output); now=now)

function _speakers2str(speaker::Vector{String})
    if length(speaker) <= 3
        return join(speaker, ", ")
    else
        return string(join(speaker[1:3], ", "), " et al.")
    end
end

function _get_today_tables(;
    now=default_now(), speaker=nothing, track=nothing, terminal_links=TERMINAL_LINKS,
    highlighting=true, text_highlighting=false,
    )
    jcon = get_conference_schedule(speaker=speaker)
    
    today_start_utc = ZonedDateTime(DateTime(Date(now), Time("00:00")), JULIACON_TIMEZONE)
    today_end_utc = ZonedDateTime(DateTime(Date(now) + Day(1), Time("00:00")), JULIACON_TIMEZONE)

    talks_today = filter(jcon; view=true) do talk
        # talk is in the requested track (default: any)
        if !isnothing(track) && talk.track != track
            return false
        end

        # talk starts "today" (local time)
        return today_start_utc <= talk.start < today_end_utc
    end

    # no talks today -> exit
    nrow(talks_today) > 0 || return (nothing, nothing, nothing)

    # create talk tables
    tracks = String[]
    tables = Matrix{Union{String,URLTextCell}}[]
    highlighters = Union{Nothing,Highlighter}[]

    # for each track
    for track_grp in groupby(talks_today, :track)
        # build talk-data matrix
        data = Matrix{Union{String,URLTextCell}}(undef, nrow(track_grp), 4)
        for (i, talk) in enumerate(eachrow(track_grp))
            data[i, 1] = Dates.format(astimezone(talk.start, timezone(now)), "HH:MM")
            data[i, 2] = terminal_links ? URLTextCell(talk.title, talk.url) : talk.title
            data[i, 3] = JuliaCon.abbrev(talk.type)
            data[i, 4] = JuliaCon._speakers2str(talk.speaker)
        end

        h_running = Highlighter((data, m, n) -> false, crayon"yellow")
        if highlighting
            for (i, talk) in enumerate(eachrow(track_grp))
                start_time = talk.start
                end_time = talk.start + talk.duration
                if start_time <= astimezone(now, JULIACON_TIMEZONE) < end_time
                    if text_highlighting
                        if data[i, 2] isa URLTextCell
                            data[i, 2].x = string("> ", data[i, 2].x)
                        else
                            data[i, 2] = string("> ", data[i, 2])
                        end
                    end

                    h_running = Highlighter((data, m, n) -> m == i, crayon"yellow")
                end
            end
        end

        push!(tracks, first(track_grp).track)
        push!(tables, data)
        push!(highlighters, h_running)
    end

    @assert length(tables) == length(highlighters) == length(tracks)
    return (tracks, tables, highlighters)
end

# A dispatcher for the `today` methods. Defaults to terminal output.
"""     today(; speaker)

Prints the schedule of today.
`speaker` can be a string identifying the speaker to filter the schedule.
`track` can be string used to filter for a track. See `JuliaCon.get_tracks()` for possible options.
"""
function today(;
    now=default_now(),
    speaker=nothing,
    track=nothing,
    terminal_links=TERMINAL_LINKS,
    output=:terminal, # can take the :text value to output a Vector{String}
    highlighting=true,
    legend=true,
)
    return today(Val(output); now, speaker, track, terminal_links, highlighting, legend)
end

function today(::Val{:terminal}; now, speaker, track, terminal_links, highlighting=true, legend=true)
    tracks, tables, highlighters = _get_today_tables(; now, speaker, track, terminal_links, highlighting)
    isnothing(tables) && return nothing

    pretty_print_results(now, tracks, legend, highlighting, tables, highlighters)
    return nothing
end



function today(::Val{:text}; now, speaker, track, terminal_links, highlighting=true, legend=true)
    tracks, tables, highlighters = _get_today_tables(; now, speaker, track, terminal_links, highlighting, text_highlighting=highlighting)
    isnothing(tables) && return nothing

    results_to_string(now, tracks, legend, highlighting, tables, highlighters)
end


"""     tomorrow(; speaker)

Prints the schedule of tomorrow.
`speaker` can be a string identifying the speaker to filter the schedule.
`track` can be string used to filter for a track. See `JuliaCon.get_tracks()` for possible options.
"""
function tomorrow(;
    now=default_now(),
    speaker=nothing,
    track=nothing,
    terminal_links=TERMINAL_LINKS,
    output=:terminal, # can take the :text value to output a Vector{String},
    legend=true
)
    return today(Val(output); now = now + Dates.Day(1), speaker, track, terminal_links, highlighting = false,
                 legend)
end

"""
    talks_by(speaker; output=:terminal, legend=false)

Prints all talks of a speaker identified by the (sub-)string `speaker`
"""
function talks_by(speaker; output=:terminal, legend=false)
    df = get_conference_schedule()
    # strip of time and filter for pure days
    days = unique(map(x -> Dates.yearmonthday(x), df.start))

    # list of ZoneDateTime for all JuliaCon days
    all_juliacon_dates = map(d -> ZonedDateTime(d..., JuliaCon.LOCAL_TIMEZONE), days)
    t(d, legend) = _get_today_tables(; now = d, speaker, legend)

    _print_talks_by(all_juliacon_dates, speaker, legend, Val(output))
end

function _print_talks_by(all_juliacon_dates, speaker, legend, ::Val{:text})
    str = []
    for d in all_juliacon_dates
        tracks, tables, highlighters = _get_today_tables(; now=d, speaker)
        isnothing(tables) && continue
        s = results_to_string(d, tracks, legend, true, tables, highlighters)
        append!(str, s)
    end
    return str
end

function _print_talks_by(all_juliacon_dates, speaker, legend, ::Val{:terminal})
    for d in all_juliacon_dates
        tracks, tables, highlighters = _get_today_tables(; now=d, speaker)
        isnothing(tables) && continue
        pretty_print_results(d, tracks, legend, true, tables, highlighters)
    end
    return nothing
end
