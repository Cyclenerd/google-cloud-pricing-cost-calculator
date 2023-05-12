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

var computeNetworkTrafficEgressAustraliaCmd= &cobra.Command{
	Use:   "australia",
	Aliases: []string{"au"},
	Short: "Internet egress traffic with Australia destinations",
	Run: func(cmd *cobra.Command, args []string) {
		pricingYml := pricing.Yml(inputPricing)
		var cost pricing.Cost
		var month float32
		// 0-1 TiB
		cost = pricing.CostComputeNetworkTrafficEgressAustraliaTiB0_1(pricingYml, inputRegion)
		month = pricing.Month(cost)
		pterm.Info.Printf("Price per GiB (0-1 TiB) per month:  $%.2f\n", month)
		// 1-10 TiB
		cost = pricing.CostComputeNetworkTrafficEgressAustraliaTiB1_10(pricingYml, inputRegion)
		month = pricing.Month(cost)
		pterm.Info.Printf("Price per GiB (1-10 TiB) per month: $%.2f\n", month)
		// 10n TiB
		cost = pricing.CostComputeNetworkTrafficEgressAustraliaTiB10n(pricingYml, inputRegion)
		month = pricing.Month(cost)
		pterm.Info.Printf("Price per GiB (10n TiB) per month:  $%.2f\n", month)
	},
}

func init() {
	computeNetworkTrafficEgressCmd.AddCommand(computeNetworkTrafficEgressAustraliaCmd)
	computeNetworkTrafficEgressAustraliaCmd.PersistentFlags().StringVarP(&inputRegion, "region", "r", "", "Google Cloud region (required)")
	_ = computeNetworkTrafficEgressAustraliaCmd.MarkPersistentFlagRequired("region")
}
