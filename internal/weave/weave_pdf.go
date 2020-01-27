package weave

import (
	"bytes"
	"fmt"
	"regexp"
	"strings"

	"github.com/zyedidia/lit/internal/parse"
	"github.com/zyedidia/lit/internal/util"
)

var header = `---
title: %s
author: %s
date: %s
geometry: "left=3cm,right=3cm,top=2cm,bottom=2cm"
urlcolor: blue
linkcolor: blue
header-includes:
- |
` + "\t```{=latex}" + `
	\usepackage{xcolor}
	\usepackage{caption}
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

	\DeclareCaptionFormat{listing} {
	   \parbox{\textwidth}{\hspace{-0.2cm}#1#2#3}
	}

	\captionsetup[lstlisting]{format=listing, singlelinecheck=true, margin=0pt, font={tt,bf}}
` + "\t```\n---"

// SetTarget sets the target type (pdf, latex, html, md)
func SetTarget(t int) {
	target = t
}

func Transform(src []string, doc parse.DocumentInfo) string {
	buf := &bytes.Buffer{}
	inCodeblock := false

	buf.WriteString(fmt.Sprintf(header, doc.Title, doc.Author, doc.Date))
	r := regexp.MustCompile("@{.*?}")

	blockName := ""
	for _, l := range src {
		trimmed := strings.TrimSpace(l)
		if strings.HasPrefix(trimmed, "---") {
			inCodeblock = !inCodeblock
			if inCodeblock {
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

				buf.WriteString(fmt.Sprintf("```{%stitle=\"[%s]%s\"}\n", codetype, blockName, suffix))
			} else {
				buf.WriteString("```\n")
				buf.WriteString("\\label{" + util.EncodeBlockName(blockName) + "}\n")
			}
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
					buf.WriteString("@{(*@")
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

	return buf.String()
}
