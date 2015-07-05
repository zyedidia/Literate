include("common.jl")

function write_markdown(markdown, out)
	if markdown != ""
		markdown = Markdown.parse(markdown) |> Markdown.html
		markdown = replace(markdown, "\\&lt;", "<")
		markdown = replace(markdown, "\\&gt;", ">")
		markdown = replace(markdown, "\\&#61;", "=")
		markdown = replace(markdown, "\\&quot;", "\"")
		markdown = replace(markdown, "&#36;", "\$")
		markdown = replace(markdown, "\\\$", "&#36;")
		write(out, "$markdown\n")
	end
end

function weave(sourcefile)
	out = open("$(name(inputfile)).html", "w")

	start_codeblock = "<pre class=\"prettyprint\">\n"
	end_codeblock = "</pre>\n"

	include_scripts = """<script src="https://cdn.rawgit.com/google/code-prettify/master/loader/run_prettify.js"></script>
	<script src='https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML'></script>
	<script type="text/x-mathjax-config">
	MathJax.Hub.Config({tex2jax: {inlineMath: [['\$','\$']]}});
	</script>"""

	base_html =  """<!doctype html>
	<html>
	<head>
	<meta charset="utf-8">
	<title>$title</title>
	$include_scripts
	<style>
	$(readall("$dir/prettyprint.css"))
	$(readall("$dir/defaultstyle.css"))
	</style>
	</head>
	<body>
	"""

	paragraphnum = 0

	write(out, base_html)

	lines = readlines(IOBuffer(sourcefile))

	in_codeblock = false
	in_paragraph = false
	markdown = ""

	for line in lines
		line = chomp(line)
		if line == ""
			markdown *= "\n"
			continue
		end

		if startswith(line, "@codetype")
			continue
		end

		if ismatch(r"^---.+$", line)
			in_paragraph = false
			write_markdown(markdown, out)
			markdown = ""
		elseif ismatch(r"^---$", line)
			in_paragraph = true
		end

		if ismatch(r"^---.*$", line)
			in_codeblock = !in_codeblock
			if in_codeblock
				line = strip(line[4:end])
				file = false
				if contains(line, "+=")
					line = strip(line[1:search(line, "+=")[1]-1])
					file = ismatch(r"^.+\..+$", line)
					line = "{$line} +≡"
				else
					file = ismatch(r"^.+\..+$", line)
					line = "{$line} ≡"
				end
				name = strip(line[4:search(line, "}")[1]-1])
				if file
					line = "<strong>$line</strong>"
				end
				write(out, "<p class=\"notp\" id=\"$name$paragraphnum\"><span class=\"codeblock_name\">$line</span></p>\n")
				write(out, start_codeblock)
			else
				write(out, end_codeblock)
			end
		else
			while ismatch(r"@{.*?}", line)
				m = match(r"@{.*?}", line)
				name = line[m.offset+2:m.offset+length(m.match)-2]
				if in_codeblock
					links = "\\<span class=\"nocode\"\\>{$name"
					for paragraph in split(block_paragraphs[name], ", ")
						links *= ", \\<a href=\"#$paragraph\"\\>$paragraph\\</a\\>"
					end
					links *= "}\\</span\\>"
					line = replace(line, m.match, links)
				else
					links = "{$name"
					for paragraph in split(block_paragraphs[name], ", ")
						links *= ", \\<a href\\=\\\"#$paragraph\\\"\\>$paragraph\\</a\\>"
					end
					links *= "}"
					line = replace(line, m.match, links)
				end
			end

			if in_codeblock
				line = replace(line, "<", "&lt;")
				line = replace(line, ">", "&gt;")
				line = replace(line, "\\&lt;", "<")
				line = replace(line, "\\&gt;", ">")
				write(out, "$line\n")
			else
				if startswith(line, "@p")
					write_markdown(markdown, out)
					markdown = ""
					in_paragraph = true
					paragraphnum += 1
					write(out, "<p class=\"notp\" id=\"$paragraphnum\"><h3>$paragraphnum. $(strip(line[3:end]))</h3></p>\n")
				elseif startswith(line, "@title")
					write(out, "<h1>$(strip(line[7:end]))</h1>\n")
				else
					if in_paragraph
						markdown *= line * "\n"
					end
				end
			end
		end
	end
	write_markdown(markdown, out)
	markdown = ""
	end_html = "</body>\n</html>"

	write(out, end_html)
	close(out)
end

buf = readall(inputfile)
firstpass(buf)
weave(buf)
