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

var regionMultiCmd = &cobra.Command{
	Use:   "multi",
	Short: "Google Cloud multi-regions",
	Run: func(cmd *cobra.Command, args []string) {
		pricingYml := pricing.Yml(inputPricing)
		if len(inputRegion) > 0 {
			if pricing.CheckRegion(pricingYml, inputRegion) {
				pterm.Info.Printf("Google Cloud region: %s\n", inputRegion)
			} else {
				pterm.Error.Printf("Google Cloud region '%s' not found!\n", inputRegion)
				os.Exit(1)
			}
		} else {
			var td pterm.TableData
			td = append(td, []string{"Region", "Description"})
			for key, value := range pricingYml.MultiRegion {
				td = append(td, []string{key, value.Description})
			}
			_ = pterm.DefaultTable.WithHasHeader().WithBoxed().WithData(td).Render()
		}
	},
}

func init() {
	regionCmd.AddCommand(regionMultiCmd)
	regionMultiCmd.Flags().StringVarP(&inputRegion, "region", "r", "", "Google Cloud region")
}
