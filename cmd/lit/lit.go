package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/pflag"
	"github.com/zyedidia/lit/internal/pandoc"
	"github.com/zyedidia/lit/internal/parse"
	"github.com/zyedidia/lit/internal/tangle"
	"github.com/zyedidia/lit/internal/weave"
)

var (
	flagVersion          = pflag.BoolP("version", "v", false, "Show the version")
	flagTangle           = pflag.BoolP("tangle", "t", false, "Only output source code")
	flagWeave            = pflag.BoolP("weave", "w", false, "Only output a readable document")
	flagTarget           = pflag.String("target", "pdf", "Specify the weave target format: pdf, tex, md, html")
	flagOutput           = pflag.StringP("output", "o", "", "Specify the output file name")
	flagNoOutput         = pflag.BoolP("no-output", "n", false, "Do not generate any output files")
	flagLineNums         = pflag.StringP("linenums", "l", "", "Write line numbers prepended with 'string' to the code output")
	flagCompiler         = pflag.BoolP("compiler", "c", false, "Report compiler errors (requires @compiler)")
	flagHelp             = pflag.BoolP("help", "h", false, "Show usage")
	flagInstallPandoc    = pflag.Bool("install-pandoc", false, "Install Pandoc")
	flagVerbose          = pflag.Bool("verbose", false, "Give verbose output")
	flagPandocFlags      = pflag.StringP("pandoc", "p", "", "Additional flags to pass to Pandoc")
	flagShowIntermediate = pflag.Bool("intermediate", false, "Display the intermediate markdown that is sent to Pandoc")
)

// FindPandoc detects if pandoc is installed and if not informs the user to install it or attempts to install it
func FindPandoc() bool {
	path, err := pandoc.Find("lit")
	if err != nil {
		if *flagInstallPandoc {
			install, err := pandoc.Install("lit")
			if err != nil {
				fmt.Println(err)
				return false
			}

			fmt.Printf("Pandoc successfully installed to %s\n", install)
			return true
		}

		fmt.Println("Pandoc was not found on your system, it can be installed by running\n\n\t lit --install-pandoc")
		return false
	} else if *flagInstallPandoc {
		fmt.Printf("Pandoc is installed at %s\n", path)
		return true
	}

	return true
}

// Usage displays the usage text for lit
func Usage() {
	fmt.Fprintf(os.Stderr, "Usage: lit [OPTIONS] [FILE]...\n")
	pflag.PrintDefaults()
}

func main() {
	pflag.Usage = Usage
	pflag.Parse()

	if *flagHelp {
		pflag.Usage()
		return
	}

	if *flagInstallPandoc {
		FindPandoc()
		return
	}

	args := pflag.Args()
	if len(args) <= 0 {
		pflag.Usage()
		return
	}

	for _, a := range args {
		data, err := ioutil.ReadFile(a)
		if err != nil {
			fmt.Println(err)
			continue
		}

		lines := strings.Split(string(data), "\n")

		blocks, doc := parse.ParseBlocks(lines)

		if *flagTangle || !*flagWeave {
			toplevel := tangle.GenerateBlocks(blocks)

			if *flagLineNums != "" {
				tangle.Config.LineDirectives = true
				tangle.Config.DirectivePrefix = *flagLineNums
			}

			tangle.WriteCode(toplevel)
		}

		if *flagWeave || !*flagTangle {
			if FindPandoc() {
				outfname := strings.TrimSuffix(filepath.Base(a), filepath.Ext(a)) + "." + *flagTarget
				toPandoc, args, tempdir := weave.Transform(lines, doc)

				if *flagShowIntermediate {
					fmt.Print(toPandoc)
				}

				err := pandoc.Run(toPandoc, append(args, "-o", outfname))
				fmt.Println(args)

				os.RemoveAll(tempdir)

				if err != nil {
					fmt.Println(err)
				}
			}
		}
	}
}
