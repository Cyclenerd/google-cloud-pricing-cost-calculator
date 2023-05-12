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
package cmd

import (
	"os"
	"github.com/Cyclenerd/google-cloud-pricing-cost-calculator/gcosts/pricing"
	"github.com/spf13/cobra"
	"github.com/pterm/pterm"
)

var copyrightCmd = &cobra.Command{
	Use:   "copyright",
	Short: "copyright information",
	Run: func(cmd *cobra.Command, args []string) {
		copyright := pricing.Yml(inputPricing).About.Copyright
		if len(copyright) > 0 {
			pterm.DefaultBox.Println(copyright)
		} else {
			pterm.Error.Println("Copyright information not found!\n")
			os.Exit(1)
		}
	},
}

func init() {
	aboutCmd.AddCommand(copyrightCmd)
}
