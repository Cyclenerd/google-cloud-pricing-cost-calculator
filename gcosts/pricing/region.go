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
package pricing

import (
	"os"
	"github.com/pterm/pterm"
)

func CheckRegion(pricingYml StructPricing, inputRegion string) bool {
	_, regionOk := pricingYml.Region[inputRegion]
	_, dualRegionOk := pricingYml.DualRegion[inputRegion]
	_, multiRegionOk := pricingYml.MultiRegion[inputRegion]
	var found bool = false
	if regionOk {
		pterm.Success.Printf("Google Cloud region '%s' found.\n", inputRegion)
		found = true
	} else if dualRegionOk {
		pterm.Success.Printf("Google Cloud dual region '%s' found.\n", inputRegion)
		found = true
	} else if multiRegionOk {
		pterm.Success.Printf("Google Cloud multi region '%s' found.\n", inputRegion)
		found = true
	} else {
		pterm.Error.Printf("Google Cloud region '%s' not found!\n", inputRegion)
		os.Exit(1)
	}
	return found
}

func ReturnRegion(pricingYml StructPricing, defaultRegion string, inputRegion string) string {
	var region string
	if len(defaultRegion) > 0 {
		region = defaultRegion
	} else {
		region = "us-central1"
	}
	if len(inputRegion) > 0 {
		CheckRegion(pricingYml, inputRegion)
		region = inputRegion
	}
	pterm.Info.Printf("Google Cloud region: '%s'\n", region)
	return region
}