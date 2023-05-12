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

var bucketCmd = &cobra.Command{
	Use: "bucket",
	Short: "Google Cloud Storage buckets",
	Run: func(cmd *cobra.Command, args []string) {
		pricingYml := pricing.Yml(inputPricing)
		if len(inputStorageClass) > 0 && len(inputRegion) > 0 {
			cost := pricing.CostStorageBucket(pricingYml, inputStorageClass, inputRegion)
			month := pricing.Month(cost)
			pterm.Info.Printf("Price per GiB per month: $%.2f\n", month)
		} else if len(inputStorageClass) > 0 {
			pricing.CheckStorageBucket(pricingYml, inputStorageClass)
		} else {
			var td pterm.TableData
			td = append(td, []string{"Storage Class"})
			for key := range pricingYml.Storage.Bucket {
				td = append(td, []string{key})
			}
			_ = pterm.DefaultTable.WithHasHeader().WithBoxed().WithData(td).Render()
		}
	},
}

func init() {
	storageCmd.AddCommand(bucketCmd)
	bucketCmd.PersistentFlags().StringVarP(&inputStorageClass, "class", "c", "", "Google Cloud Storage class")
	bucketCmd.PersistentFlags().StringVarP(&inputRegion, "region", "r", "", "Google Cloud region")
}
