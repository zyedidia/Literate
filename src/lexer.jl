import Base.close

const EOF = '\0'

type Lexer
	buffer::IOBuffer
	separators::Array{Char, 1}

	function Lexer(buffer::IOBuffer, separators::Array{Char, 1})
		new(buffer, separators)
	end

	function Lexer(str::String, separators::Array{Char, 1})
		new(IOBuffer(str), separators)
	end
end

function peekchar(io::IOBuffer)
	if !io.readable || io.ptr > io.size
		return EOF
	end
	ch = Uint8(io.data[io.ptr])
	if ch < 0x80
		return Char(ch)
	end
	# mimic utf8.next function
	trailing = Base.utf8_trailing[ch+1]
	c = Uint32(0)
	for j = 1:trailing
		c += ch
		c <<= 6
		ch = Uint8(io.data[io.ptr+j])
	end
	c += ch
	c -= Base.utf8_offset[trailing+1]
	return Char(c)
end

function readchar(io::IOBuffer)
	if eof(io)
		return EOF
	else
		read(io, Char)
	end
end

function trim(str::String)
	if ismatch(r"^\s+$", str)
		str
	else
		strip(str)
	end
end

function advance(lexer::Lexer)
	token = ""
	while true
		c = readchar(lexer.buffer)

		if c == EOF
			return EOF
		end

		token *= "$c"
		if c in lexer.separators || peekchar(lexer.buffer) in lexer.separators
			break
		end
	end
	trim(token)
end

function advanceline(lexer::Lexer)
	line = ""
	token = ""
	while true
		token = advance(lexer)

		line *= "$token"

		nextchar = peekchar(lexer.buffer)
		if token == "\n" || token == EOF || nextchar == "\n" || nextchar == EOF
			break
		end
	end
	line
end

function close(lexer::Lexer)
	close(lexer.buffer)
end
