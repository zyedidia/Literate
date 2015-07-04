include("common.jl")

function weave(sourcefile)
	out = open("$(name(inputfile)).html", "w")

	start_codeblock = "<pre class=\"prettyprint lang-$codetype\">\n"
	end_codeblock = "</pre>\n"

	include_scripts = """<script src="https://cdn.rawgit.com/google/code-prettify/master/loader/run_prettify.js"></script>
	<script src='https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML'></script>
	<script type="text/x-mathjax-config">
	  MathJax.Hub.Config({tex2jax: {inlineMath: [['\$','\$'], ['\\(','\\)']]}});
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

	for line in lines
		line = chomp(line)
		if line == ""
			continue
		end

		if startswith(line, "@codetype")
			continue
		end

		if ismatch(r"^---.*$", line)
			in_codeblock = !in_codeblock
			if in_codeblock
				line = strip(line[4:end])
				if contains(line, "+=")
					line = "⟨$(strip(line[1:search(line, "+=")[1]-1]))⟩ +="
				else
					line = "⟨$line⟩ ="
				end
				name = strip(line[4:search(line, "⟩")[1]-1])
				write(out, "<a name=\"$name$paragraphnum\"><em class=\"codeblock_name\">$line</em></a>\n")
				write(out, start_codeblock)
			else
				write(out, end_codeblock)
			end
		else
			while ismatch(r"@<.*?>", line)
				m = match(r"@<.*?>", line)
				name = line[m.offset+2:m.offset+length(m.match)-2]
				if in_codeblock
					# line = replace(line, m.match, "\\<span class=\"nocode\"\\>⟨\\<a href=\"#$name\"\\>$name $(block_paragraphs[name])\\</a\\>⟩\\</span\\>")
					links = "\\<span class=\"nocode\"\\>⟨$name"
					for paragraph in split(block_paragraphs[name], ", ")
						links *= ", \\<a href=\"#$paragraph\"\\>$paragraph\\</a\\>"
					end
					links *= "⟩\\</span\\>"
					line = replace(line, m.match, links)
				else
					links = "⟨$name"
					for paragraph in split(block_paragraphs[name], ", ")
						links *= ", \\<a href\\=\\\"#$paragraph\\\"\\>$paragraph\\</a\\>"
					end
					links *= "⟩"
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
					paragraphnum += 1
					write(out, "<a name=\"$paragraphnum\"><h3>$paragraphnum. $(strip(line[3:end]))</h3></a>\n")
				elseif startswith(line, "@title")
					write(out, "<h1>$(strip(line[7:end]))</h1>\n")
				else
					line = Markdown.parse(line) |> Markdown.html
					line = replace(line, "\\&lt;", "<")
					line = replace(line, "\\&gt;", ">")
					line = replace(line, "\\&#61;", "=")
					line = replace(line, "\\&quot;", "\"")
					line = replace(line, "&#36;", "\$")
					line = replace(line, "\\\$", "&#36;")
					write(out, "$line\n")
				end
			end
		end
	end
	end_html = "</body>\n</html>"

	write(out, end_html)
	close(out)
end

buf = readall(inputfile)
firstpass(buf)
weave(buf)
