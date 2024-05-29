/*
Copyright © 2022 Louis Lefebvre <louislefebvre1999@gmail.com>
*/
package cmd

import (
	"bufio"
	"errors"
	"fmt"
	"io/fs"
	"log"
	"os"
	"path"
	"regexp"
	"strings"

	"github.com/spf13/cobra"
)

const tildeRegex = `.*~`

var (
	inter, recurs bool

	ErrNoDelete = errors.New("did not delete a file")
)

var rootCmd = &cobra.Command{
	Use:   "rmt",
	Short: "Removes all files containing a tilde found",
	Run: func(cmd *cobra.Command, args []string) {
		var pwd string
		var err error
		if a := len(args); a > 1 {
			log.Fatal("can only specify at most one argument, got", a)
		} else if a == 1 {
			pwd = args[0]
		} else {
			pwd, err = os.Getwd()
			if err != nil {
				log.Fatal(err)
			}
		}

		if recurs {
			err = fs.WalkDir(os.DirFS(pwd), ".", removeTilde)
			if err != nil {
				log.Fatal(err)
			}
		} else {
			dirs, err := os.ReadDir(pwd)
			if err != nil {
				log.Fatal(err)
			}

			for _, d := range dirs {
				err := removeTilde(path.Join(pwd, d.Name()), d, nil)
				if err != nil {
					log.Println(err)
				}
			}
		}
	},
}

func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

func init() {
	rootCmd.Flags().BoolVarP(&inter, "interactive", "i", false, "interactive output")
	rootCmd.Flags().BoolVarP(&recurs, "recursive", "r", false, "walk filepath starting at current directory")
}

func removeTilde(p string, d fs.DirEntry, err error) error {
	if d.IsDir() {
		return nil
	}

	tr := regexp.MustCompile(tildeRegex)
	if tr.MatchString(d.Name()) {
		err := deleteFile(p, inter)
		if err == ErrNoDelete {
			fmt.Printf("didn't delete %s\n", p)
			return nil
		} else if err != nil {
			return err
		}
		fmt.Printf("deleted %s\n", p)
	}
	return nil
}

func deleteFile(f string, i bool) error {
	if i {
		delete := interactive(f)
		if !delete {
			return ErrNoDelete
		}
	}
	return os.Remove(f)
}

func interactive(f string) bool {
	r := bufio.NewReader(os.Stdin)
	fmt.Printf("Would you like to remove file %s? ", f)
	resp, err := r.ReadString('\n')
	if err != nil {
		panic(err)
	}
	re := strings.TrimSpace(resp)
	if strings.Compare(re, "yes") == 0 || strings.Compare(re, "y") == 0 {
		return true
	}
	return false
}
