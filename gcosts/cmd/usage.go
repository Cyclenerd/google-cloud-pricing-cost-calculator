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
	"errors"
	"fmt"
	"path/filepath"
	"github.com/Cyclenerd/google-cloud-pricing-cost-calculator/gcosts/pricing"
	"github.com/Cyclenerd/google-cloud-pricing-cost-calculator/gcosts/usage"
	"github.com/spf13/cobra"
	"github.com/pterm/pterm"
)

// usageCmd represents the calc commands
var usageCmd = &cobra.Command{
	Use: "calc",
	Aliases: []string{"calculate", "calculator"},
	SuggestFor: []string{"usage"},
	Short: "Usage files",
	Run: func(cmd *cobra.Command, args []string) {
		pricingYml := pricing.Yml(inputPricing)

		pterm.DefaultSection.Printf("📂 Directory %s\n", inputUsageDir)
		files := usage.ReadDir(inputUsageDir)

		for _, file := range files {
			filepath := filepath.Join(inputUsageDir, file)
			pterm.DefaultSection.WithLevel(2).Printf("📝 File %s\n", file)
			usageYml := usage.Yml(filepath)

			// Overwrite defaults
			defaultProject = pricing.ReturnProject(defaultProject, usageYml.Project)
			defaultRegion = pricing.ReturnRegion(pricingYml, defaultRegion, usageYml.Region)
			defaultDiscount = pricing.ReturnDiscount(defaultDiscount, usageYml.Discount)

			// Store information for cost line item
			pricing.File = file
			pricing.Project = defaultProject

			// Calc pricing of resources
			var disks []usage.Disk = usageYml.Disks
			var buckets []usage.Bucket = usageYml.Buckets
			if len(usageYml.Monitoring) > 0 {
				pterm.DefaultSection.WithLevel(3).Println("🚦 Monitoring")
				for _, monitoring := range usageYml.Monitoring {
					region, discount := pricing.OverwirteDefault(pricingYml, defaultRegion, monitoring.Region, defaultDiscount, monitoring.Discount)
					pricing.CalcMonitoring(pricingYml, monitoring.Name, monitoring.Data, region, discount)
				}
			}
			if len(usageYml.VpnTunnels) > 0 {
				pterm.DefaultSection.WithLevel(3).Println("🚇 Cloud VPN")
				for _, vpnTunnel := range usageYml.VpnTunnels {
					region, discount := pricing.OverwirteDefault(pricingYml, defaultRegion, vpnTunnel.Region, defaultDiscount, vpnTunnel.Discount)
					pricing.CalcComputeNetworkVpnTunnel(pricingYml, vpnTunnel.Name, region, discount)
				}
			}
			if len(usageYml.NatGateways) > 0 {
				pterm.DefaultSection.WithLevel(3).Println("🔗 Cloud NAT")
				for _, natGateway := range usageYml.NatGateways {
					region, discount := pricing.OverwirteDefault(pricingYml, defaultRegion, natGateway.Region, defaultDiscount, natGateway.Discount)
					pricing.CalcComputeNetworkNatGateway(pricingYml, natGateway.Name, natGateway.Data, region, discount)
				}
			}
			if len(usageYml.Traffic) > 0 {
				pterm.DefaultSection.WithLevel(3).Println("🕸️  Network")
				for _, traffic := range usageYml.Traffic {
					region, discount := pricing.OverwirteDefault(pricingYml, defaultRegion, traffic.Region, defaultDiscount, traffic.Discount)
					pricing.CalcComputeNetworkTrafficEgress(pricingYml, traffic.Name, traffic.World, traffic.China, traffic.Australia, region, discount)
				}
			}
			if len(usageYml.Instances) > 0 {
				pterm.DefaultSection.WithLevel(3).Println("🖥️  Compute Engine Instances")
				for _, instance := range usageYml.Instances {
					region, discount := pricing.OverwirteDefault(pricingYml, defaultRegion, instance.Region, defaultDiscount, instance.Discount)
					pricing.CalcComputeInstance(pricingYml, instance.Name, instance.Type, region, discount, instance.Commitment, instance.Spot, instance.Terminated)
					pricing.CalcComputeLicense(pricingYml, instance.Name, instance.Type, instance.Os, discount, instance.Commitment, instance.Terminated)
					pricing.CalcComputeNetworkIp(pricingYml, instance.Name, instance.ExternalIp, region, discount, instance.Terminated)
					disks = append(disks, instance.Disks...)
					buckets = append(buckets, instance.Buckets...)
				}
			}
			if len(disks) > 0 {
				pterm.DefaultSection.WithLevel(3).Println("💾 Compute Engine Disks")
				for _, disk := range disks {
					region, discount := pricing.OverwirteDefault(pricingYml, defaultRegion, disk.Region, defaultDiscount, disk.Discount)
					pricing.CalcComputeDisk(pricingYml, disk.Name, disk.Type, disk.Data, region, discount)
				}
			}
			if len(buckets) > 0 {
				pterm.DefaultSection.WithLevel(3).Println("🪣 Cloud Storage")
				for _, bucket := range buckets {
					region, discount := pricing.OverwirteDefault(pricingYml, defaultRegion, bucket.Region, defaultDiscount, bucket.Discount)
					pricing.CalcStorageBucket(pricingYml, bucket.Name, bucket.Class, bucket.Data, region, discount)
				}
			}
		}

		var td pterm.TableData
		// PROJECT;REGION;RESOURCE;NAME;COST;TYPE;DATA;CLASS;COMMITMENT;DISCOUNT;FILE
		td = append(td, []string{
			"Name",
			"Res.",
			"Type/Class",
			"Cost",
			"CUD",
			"Disc.",
		})
		var totalCosts float32
		for _, lineItem := range pricing.LineItems {
			td = append(td, []string{
				fmt.Sprintf("%.30s", lineItem.Name),
				fmt.Sprintf("%.10s", lineItem.Resource),
				fmt.Sprintf("%.25s", lineItem.Type),
				fmt.Sprintf("%.2f", lineItem.Cost),
				fmt.Sprintf("%v", lineItem.Commitment),
				fmt.Sprintf("%.2f", lineItem.Discount),
			})
			totalCosts = totalCosts + lineItem.Cost
		}

		pterm.DefaultSection.WithLevel(2).Println("💰 Costs")
		_ = pterm.DefaultTable.WithHasHeader().WithBoxed().WithData(td).Render()
		pterm.DefaultBasicText.Println("Total cost: " + pterm.LightMagenta(fmt.Sprintf("%.2f", totalCosts)))

		// Export CSV file
		if _, err := os.Stat(inputExportCsv); errors.Is(err, os.ErrNotExist) {
			// file does not exist
			pricing.ExportCsv(pricing.LineItems, inputExportCsv)
		} else {
			// file exists
			pterm.Warning.Printf("Export file '%s' exists! Should it be overwritten?\n", inputExportCsv)
			result, _ := pterm.DefaultInteractiveConfirm.Show()
			if result {
				pricing.ExportCsv(pricing.LineItems, inputExportCsv)
			} else {
				pterm.Warning.Println("Export file not saved!")
			}
		}

		// Done
		pterm.DefaultHeader.WithFullWidth().Println("✅ Done - Calculation of costs for used resources completed")
	},
}

func init() {
	rootCmd.AddCommand(usageCmd)
	usageCmd.PersistentFlags().StringVarP(&inputUsageDir, "dir", "d", defaultDir, "Directory with YAML usage files")
	usageCmd.PersistentFlags().StringVarP(&inputExportCsv, "csv", "e", defaultExportCsv, "Export CSV file with costs for resources")
}
