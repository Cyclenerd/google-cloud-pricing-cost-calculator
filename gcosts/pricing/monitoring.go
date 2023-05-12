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

// Google Cloud Monitoring data

func CostMonitoringDataMiB0_100000(pricingYml StructPricing, inputRegion string) Cost {
	cost, ok := pricingYml.Monitoring.Data.Cost.MiB0_100000[inputRegion]
	if ok {
		pterm.Success.Printf("Google Cloud Monitoring data (0-100,000 MiB) in region '%s' found.\n", inputRegion)
	} else {
		pterm.Error.Printf("Google Cloud Monitoring data (0-100,000 MiB) in region '%s' not found!\n", inputRegion)
		os.Exit(1)
	}
	return cost
}

func CostMonitoringDataMiB0_100000_250000(pricingYml StructPricing, inputRegion string) Cost {
	cost, ok := pricingYml.Monitoring.Data.Cost.MiB0_100000_250000[inputRegion]
	if ok {
		pterm.Success.Printf("Google Cloud Monitoring data (100,000-250,000 MiB) in region '%s' found.\n", inputRegion)
	} else {
		pterm.Error.Printf("Google Cloud Monitoring data (100,000-250,000 MiB) in region '%s' not found!\n", inputRegion)
		os.Exit(1)
	}
	return cost
}

func CostMonitoringDataMiB0_250000n(pricingYml StructPricing, inputRegion string) Cost {
	cost, ok := pricingYml.Monitoring.Data.Cost.MiB0_250000n[inputRegion]
	if ok {
		pterm.Success.Printf("Google Cloud Monitoring data (250,000n MiB) in region '%s' found.\n", inputRegion)
	} else {
		pterm.Error.Printf("Google Cloud Monitoring data (250,000n MiB) in region '%s' not found!\n", inputRegion)
		os.Exit(1)
	}
	return cost
}

func returnMonitoringName(defaultName string, inputName string) string {
	var name string
	if len(defaultName) > 0 {
		name = defaultName
	} else {
		name = "default-monitoing-name"
	}
	if len(inputName) > 0 {
		name = inputName
	}
	pterm.Info.Printf("Monitoring name: '%s'\n", name)
	return name
}

func CalcMonitoring(pricingYml StructPricing, inputName string, inputData float32, inputRegion string, inputDiscount float32) float32 {
	name := returnMonitoringName("", inputName)
	discount, discountText := returnDiscount(inputDiscount)
	var range1 float32 = 100000 // 0-100000 MiB
	var range2 float32 = 250000 // 100000-250000 MiB
	var price float32
	if inputData > 0 {
		// 0-100000 MiB
		month1 := Month(CostMonitoringDataMiB0_100000(pricingYml, inputRegion))
		monthRange1 := range1*month1
		// 100000-250000 MiB
		month2 := Month(CostMonitoringDataMiB0_100000_250000(pricingYml, inputRegion))
		monthRange2 := (range2-range1)*month2
		// 250000n MiB
		month3 := Month(CostMonitoringDataMiB0_250000n(pricingYml, inputRegion))
		if (inputData > range2) {
			price = (inputData-range2)*month3
			price = price + monthRange2 + monthRange1
		} else if inputData > range1 {
			price = (inputData-range1)*month2
			price = price + monthRange1
		} else {
			price = inputData*month1
		}
		price = price*discount
		pterm.Info.Printf("Price '%s' %.2f MiB data per month: $%.2f %s\n", name, inputData, price, discountText)
	}
	if price > 0 {
		LineItems = append(LineItems, LineItem{
			File: File,
			Project: Project,
			Name: name,
			Data: inputData,
			Region: inputRegion,
			Resource: "monitoring",
			Type: "data",
			Discount: discount,
			Cost: price,
		})
	}
	return price
}