package tangle

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"

	"github.com/zyedidia/lit/internal/parse"
)

type ConfigOptions struct {
	LineDirectives  bool
	DirectivePrefix string
}

var Config ConfigOptions

func resolveBlock(block parse.Codeblock, blocks map[string]parse.Codeblock, visited []string) parse.Codeblock {
	var refs []parse.Codeblock

	for _, v := range visited {
		if block.Name == v {
			// TODO throw error
			fmt.Println("Circular dependency in", block.Name)
			fmt.Println("Visit order:")

			for _, v := range visited {
				fmt.Print(v + " -> ")
			}
			fmt.Println(block.Name)

			os.Exit(1)
		}
	}

	for _, r := range block.References {
		if b, ok := blocks[r.Block]; ok {
			b = resolveBlock(b, blocks, append(visited, block.Name))
			refs = append(refs, b)
		} else {
			// TODO throw error
			log.Fatal("Could not find reference")
			os.Exit(1)
		}
	}

	for i := len(block.References) - 1; i >= 0; i-- {
		refb := refs[i]
		lnum := block.References[i].InsertLine
		ws := block.References[i].InsertWS

		for i, l := range refb.Code {
			refb.Code[i].Src = ws + l.Src
		}

		block.Code = append(block.Code[:lnum], append(refb.Code, block.Code[lnum:]...)...)
	}

	return block
}

// GenerateBlocks takes the parsed map of blocks and generates resolved top level blocks
func GenerateBlocks(blocks map[string]parse.Codeblock) []parse.Codeblock {
	var toplevel []parse.Codeblock

	for _, v := range blocks {
		if strings.Contains(v.Name, ".") {
			toplevel = append(toplevel, v)
		}
	}

	for i, b := range toplevel {
		toplevel[i] = resolveBlock(b, blocks, []string{})
	}

	return toplevel
}

// WriteCode writes resolved top level code blocks to files
func WriteCode(blocks []parse.Codeblock) {
	for _, b := range blocks {
		f, err := os.Create(b.Name)
		if err != nil {
			// TODO throw error
			fmt.Println(err)
			continue
		}

		for _, l := range b.Code {
			if Config.LineDirectives {
				// TODO errors
				f.Write([]byte(Config.DirectivePrefix))
				f.Write([]byte(strconv.Itoa(l.Num)))
				f.Write([]byte{'\n'})
			}

			_, err := f.Write([]byte(l.Src))
			if err != nil {
				// TODO throw error
				fmt.Println(err)
				break
			}
		}

		f.Close()
	}
}
