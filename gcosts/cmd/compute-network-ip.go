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
	"github.com/spf13/cobra"
	"github.com/pterm/pterm"
)

var computeNetworkIpCmd = &cobra.Command{
	Use:   "ip",
	Short: "Google Compute Engine external public IP",
	Run: func(cmd *cobra.Command, args []string) {
		pricingYml := pricing.Yml(inputPricing)
		monthVm := pricing.Month(pricing.CostComputeNetworkIpVm(pricingYml, inputRegion))
		pterm.Info.Printf("Price per used IP per month:   $%.2f\n", monthVm)
		monthUnused := pricing.Month(pricing.CostComputeNetworkIpUnused(pricingYml, inputRegion))
		pterm.Info.Printf("Price per unused IP per month: $%.2f\n", monthUnused)
	},
}

func init() {
	computeNetworkCmd.AddCommand(computeNetworkIpCmd)
	computeNetworkCmd.PersistentFlags().StringVarP(&inputRegion, "region", "r", "", "Google Cloud region (required)")
	_ = computeNetworkCmd.MarkPersistentFlagRequired("region")
}
