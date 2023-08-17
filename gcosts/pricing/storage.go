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

// Storage bucket

func CheckStorageBucket(pricingYml StructPricing, inputStorageClass string) Bucket {
	resources := pricingYml.Storage.Bucket
	resource, ok := resources[inputStorageClass]
	if ok {
		pterm.Success.Printf("Google Cloud Storage class '%s' found.\n", inputStorageClass)
	} else {
		pterm.Error.Printf("Google Cloud Storage class '%s' not found!\n", inputStorageClass)
		os.Exit(1)
	}
	return resource
}

func CheckStorageRetrieval(pricingYml StructPricing, inputStorageClass string) Retrieval {
	resources := pricingYml.Storage.Retrieval
	resource, ok := resources[inputStorageClass]
	if ok {
		pterm.Success.Printf("Google Cloud Storage class with retrieval fee '%s' found.\n", inputStorageClass)
	} else {
		pterm.Error.Printf("Google Cloud Storage class with retrieval fee '%s' not found!\n", inputStorageClass)
		os.Exit(1)
	}
	return resource
}

func CostStorageBucket(pricingYml StructPricing, inputStorageClass string, inputRegion string) Cost {
	resource := CheckStorageBucket(pricingYml, inputStorageClass)
	cost, ok := resource.Cost[inputRegion]
	if ok {
		pterm.Success.Printf("GCS class '%s' in region '%s' found.\n", inputStorageClass, inputRegion)
	} else {
		pterm.Error.Printf("GCS class '%s' in region '%s' not found!\n", inputStorageClass, inputRegion)
		os.Exit(1)
	}
	return cost
}

func CostStorageRetrieval(pricingYml StructPricing, inputStorageClass string, inputRegion string) Cost {
	resource := CheckStorageRetrieval(pricingYml, inputStorageClass)
	cost, ok := resource.Cost[inputRegion]
	if ok {
		pterm.Success.Printf("GCS class with retrieval fee '%s' in region '%s' found.\n", inputStorageClass, inputRegion)
	} else {
		pterm.Error.Printf("GCS class with retrieval fee '%s' in region '%s' not found!\n", inputStorageClass, inputRegion)
		os.Exit(1)
	}
	return cost
}

func returnStorageBucketName(defaultName string, inputName string) string {
	var name string
	if len(defaultName) > 0 {
		name = defaultName
	} else {
		name = "default-bucket-name"
	}
	if len(inputName) > 0 {
		name = inputName
	}
	pterm.Info.Printf("GCS bucket name: '%s'\n", name)
	return name
}

func CalcStorageBucket(pricingYml StructPricing, inputName string, inputStorageClass string, inputStorageData float32, inputStorageRetrieval float32, inputRegion string, inputDiscount float32) float32 {
	name := returnStorageBucketName("", inputName)
	discount, discountText := returnDiscount(inputDiscount)
	var price float32 = (Month(CostStorageBucket(pricingYml, inputStorageClass, inputRegion)) * inputStorageData) * discount
	pterm.Info.Printf("Price '%s' '%.2f' GiB per month: $%.2f %s\n", name, inputStorageData, price, discountText)
	if price > 0 {
		LineItems = append(LineItems, LineItem{
			File:     File,
			Project:  Project,
			Name:     name,
			Type:     inputStorageClass, // Store Class in Type
			Data:     inputStorageData,
			Region:   inputRegion,
			Resource: "bucket",
			Discount: discount,
			Cost:     price,
		})
	}
	if inputStorageRetrieval > 0 {
		var retrieval_fee float32 = (Month(CostStorageRetrieval(pricingYml, inputStorageClass, inputRegion)) * inputStorageRetrieval) * discount
		pterm.Info.Printf("Retrieval fee '%s' '%.2f' GiB per month: $%.2f %s\n", name, inputStorageData, price, discountText)
		if retrieval_fee > 0 {
			LineItems = append(LineItems, LineItem{
				File:     File,
				Project:  Project,
				Name:     name,
				Type:     inputStorageClass, // Store Class in Type
				Data:     inputStorageRetrieval,
				Region:   inputRegion,
				Resource: "retrieval",
				Discount: discount,
				Cost:     retrieval_fee,
			})
		}
	}
	return price
}
