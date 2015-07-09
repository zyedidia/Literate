# Declare a few globals
title = ""
block_locations = Dict{String, Array{UInt16, 1}}()
block_use_locations = Dict{String, Array{UInt16, 1}}()

codetype = ""
codetype_ext = ""

code_lines = Array{UInt16, 1}() # Hopefully there won't be more than 65,535 lines
section_linenums = Array{UInt16, 1}()

# Define the get_locations function
function get_locations(lines)
    sectionnum = 0   # Which section is currently being parsed
    in_codeblock = false   # Whether we are parsing a codeblock or not

    for line_num = 1:length(lines)
        line = lines[line_num] |> chomp # Use chomp to remove the \n

        if startswith(line, "@title")
# Initialize the title variable
global title = strip(line[7:end])

        elseif startswith(line, "@s")
            push!(section_linenums, Uint16(line_num))
            sectionnum += 1
        elseif startswith(line, "---")
# A codeblock has been defined
in_codeblock = true
if ismatch(r"^---$", line)
    in_codeblock = false
    continue
end
# Get the block name
block_name = line[4:end] |> strip # Remove the ---

if contains(block_name, "+=")
    plus_index = search(block_name, "+")[end] # Get the index of the "+" (the [end] is to get the last occurrence)
    block_name = block_name[1:plus_index-1] |> strip # Remove the "+=" and strip any whitespace
end

# Add the locations to the dict
if !haskey(block_locations, block_name) # If this block has not been defined in the dict yet
    block_locations[block_name] = [sectionnum] # Create a new slot for it and add the current paragraph num
elseif !(sectionnum in block_locations[block_name]) # If the current paragraph num isn't already in the array
    push!(block_locations[block_name], sectionnum) # Add it
end


        elseif in_codeblock && startswith(strip(line), "@{")
# A codeblock has been used
line = strip(line)
block_name = line[3:end-1] # Substring to just get the block name

# Pretty much the same as before
if !haskey(block_use_locations, block_name)
    block_use_locations[block_name] = [sectionnum]
elseif !(sectionnum in block_use_locations[block_name])
    push!(block_use_locations[block_name], sectionnum)
end

        end
    end
end

# Define the write_markdown function
function write_markdown(markdown, out)
    if markdown != ""
        html = Markdown.parse(markdown) |> Markdown.html
        # Here is where we replace \(escaped character code) to what it should be in HTML
        html = replace(html, "\\&lt;", "<")
        html = replace(html, "\\&gt;", ">")
        html = replace(html, "\\&#61;", "=")
        html = replace(html, "\\&quot;", "\"")
        html = replace(html, "&#36;", "\$")
        html = replace(html, "\\\$", "&#36;")
        write(out, "$html\n")
    end
end

# Define the weave function
function weave(lines, outputstream, source_dir, inputfilename, has_index)
    out = outputstream

    get_locations(lines)

# Set up html
start_codeblock = "<pre class=\"prettyprint\">\n"
end_codeblock = "</pre>\n"

scripts = """<script src="https://cdn.rawgit.com/google/code-prettify/master/loader/run_prettify.js"></script>
             <script src='https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML'></script>
             <script type="text/x-mathjax-config"> MathJax.Hub.Config({tex2jax: {inlineMath: [['\$','\$']]}}); </script>"""

# Get the CSS
css = ""
files = readdir(source_dir) # All the files in the current directory
if "default.css" in files
    css = readall("$source_dir/default.css") # Read the user's default.css
else
    css = readall("$gen/default.css") # Use the default css
end

if "colorscheme.css" in files
    css *= readall("$source_dir/colorscheme.css") # Read the user's colorscheme.css
else
    css *= readall("$gen/colorscheme.css") # Use the default colorscheme
end

if "additions.css" in files
    css *= readall("$source_dir/additions.css") # Read the user's additions.css
end


base_html = """<!doctype html>
               <html>
               <head>
               <meta charset="utf-8">
               <title>$title</title>
               $scripts
               <style>
               $css
               </style>
               </head>
               <body>
               """

write(out, base_html)

# Set up variables
sectionnum = 0 # Which section number we are currently parsing
in_codeblock = false # Whether or not we are parsing a some code
in_prose = false # Whether or not we are parsing prose
markdown = "" # This variable holds the current markdown that needs to be transformed to html

cur_codeblock_name = "" # The name of the current codeblock begin parsed


    for line_num = 1:length(lines)
        line = lines[line_num] |> chomp

        if startswith(line, "@code_type")
            command = split(line, " ")
            global codetype = command[2]
            global codetype_ext = command[3]
            continue
        elseif startswith(line, "@comment_type")
            continue
        end

# Parse the line
if line == ""
    # This was a blank line
    if in_codeblock
        write(out, "\n")
    else
        markdown *= "\n" # Tell markdown this was a blank line
    end
    continue
end

if startswith(line, "codetype") # Ignore this line
    continue
end

if ismatch(r"^---.+$", line) # Codeblock began
# Begin codeblock
# A code block just began
in_prose = false
in_codeblock = true
# Write the current markdown
write_markdown(markdown, out)
# Reset the markdown
markdown = ""

write(out, "<div class=\"codeblock\">\n")
name = strip(line[4:end]) # The codeblock name

adding = false # Whether or not this block is a +=

if contains(name, "+=")
    name = strip(name[1:search(name, "+")[end]-1]) # Remove the += from the name
    adding = true
end

cur_codeblock_name = name
file = ismatch(r"^.+\w\.\w+$", name) # Whether or not this name is a file name

definition_location = block_locations[name][1]
output = "$name <a href=\"#$definition_location\">$definition_location</a>" # Add the link to the definition location
output = "{$output} $(adding ? "+" : "")≡" # Add the = or +=

if file
    output = "<strong>$output</strong>" # If the name is a file, make it bold
end

write(out, "<p class=\"notp\" id=\"$name$sectionnum\"><span class=\"codeblock_name\">$output</span></p>\n")
# We can now begin pretty printing the code that comes next
write(out, start_codeblock)

elseif ismatch(r"^---$", line) # Codeblock ended
# End codeblock
# A code block just ended
in_prose = true
in_codeblock = false

# First start by ending the pretty printing
write(out, end_codeblock)
# This was stored when the code block began
name = cur_codeblock_name

# Write any "see also" links
locations = block_locations[name]
if length(locations) > 1
    links = "" # This will hold the html for the links
    loopnum = 0
    for i = 2:length(locations)
        location = locations[i]
        if location != sectionnum
            loopnum += 1
            punc = "" # We might need a comma or 'and'
            if loopnum > 1 && loopnum < length(locations)-1
                punc = ","
            elseif loopnum == length(locations)-1 && loopnum > 1
                punc = " and"
            end
            links *= "$punc <a href=\"#$location\">$location</a>"
        end
    end
    if loopnum > 0
        write(out, "<p class=\"seealso\">See also section$(loopnum > 1 ? "s" : "") $links.</p>\n")
    end
end

# Write any "used in" links
# Top level codeblocks such as files are never used, so we have to check here
if haskey(block_use_locations, name)
    locations = block_use_locations[name]
    output = "<p class=\"seealso\">This code is used in section$(length(locations) > 1 ? "s" : "")"
    for i in 1:length(locations)
        location = locations[i]
        punc = ""
        if i > 1 && i < length(locations)
            punc = ","
        elseif i == length(locations) && i != 1
            punc = " and"
        end
        output *= "$punc <a href=\"#$location\">$location</a>"
    end
    output *= ".</p>\n"
    write(out, output)
end

# Close the "codeblock" div
write(out, "</div>\n")

elseif startswith(line, "@s") && !in_codeblock # Section began
# Create a new section
if sectionnum != 1
    # Every section is part of a div. Here we close the last one, and open a new one
    write(out, "</div>")
end
write(out, "<div class=\"section\">\n")

# Write the markdown. It is possible that the last section had no code and was only prose.
write_markdown(markdown, out)
# Reset the markdown
markdown = ""

in_section = true
sectionnum += 1
heading_title = strip(line[3:end])
write(out, "<p class=\"notp\" id=\"$sectionnum\"><h4 $(heading_title == "" ? "class=\"noheading\"" : "")>$sectionnum. $heading_title</h4></p>\n")

elseif startswith(line, "@title") # Title created
# Create the title
write(out, "<h1>$(strip(line[7:end]))</h1>\n")

else
    if in_codeblock
# Write out the line of code
line = replace(line, "&", "&amp;")
line = replace(line, "<", "&lt;")
line = replace(line, ">", "&gt;")
# Link any sections in the line
while ismatch(r"@{.*?}", line)
    if !startswith(strip(line), "@{") && in_codeblock
        break
    end
    m = match(r"@{.*?}", line)
    name = line[m.offset + 2:m.offset + length(m.match)-2] # Get the name in curly brackets
    location = block_locations[name][1]
    if in_codeblock
        anchor = " <a href=\"#$location\">$location</a>"
        links = "<span class=\"nocode\">{$name$anchor}</span>" # The nocode is so that this is not pretty printed
        line = replace(line, m.match, links)
    else
        anchor = "[$location](#$location)"
        links = "{$name$anchor}"
        line = replace(line, m.match, links)
    end
end

push!(code_lines, Uint16(line_num))
write(out, "$line\n")

    else
# Add the line to the markdown
# Link any sections in the line
while ismatch(r"@{.*?}", line)
    if !startswith(strip(line), "@{") && in_codeblock
        break
    end
    m = match(r"@{.*?}", line)
    name = line[m.offset + 2:m.offset + length(m.match)-2] # Get the name in curly brackets
    location = block_locations[name][1]
    if in_codeblock
        anchor = " <a href=\"#$location\">$location</a>"
        links = "<span class=\"nocode\">{$name$anchor}</span>" # The nocode is so that this is not pretty printed
        line = replace(line, m.match, links)
    else
        anchor = "[$location](#$location)"
        links = "{$name$anchor}"
        line = replace(line, m.match, links)
    end
end

markdown *= line * "\n"

    end
end

    end

    if has_index
        include("$gen/index.jl")
        write(out, create_index(inputfilename))
    end

# Clean up
write_markdown(markdown, out)
write(out, "</body>\n</html>\n")

end


