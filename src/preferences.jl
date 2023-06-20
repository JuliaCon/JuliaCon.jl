const CACHE_MODE = Symbol(uppercase(@load_preference("cache_mode", "DEFAULT")))
const CACHE_DIR = @load_preference(
    "cache_dir", joinpath(DEPOT_PATH[1], "datadeps", "JuliaConSchedule")
)
const TIMEOUT = parse(Float64, @load_preference("timeout", "5.0"))
const TERMINAL_LINKS = parse(Bool, @load_preference("terminal_links", "false"))
const JULIACON_TIMEZONE = tz"UTC"
const LOCAL_TIMEZONE = begin
    tzstr = @load_preference("local_timezone", "")
    if !istimezone(tzstr)
        @has_preference("local_timezone") &&
            @warn "Preference \"local_timezone\" isn't a valid timezone. Check out TimeZones.timezone_names() for possible options. Falling back to localzone()."
        localzone()
    else
        TimeZone(tzstr)
    end
end

const PRETALX_JSON_URL = "https://pretalx.com/juliacon2023/schedule/export/schedule.json"
const DATA_ARCHIVE_JSON_URL = "https://raw.githubusercontent.com/JuliaCon/JuliaConDataArchive/master/juliacon2023_schedule/schedule.json"
const jcon = Ref{DataFrame}()

function set_cachemode(mode::Symbol)
    @assert mode in (:DEFAULT, :NEVER, :ALWAYS)
    @set_preferences!("cache_mode" => uppercase(string(mode)))
    @info("New cache mode set; restart your Julia session for this change to take effect!")
end
function set_cachedir(path::String)
    @set_preferences!("cache_dir" => string(path))
    @info("New cache dir set; restart your Julia session for this change to take effect!")
end
function set_timeout(val::Union{Float64,Int})
    @assert val > 0
    @set_preferences!("timeout" => string(val))
    @info("New timeout set; restart your Julia session for this change to take effect!")
end
function set_terminallinks(on::Bool)
    @set_preferences!("terminal_links" => string(on))
    @info(
        "New terminal links preference set; restart your Julia session for this change to take effect!"
    )
end
function set_local_timezone(tz::AbstractString)
    if !istimezone(tz)
        throw(ArgumentError("\"$tz\" isn't a valid timezone. Check out TimeZones.timezone_names() for possible options."))
    else
        @set_preferences!("local_timezone" => tz)
        @info(
            "New local timezone set; restart your Julia session for this change to take effect!"
        )
        return nothing
    end
end
function reset_local_timezone()
    tz = string(localzone())
    tz = tz == "Etc/UTC" ? "UTC" : tz # Make CI runners happy....
    set_local_timezone(tz)
end

default_json_url() = DATA_ARCHIVE_JSON_URL
default_now() = TimeZones.now(LOCAL_TIMEZONE)

"""
    debugmode(on::Bool=true)

Simulates that we are live / in the middle of JuliaCon.
"""
function debugmode(on::Bool=true)
    if on
        # @eval JuliaCon default_now() = ZonedDateTime(Dates.DateTime("2022-07-20T18:00:00.000"), tz"MET") # JuliaCon2022 workshops
        # @eval JuliaCon default_now() = ZonedDateTime(Dates.DateTime("2022-07-30T22:00:00.000"), tz"MET") # JuliaCon2022 posters
        @eval JuliaCon function default_now()
            return ZonedDateTime(Dates.DateTime("2023-07-27T13:35:00.000"), tz"MET")
            # return ZonedDateTime(Dates.DateTime("2022-07-24T18:15:00.000"), tz"America/Los_Angeles")
            # return ZonedDateTime(Dates.DateTime("2022-07-24T20:00:00.000"), tz"MET")
        end # JuliaCon2023
    else
        @eval JuliaCon default_now() = TimeZones.now(LOCAL_TIMEZONE)
    end
    return nothing
end

"""
    set_json_source(src::Symbol)

Anticipated input: `:pretalx`, `:github` (JuliaConDataArchive)
"""
function set_json_source(src::Symbol)
    if src == :pretalx
        @eval JuliaCon default_json_url() = PRETALX_JSON_URL
    else
        @eval JuliaCon default_json_url() = DATA_ARCHIVE_JSON_URL
    end
    return nothing
end
