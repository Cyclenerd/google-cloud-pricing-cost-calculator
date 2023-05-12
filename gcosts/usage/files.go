/*
Copyright © 2023 Nils Knieling <https://github.com/Cyclenerd>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package usage

import (
	"os"
	"strings"
	"github.com/pterm/pterm"
)

func ReadDir(dir string) []string {
	pterm.Info.Printf("Directory with YAML usage files: '%s'\n", dir)
	f, err := os.ReadDir(dir)
	if err != nil {
		pterm.Error.Println(err)
		os.Exit(9)
	}
	var files []string
	for _, file := range f {
		if file.IsDir() {
			continue
		}
		name := file.Name()
		if strings.Contains(name, ".yml") {
			pterm.Success.Printf("YAML usage file '%s' found.\n", name)
			files = append(files, name)
		}
	}
	return files
}