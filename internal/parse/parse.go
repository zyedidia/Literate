package parse

import (
	"bytes"
	"log"
	"os"
	"regexp"
	"strings"
)

type DocumentInfo struct {
	Title    string
	Author   string
	Date     string
	CodeType string
}

type Line struct {
	Src string // the actual source for the line
	Num int    // the line number in the Literate file it corresponds to
}

// A Codeblock represents a literate block of code which
// may include other codeblocks in the program
type Codeblock struct {
	Name       string      // Name of the codeblock
	Code       []Line      // Code source
	References []Reference // References are additional codeblocks this block includes
}

// A Reference from one codeblock to another codeblock
type Reference struct {
	// the Block that is being referred to
	Block string
	// InsertWS is the whitespace that should be inserted before each line
	// when inserting the referred block into the referring block
	InsertWS string
	// The line number in the codeblock at which to insert this reference
	InsertLine int
}

func ParseBlocks(src []string) (map[string]Codeblock, DocumentInfo) {
	blocks := make(map[string]Codeblock)
	curBlock := Codeblock{}
	addCode := false
	var doc DocumentInfo

	inCodeblock := false

	r := regexp.MustCompile("@{.*?}")

	for i, l := range src {
		trimmed := strings.TrimSpace(l)
		if strings.HasPrefix(trimmed, "---") {
			inCodeblock = !inCodeblock

			if inCodeblock {
				blockName := strings.TrimSpace(trimmed[3:])
				if strings.HasSuffix(trimmed, "+=") || strings.HasSuffix(trimmed, ":=") {
					blockName = strings.TrimSpace(blockName[:len(blockName)-2])

					if b, ok := blocks[blockName]; !ok {
						// TODO throw error because block wasn't defined yet
						log.Fatal("Block not yet defined ", blockName)
						os.Exit(1)
					} else {
						curBlock = b
					}
				}

				if strings.HasSuffix(trimmed, "+=") {
					addCode = true
				} else {
					addCode = false
				}

				curBlock.Name = blockName
				if !addCode {
					curBlock.References = make([]Reference, 0)
					curBlock.Code = make([]Line, 0)
				}
			} else {
				if trimmed != "---" {
					// TODO throw error because end of codeblock has extra chars
					log.Fatal("Block end has extra chars")
					os.Exit(1)
				}

				blocks[curBlock.Name] = curBlock
			}
		} else if inCodeblock {
			codebuf := &bytes.Buffer{}
			for {
				loc := r.FindStringIndex(l)
				if loc == nil {
					codebuf.WriteString(l)
					break
				} else {
					refName := l[loc[0]+2 : loc[1]-1]
					code := l[:loc[0]]
					curBlock.References = append(curBlock.References, Reference{refName, code, len(curBlock.Code)})
					codebuf.WriteString(code)
					l = l[loc[1]:]
				}
			}
			codebuf.WriteString("\n")
			curBlock.Code = append(curBlock.Code, Line{codebuf.String(), i + 1})
		} else if strings.HasPrefix(trimmed, "@title") {
			doc.Title = strings.TrimSpace(trimmed[6:])
		} else if strings.HasPrefix(trimmed, "@author") {
			doc.Author = strings.TrimSpace(trimmed[7:])
		} else if strings.HasPrefix(trimmed, "@date") {
			doc.Date = strings.TrimSpace(trimmed[5:])
		} else if strings.HasPrefix(trimmed, "@code_type") {
			fields := strings.Fields(trimmed)
			if len(fields) >= 1 {
				doc.CodeType = fields[1]
			}
		}
	}

	return blocks, doc
}
