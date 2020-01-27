package pandoc

import (
	"archive/tar"
	"archive/zip"
	"bytes"
	"compress/gzip"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"

	"github.com/OpenPeeDeeP/xdg"
)

var ErrNoPandocArch = errors.New("No Pandoc binary supports this architecture")
var ErrNoPandocOS = errors.New("No Pandoc binary supports this OS")
var ErrNoPandocBinary = errors.New("Could not find a valid Pandoc binary on Github")

var pandocPath string

type release struct {
	Assets []struct {
		DownloadURL string `json:"browser_download_url"`
	} `json:"assets"`
}

func binDir(appname string) string {
	return filepath.Join(xdg.DataHome(), appname, "bin")
}

func localBinary(appname string) string {
	return filepath.Join(binDir(appname), "pandoc")
}

// Find returns the path of the pandoc executable installed if it exists
func Find(appname string) (string, error) {
	var err error
	pandocPath, err = exec.LookPath("pandoc")
	if err != nil {
		pandocPath = localBinary(appname)
		if _, err := os.Stat(pandocPath); err == nil {
			return pandocPath, nil
		}
		return "", err
	}

	return pandocPath, nil
}

// Run executes the pandoc binary with the given flags and `input` as stdin
func Run(input string, flags []string) error {
	cmd := exec.Command(pandocPath, flags...)
	cmd.Stdin = strings.NewReader(input)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	return err
}

func latestRelease() (*release, error) {
	resp, err := http.Get("https://api.github.com/repos/jgm/pandoc/releases/latest")
	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("server returned bad status: %s", resp.Status)
	}

	body, err := ioutil.ReadAll(resp.Body)

	if err != nil {
		return nil, err
	}

	release := &release{}
	err = json.Unmarshal(body, &release)
	if err != nil {
		return nil, err
	}

	return release, nil
}

func toPandocArch(arch string, os string) (string, error) {
	switch arch {
	case "amd64":
		if os == "windows" {
			return "x86_64", nil
		} else if os == "darwin" {
			return "", nil
		} else if os == "linux" {
			return "amd64", nil
		}
		return "", ErrNoPandocArch
	case "386":
		if os == "windows" {
			return "i386", nil
		}
		return "", ErrNoPandocArch
	default:
		return "", ErrNoPandocArch
	}
}

func toPandocOS(os string) (string, error) {
	switch os {
	case "linux":
		return "linux", nil
	case "darwin":
		return "macOS", nil
	case "windows":
		return "windows", nil
	default:
		return "", ErrNoPandocOS
	}
}

func getCompression(os string) string {
	if runtime.GOOS == "linux" {
		return ".tar.gz"
	}
	return ".zip"
}

func getBinarySuffix(os string, arch string) (string, error) {
	pandocOS, err := toPandocOS(os)
	if err != nil {
		return "", err
	}
	pandocArch, err := toPandocArch(arch, os)
	if err != nil {
		return "", err
	}

	if pandocArch != "" {
		pandocArch = "-" + pandocArch
	}

	return pandocOS + pandocArch + getCompression(pandocOS), nil
}

// Install downloads and installs the latest version of pandoc to XDG_DATA_DIR/appname/bin/pandoc
func Install(appname string) (string, error) {
	r, err := latestRelease()
	if err != nil {
		return "", err
	}

	binarySuffix, err := getBinarySuffix(runtime.GOOS, runtime.GOARCH)
	if err != nil {
		return "", err
	}

	var download string
	for _, asset := range r.Assets {
		if strings.HasSuffix(asset.DownloadURL, binarySuffix) {
			download = asset.DownloadURL
			break
		}
	}

	if download == "" {
		return "", ErrNoPandocBinary
	}

	fmt.Printf("Found a compatible pandoc binary: %s\n", download)

	resp, err := http.Get(download)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("server returned bad status: %s", resp.Status)
	}

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	bindir := binDir(appname)
	if _, err := os.Stat(bindir); os.IsNotExist(err) {
		os.MkdirAll(bindir, os.ModePerm)
	}

	fname := localBinary(appname)
	pandoc, err := os.Create(fname)
	if err != nil {
		return "", err
	}
	defer pandoc.Close()
	os.Chmod(fname, os.ModePerm)

	c := getCompression(runtime.GOOS)
	if c == ".tar.gz" {
		buf := bytes.NewBuffer(body)
		gzf, err := gzip.NewReader(buf)
		if err != nil {
			return "", err
		}
		tr := tar.NewReader(gzf)
		for {
			hdr, err := tr.Next()
			if err == io.EOF {
				break
			}
			if err != nil {
				continue
			}
			if strings.HasSuffix(hdr.Name, "/pandoc") {
				if _, err := io.Copy(pandoc, tr); err != nil {
					return "", err
				}
				return fname, nil
			}
		}
	} else if c == ".zip" {
		reader := bytes.NewReader(body)

		r, err := zip.NewReader(reader, int64(len(body)))
		if err != nil {
			return "", nil
		}

		for _, f := range r.File {
			if strings.HasSuffix(f.Name, "/pandoc") {
				rc, err := f.Open()
				if err != nil {
					return "", err
				}
				defer rc.Close()
				if _, err = io.Copy(pandoc, rc); err != nil {
					return "", err
				}
				return fname, nil
			}
		}
	}

	return "", errors.New("Could not find pandoc binary in archive")
}
