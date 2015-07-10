# Create the Tag type
type Tag
    name::String
    tag_type::String
    line_num::Int
end


function section_for_linenum(linenum)
    # Get the section number given a line number
    for i = 1:length(section_linenums)
        if i == length(section_linenums)
            return i
        end
        if linenum < section_linenums[i + 1]
            return i
        end
    end

end

function create_index(inputfile)
    try
        run(`which ctags`)
    catch
        println("You do not have ctags installed and it is required for making an index.")
        println("If you do not want to make an index use the -noindex flag.")
        return ""
    end

    supported_languages = split(lowercase(readall(`ctags --list-languages`)), "\n")
    if !(lowercase(codetype) in supported_languages)
        println("$codetype is not supported by your version of ctags.")
        println("Please use -noindex if you would not like to create an index.")
        return ""
    end

    # Run Ctags on the lit file
    tags_str = readall(`ctags -x --language-force=$(lowercase(codetype)) $inputfile`)

    tags_arr = split(tags_str, "\n")
    tags = Tag[]

    for tag in tags_arr
        if tag != ""
            words = split(tag, r"\s+")
            line_num = parse(Int, words[3])

            if !(line_num in code_lines)
                continue
            end

            name = words[1]
            tag_type = words[2]

            push!(tags, Tag(name, tag_type, line_num))
        end
    end

    # Create the HTML for the index
    html = "<h3>Index</h3>\n"
    html *= "<h5>Identifiers Used</h5>\n"
    html *= "<ul class=\"two-col\">\n"

    for tag in tags
        section_num = section_for_linenum(tag.line_num)
        html *= "<li><code>$(tag.name)</code>: <em>$(tag.tag_type)</em> <a href=\"#$section_num\">$section_num</a></li>\n"
    end
    html *= "</ul>"

    html *= "<h5>Code Blocks</h5>\n"
    html *= "<ul class=\"two-col\">\n"

    # Sort the block_locations dictionary so that the codeblocks come in order
    for (name, locations) in sort(collect(block_locations), by=x->x[2][1])
        html *= "<li><code>$(name)</code>"
        for i = 1:length(locations)
            location = locations[i]
            p = i == 1 ? " " : ", "
            html *= "$p<a href=\"#$(location)\">$(location)</a>"
        end
        html *= "</li>\n"
    end
    html *= "</ul>"

    return html
end

