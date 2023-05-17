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
	"github.com/Cyclenerd/google-cloud-pricing-cost-calculator/gcosts/pricing"
	"github.com/pterm/pterm"
	"github.com/spf13/cobra"
	"os"
)

var aboutCmd = &cobra.Command{
	Use:   "about",
	Short: "pricing.yml informations",
	Run: func(cmd *cobra.Command, args []string) {
		generated := pricing.Yml(inputPricing).About.Generated
		if len(generated) > 0 {
			pterm.Info.Printf("Last price update: %s\n", generated)
		} else {
			pterm.Error.Println("Information not found!")
			os.Exit(1)
		}
	},
}

func init() {
	rootCmd.AddCommand(aboutCmd)
}
