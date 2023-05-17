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
)

var diskCmd = &cobra.Command{
	Use:     "disk",
	Aliases: []string{"storage"},
	Short:   "Google Compute Engine storage disks",
	Run: func(cmd *cobra.Command, args []string) {
		pricingYml := pricing.Yml(inputPricing)
		if len(inputDiskType) > 0 && len(inputRegion) > 0 {
			cost := pricing.CostComputeDisk(pricingYml, inputDiskType, inputRegion)
			month := pricing.Month(cost)
			pterm.Info.Printf("Price per GiB per month: $%.2f\n", month)
		} else if len(inputDiskType) > 0 {
			pricing.CheckComputeDisk(pricingYml, inputDiskType)
		} else {
			var td pterm.TableData
			td = append(td, []string{"Disk Type"})
			for key := range pricingYml.Compute.Storage {
				td = append(td, []string{key})
			}
			_ = pterm.DefaultTable.WithHasHeader().WithBoxed().WithData(td).Render()
		}
	},
}

func init() {
	computeCmd.AddCommand(diskCmd)
	diskCmd.PersistentFlags().StringVarP(&inputDiskType, "type", "t", "", "Google Compute Engine storage disk type")
	diskCmd.PersistentFlags().StringVarP(&inputRegion, "region", "r", "", "Google Cloud region")
}
