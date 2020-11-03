package weave

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"log"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/zyedidia/lit/internal/parse"
	"github.com/zyedidia/lit/internal/util"
)

var meta = `title: %s
author: %s
date: %s
geometry: "left=3cm,right=3cm,top=2cm,bottom=2cm"
urlcolor: blue
linkcolor: blue`

var includes = `
lit-caption-includes:
- |
` + "    ```{=latex}" + `
    \usepackage{caption}

    \DeclareCaptionFormat{listing} {
       \parbox{\textwidth}{\hspace{-0.2cm}#1#2#3}
    }

    \captionsetup[lstlisting]{format=listing, singlelinecheck=true, margin=0pt, font={tt,bf}}
` + "    ```" + `
lit-highlight-includes:
- |
` + "    ```{=latex}" + `
    \usepackage{xcolor}
    \definecolor{synred}{rgb}{0.6,0,0}
    \definecolor{syngreen}{rgb}{0.25,0.5,0.35}
    \definecolor{synpurple}{rgb}{0.5,0,0.35}

    \lstset{ basicstyle=\ttfamily
        , keepspaces=true
        , escapeinside={(*@}{@*)}
        , showspaces=false
        , showstringspaces=false
        , breaklines=true
        , frame=tb
        , keywordstyle=\color{synpurple}\bfseries
        , stringstyle=\color{synred}
        , commentstyle=\color{syngreen}
        }
` + "    ```\n"

// SetTarget sets the target type (pdf, latex, html, md)
func SetTarget(t int) {
	target = t
}

// Transform returns the lit file transformed into a pandoc-compatible markdown file
// and the arguments to run with pandoc to convert the markdown to PDF.
func Transform(src []string, doc parse.DocumentInfo) (string, []string, string) {
	buf := &bytes.Buffer{}
	inCodeblock := false

	dir, err := ioutil.TempDir("", "lit")
	if err != nil {
		log.Fatal(err)
		return "", []string{}, ""
	}

	template := filepath.Join(dir, "template.tex")
	metaf := filepath.Join(dir, "meta.yaml")
	ioutil.WriteFile(metaf, []byte(fmt.Sprintf(meta, doc.Title, doc.Author, doc.Date)), 0666)
	ioutil.WriteFile(template, []byte(templateTex), 0666)

	r := regexp.MustCompile("@{.*?}")

	blockName := ""
	for _, l := range src {
		trimmed := strings.TrimSpace(l)
		if strings.HasPrefix(trimmed, "---") && len(trimmed) > 3 && !inCodeblock {
			inCodeblock = true
			blockName = strings.TrimSpace(trimmed[3:])
			suffix := ""
			if strings.HasSuffix(trimmed, "+=") || strings.HasSuffix(trimmed, ":=") {
				suffix = " " + trimmed[len(trimmed)-2:]
				blockName = strings.TrimSpace(blockName[:len(blockName)-2])
			}

			codetype := ""
			if doc.CodeType != "" {
				codetype = "." + doc.CodeType + " "
			}

			buf.WriteString("\\label{" + util.EncodeBlockName(blockName) + "}\n")
			buf.WriteString(fmt.Sprintf("```{%stitle=\"[%s]%s\"}\n", codetype, blockName, suffix))
		} else if len(trimmed) == 3 && inCodeblock {
			inCodeblock = false
			buf.WriteString("```\n")
		} else if inCodeblock {
			for {
				loc := r.FindStringIndex(l)
				if loc == nil {
					buf.WriteString(l)
					break
				} else {
					refName := l[loc[0]+2 : loc[1]-1]
					code := l[:loc[0]]
					buf.WriteString(code)
					buf.WriteString("{(*@")
					buf.WriteString(refName)
					buf.WriteString(" \\ref{" + util.EncodeBlockName(refName) + "}@*)}")
					l = l[loc[1]:]
				}
			}
			buf.WriteString("\n")
		} else if strings.HasPrefix(trimmed, "@s") {
			buf.WriteString("#" + trimmed[2:])
			buf.WriteString("\n")
		} else if !strings.HasPrefix(trimmed, "@") {
			buf.WriteString(l)
			buf.WriteString("\n")
		}
	}

	args := []string{"-s", "--listings", "--number-sections", "--template=" + template, "--metadata-file=" + metaf}

	return buf.String(), args, dir
}
