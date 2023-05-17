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

var computeNetworkNatDataCmd = &cobra.Command{
	Use:   "data",
	Short: "GCE network NAT ingress and egress data",
	Run: func(cmd *cobra.Command, args []string) {
		pricingYml := pricing.Yml(inputPricing)
		cost := pricing.CostComputeNetworkNatData(pricingYml, inputRegion)
		month := pricing.Month(cost)
		pterm.Info.Printf("Price ingress and egress data per GiB per month: $%.2f\n", month)
	},
}

func init() {
	computeNetworkNatCmd.AddCommand(computeNetworkNatDataCmd)
	computeNetworkNatDataCmd.PersistentFlags().StringVarP(&inputRegion, "region", "r", "", "Google Cloud region (required)")
	_ = computeNetworkNatDataCmd.MarkPersistentFlagRequired("region")
}
