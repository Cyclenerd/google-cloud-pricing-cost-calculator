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

var computeNetworkVpnTunnelCmd = &cobra.Command{
	Use:   "tunnel",
	Short: "GCE network VPN tunnel",
	Run: func(cmd *cobra.Command, args []string) {
		regionCost, ok := pricing.Yml(inputPricing).Compute.Network.Vpn.Tunnel.Cost[inputRegion]
		if ok {
			pterm.Success.Printf("GCE network VPN tunnel in region '%s' found.\n", inputRegion)
			month := regionCost.Month
			if month > 0 {
				pterm.Info.Printf("Price per tunnel per month: $%.2f\n", month)
			} else {
				pterm.Error.Println("Price per month not found!\n")
				os.Exit(1)
			}
		} else {
			pterm.Error.Printf("GCE network VPN tunnel in region '%s' not found!\n", inputRegion)
			os.Exit(1)
		}
	},
}

func init() {
	computeNetworkVpnCmd.AddCommand(computeNetworkVpnTunnelCmd)
	computeNetworkVpnTunnelCmd.PersistentFlags().StringVarP(&inputRegion, "region", "r", "", "Google Cloud region (required)")
	computeNetworkVpnTunnelCmd.MarkPersistentFlagRequired("region")
}
