"""
    debugmode(on::Bool=true)

Simulates that we are live / in the middle of JuliaCon.
"""
function debugmode(on::Bool=true)
    if on
        @eval JuliaCon default_now() = Dates.DateTime("2020-07-29T16:30:00.000") # JuliaCon2020
    else
        @eval JuliaCon default_now() = Dates.now()
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

"""
Explicitly trigger a schedule update.
"""
function update_schedule()
    local file
    try
        file = download(default_json_url())
    catch err
        error("Couldn't download schedule.json from $(default_json_url()).")
        println(err)
    end

    try
        data = JSON.parsefile(file)
        jcon[] = json2struct(data["schedule"]["conference"])
    catch err
        error("Couldn't parse JSON schedule.")
        println(err)
    end
    return nothing
end