"""
    pretty_print_results

Print the results of functions like `today`.
"""
function pretty_print_results(now, tracks, legend, highlighting, tables, highlighters)
    header = (["Time", "Title", "Type", "Speaker"],)
    header_crayon = crayon"dark_gray bold"
    border_crayon = crayon"dark_gray"
    h_times = Highlighter((data, i, j) -> j == 1, crayon"white bold")

    println()
    println(Dates.format(TimeZones.Date(now), "E d U Y"))

    for j in eachindex(tracks)
        track = tracks[j]
        data = tables[j]
        h_running = highlighters[j]
        println()
        pretty_table(
            data;
            title=track,
            title_crayon=Crayon(; foreground=_track2color(track), bold=true),
            header=header,
            header_crayon=header_crayon,
            border_crayon=border_crayon,
            highlighters=(h_times, h_running),
            tf=tf_unicode_rounded,
            alignment=[:c, :l, :c, :l],
        )
    end

    if legend 
        print_legend(highlighting)
    end

    return nothing
end


"""
    results_to_string 

Put the results of functions like `today` to a string.
"""
function results_to_string(now, tracks, legend, highlighting, tables, highlighters)
    header = (["Time", "Title", "Type", "Speaker"],)
    header_crayon = crayon"dark_gray bold"
    border_crayon = crayon"dark_gray"
    h_times = Highlighter((data, i, j) -> j == 1, crayon"white bold")

    strings = Vector{String}()
    push!(strings, string(Dates.format(TimeZones.Date(now), "E d U Y")))
    for j in eachindex(tracks)
        track = tracks[j]
        data = tables[j]
        h_running = highlighters[j]
        str = pretty_table(
            String,
            data;
            title=track,
            title_crayon=Crayon(; foreground=_track2color(track), bold=true),
            header=header,
            header_crayon=header_crayon,
            border_crayon=border_crayon,
            highlighters=(h_times, h_running),
            tf=tf_unicode_rounded,
            alignment=[:c, :l, :c, :l],
        )
        push!(strings, str)
    end

    legend = if highlighting
        """
        Currently running talks are prefixed by a '>'.

        """
    else
        ""
    end

    legend *= """
    $(JuliaCon.abbrev(JuliaCon.Talk)) = Talk, $(JuliaCon.abbrev(JuliaCon.LightningTalk)) = Lightning Talk, $(JuliaCon.abbrev(JuliaCon.SponsorTalk)) = Sponsor Talk, $(JuliaCon.abbrev(JuliaCon.Keynote)) = Keynote,
    $(JuliaCon.abbrev(JuliaCon.Workshop)) = Workshop, $(JuliaCon.abbrev(JuliaCon.Minisymposium)) = Minisymposium, $(JuliaCon.abbrev(JuliaCon.BoF)) = Birds of Feather,
    $(JuliaCon.abbrev(JuliaCon.Experience)) = Experience, $(JuliaCon.abbrev(JuliaCon.VirtualPoster)) = Virtual Poster, $(JuliaCon.abbrev(JuliaCon.SocialHour)) = Social Hour

    Check out $(CONFERENCE_SCHEDULE_URL) for more information.
    """
    push!(strings, legend)
    return strings
end
