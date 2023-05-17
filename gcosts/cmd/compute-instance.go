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

var instanceCmd = &cobra.Command{
	Use:   "instance",
	Short: "Google Compute Engine instances",
	Run: func(cmd *cobra.Command, args []string) {
		pricingYml := pricing.Yml(inputPricing)
		if len(inputMachineType) > 0 && len(inputRegion) > 0 {
			cost := pricing.CostComputeInstance(pricingYml, inputMachineType, inputRegion)
			month := pricing.Month(cost)
			pterm.Info.Printf("Price per month:        $%.2f\n", month)
			month1Y := pricing.Month1Y(cost)
			pterm.Info.Printf("1Y CUD price per month: $%.2f\n", month1Y)
			month3Y := pricing.Month3Y(cost)
			pterm.Info.Printf("3Y CUD price per month: $%.2f\n", month3Y)
			monthSpot := pricing.MonthSpot(cost)
			pterm.Info.Printf("Spot price per month:   $%.2f\n", monthSpot)
		} else if len(inputMachineType) > 0 {
			pricing.CheckComputeInstance(pricingYml, inputMachineType)
		} else {
			var td pterm.TableData
			td = append(td, []string{"Machine Type"})
			for key := range pricingYml.Compute.Instance {
				td = append(td, []string{key})
			}
			_ = pterm.DefaultTable.WithHasHeader().WithBoxed().WithData(td).Render()
		}
	},
}

func init() {
	computeCmd.AddCommand(instanceCmd)
	instanceCmd.PersistentFlags().StringVarP(&inputMachineType, "type", "t", "", "Google Compute Engine machine type")
	instanceCmd.PersistentFlags().StringVarP(&inputRegion, "region", "r", "", "Google Cloud region")
}
