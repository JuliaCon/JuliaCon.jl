abstract type JuliaConTalkType end
struct LightningTalk <: JuliaConTalkType end
struct SponsorTalk <: JuliaConTalkType end
struct Talk <: JuliaConTalkType end
struct Keynote <: JuliaConTalkType end
struct BoF <: JuliaConTalkType end
struct Minisymposia <: JuliaConTalkType end
struct Workshop <: JuliaConTalkType end

struct JuliaConTalk{T<:JuliaConTalkType}
    start::String
    duration::String
    url::String
    title::String
    type::T
    speaker::Vector{String}
end

struct JuliaConTrack
    name::String
    talks::Vector{JuliaConTalk}
end

struct JuliaConDay
    number::Int
    date::Date
    start::DateTime
    stop::DateTime
    tracks::Vector{JuliaConTrack}
end

struct JuliaConSchedule
    start::Date
    stop::Date
    ndays::Int
    days::Vector{JuliaConDay}
end

function json2struct(conf)
    jcon_days = Vector{JuliaConDay}(undef, length(conf["days"]))
    k = 1
    for day in conf["days"]
        jcon_tracks = Vector{JuliaConTrack}(undef, length(day["rooms"]))
        j = 1
        for (track, talks) in day["rooms"]
            jcon_talks = Vector{JuliaConTalk}(undef, length(talks))
            for (i, talk) in enumerate(talks)
                jcon_talks[i] = JuliaConTalk(
                    talk["start"],
                    talk["duration"],
                    talk["url"],
                    talk["title"],
                    talktype_from_str(talk["type"]),
                    String[p["public_name"] for p in talk["persons"]],
                )
            end
            jcon_tracks[j] = JuliaConTrack(string(track), jcon_talks)
            j += 1
        end
        jcon_days[k] = JuliaConDay(
            k,
            Date(day["date"]),
            DateTime(day["day_start"][1:(end - 6)]),
            DateTime(day["day_end"][1:(end - 6)]),
            jcon_tracks,
        )
        k += 1
    end

    jcon = JuliaConSchedule(
        Date(conf["start"]), Date(conf["end"]), length(conf["days"]), jcon_days
    )
    return jcon
end

function talktype_from_str(str)
    if str == "Talk"
        return Talk()
    elseif str == "Lightning Talk"
        return LightningTalk()
    elseif str == "Sponsor Talk"
        return SponsorTalk()
    elseif str == "Keynote"
        return Keynote()
    elseif str == "Birds of Feather"
        return BoF()
    elseif str == "Minisymposia"
        return Minisymposia()
    elseif contains(str, "Workshop")
        return Workshop()
    else
        error("Unknown JuliaCon talk type \"$str\".")
    end
end

function show(io::IO, x::JuliaConSchedule)
    return print(io, "JuliaCon ", Dates.Year(x.start).value, " Schedule")
end
show(io::IO, ::MIME"text/plain", x::JuliaConSchedule) = show(io, x)

function show(io::IO, x::JuliaConDay)
    return print(io, "JuliaCon ", Dates.Year(x.start).value, ": Day ", x.number)
end
show(io::IO, ::MIME"text/plain", x::JuliaConDay) = show(io, x)

show(io::IO, x::JuliaConTrack) = print(io, "JuliaCon Track: ", x.name)
function show(io::IO, ::MIME"text/plain", x::JuliaConTrack)
    show(io, x)
    if length(x.talks) > 1
        print(io, " (", length(x.talks), " talks)")
    else
        print(io, " (", length(x.talks), " talk)")
    end
end

show(io::IO, x::JuliaConTalk{T}) where {T<:JuliaConTalkType} = print(io, T)
function show(io::IO, ::MIME"text/plain", x::JuliaConTalk{T}) where {T<:JuliaConTalkType}
    show(io, x)
    println(io)
    println(io, "├ Title: ", x.title)
    println(io, "├ Time: ", x.start)
    return print(io, "└ URL: ", x.url)
end

show(io::IO, x::LightningTalk) = print(io, "Lightning Talk")
show(io::IO, x::SponsorTalk) = print(io, "Sponsor Talk")
show(io::IO, x::Talk) = print(io, "Talk")
show(io::IO, x::Keynote) = print(io, "Keynote")
show(io::IO, x::BoF) = print(io, "Birds of Feather")
show(io::IO, x::Minisymposia) = print(io, "Minisymposia")
show(io::IO, x::Workshop) = print(io, "Workshop")

abbrev(::Type{LightningTalk}) = "L"
abbrev(::Type{SponsorTalk}) = "S"
abbrev(::Type{Talk}) = "T"
abbrev(::Type{Keynote}) = "K"
abbrev(::Type{BoF}) = "BoF"
abbrev(::Type{Minisymposia}) = "M"
abbrev(::Type{Workshop}) = "W"

abbrev(x::JuliaConTalkType) = abbrev(typeof(x))
