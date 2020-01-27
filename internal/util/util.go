package util

import (
	"regexp"
	"strings"
)

func EncodeBlockName(block string) string {
	r := regexp.MustCompile("\\W")
	return "lit" + strings.Join(r.Split(block, -1), "")
}
