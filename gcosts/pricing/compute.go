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

// Google Compute Engine instance

func CheckComputeInstance(pricingYml StructPricing, inputMachineType string) Instance {
	instances := pricingYml.Compute.Instance
	instance, ok := instances[inputMachineType]
	if ok {
		pterm.Success.Printf("Google Compute Engine machine type '%s' found.\n", inputMachineType)
	} else {
		pterm.Error.Printf("Google Compute Engine machine type '%s' not found!\n", inputMachineType)
		os.Exit(1)
	}
	return instance
}

func CostComputeInstance(pricingYml StructPricing, inputMachineType string, inputRegion string) Cost {
	instance := CheckComputeInstance(pricingYml, inputMachineType)
	cost, ok := instance.Cost[inputRegion]
	if ok {
		pterm.Success.Printf("GCE machine type '%s' in region '%s' found.\n", inputMachineType, inputRegion)
	} else {
		pterm.Error.Printf("GCE machine type '%s' in region '%s' not found!\n", inputMachineType, inputRegion)
		os.Exit(1)
	}
	return cost
}

func returnComputeInstanceSpot(inputValue bool) bool {
	var outputValue bool
	if inputValue {
		outputValue = true
		pterm.Info.Println("GCE instance provisioning model: Spot VM")
	}
	return outputValue
}

func returnComputeInstanceTerminated(inputValue bool) bool {
	var outputValue bool
	if inputValue {
		outputValue = true
		pterm.Info.Println("GCE instance state: Terminated")
	}
	return outputValue
}

func returnComputeInstanceCommitment(inputValue int) int {
	var outputValue int
	switch inputValue {
	case 1:
		outputValue = inputValue
		pterm.Info.Println("GCE instance commitment: 1 year")
	case 3:
		outputValue = inputValue
		pterm.Info.Println("GCE instance commitment: 3 years")
	default:
		outputValue = 0
		pterm.Warning.Printf("Invalid GCE instance commitment: '%v'\n", inputValue)
		pterm.Info.Println("GCE instance commitment: no")
	}
	return outputValue
}

func returnComputeInstanceName(defaultName string, inputName string) string {
	var name string
	if len(defaultName) > 0 {
		name = defaultName
	} else {
		name = "default-instance-name"
	}
	if len(inputName) > 0 {
		name = inputName
	}
	pterm.Info.Printf("GCE instance name: '%s'\n", name)
	return name
}

func CalcComputeInstance(pricingYml StructPricing, inputName string, inputMachineType string, inputRegion string, inputDiscount float32, inputCommitment int, inputSpot bool, inputTerminated bool) float32 {
	name := returnComputeInstanceName("", inputName)
	commitment := returnComputeInstanceCommitment(inputCommitment)
	spot := returnComputeInstanceSpot(inputSpot)
	terminated := returnComputeInstanceTerminated(inputTerminated)
	cost := CostComputeInstance(pricingYml, inputMachineType, inputRegion)
	discount, discountText := returnDiscount(inputDiscount)

	var price float32
	if commitment == 1 {
		price = Month1Y(cost) * discount
		pterm.Info.Printf("1Y CUD price '%s' VM per month: $%.2f %s\n", name, price, discountText)
	} else if commitment == 3 {
		price = Month3Y(cost) * discount
		pterm.Info.Printf("3Y CUD price '%s' VM per month: $%.2f %s\n", name, price, discountText)
	} else if terminated {
		price = 0
		pterm.Info.Printf("Price '%s' VM per month: $%.2f (terminated instance)\n", name, price)
	} else if spot {
		price = MonthSpot(cost) * discount
		pterm.Info.Printf("Spot price '%s' VM per month: $%.2f %s\n", name, price, discountText)
	} else {
		price = Month(cost) * discount
		pterm.Info.Printf("Price '%s' VM per month: $%.2f %s\n", name, price, discountText)
	}
	if price > 0 {
		LineItems = append(LineItems, LineItem{
			File:       File,
			Project:    Project,
			Name:       name,
			Type:       inputMachineType,
			Region:     inputRegion,
			Resource:   "vm",
			Commitment: commitment,
			Discount:   discount,
			Cost:       price,
		})
	}
	return price
}

// Google Compute Engine storage disk

func CheckComputeDisk(pricingYml StructPricing, inputDiskType string) Storage {
	disks := pricingYml.Compute.Storage
	disk, ok := disks[inputDiskType]
	if ok {
		pterm.Success.Printf("Google Compute Engine storage disk type '%s' found.\n", inputDiskType)
	} else {
		pterm.Error.Printf("Google Compute Engine storage disk type '%s' not found!\n", inputDiskType)
		os.Exit(1)
	}
	return disk
}

func CostComputeDisk(pricingYml StructPricing, inputDiskType string, inputRegion string) Cost {
	disk := CheckComputeDisk(pricingYml, inputDiskType)
	cost, ok := disk.Cost[inputRegion]
	if ok {
		pterm.Success.Printf("GCE storage disk type '%s' in region '%s' found.\n", inputDiskType, inputRegion)
	} else {
		pterm.Error.Printf("GCE storage disk type '%s' in region '%s' not found!\n", inputDiskType, inputRegion)
		os.Exit(1)
	}
	return cost
}

func returnComputeDiskName(defaultName string, inputName string) string {
	var name string
	if len(defaultName) > 0 {
		name = defaultName
	} else {
		name = "default-disk-name"
	}
	if len(inputName) > 0 {
		name = inputName
	}
	pterm.Info.Printf("GCE storage disk name: '%s'\n", name)
	return name
}

func CalcComputeDisk(pricingYml StructPricing, inputName string, inputStorageType string, inputStorageData float32, inputRegion string, inputDiscount float32) float32 {
	name := returnComputeDiskName("", inputName)
	discount, discountText := returnDiscount(inputDiscount)
	price := (Month(CostComputeDisk(pricingYml, inputStorageType, inputRegion)) * inputStorageData) * discount
	pterm.Info.Printf("Price '%s' '%.2f' GiB per month: $%.2f %s\n", name, inputStorageData, price, discountText)
	if price > 0 {
		LineItems = append(LineItems, LineItem{
			File:     File,
			Project:  Project,
			Name:     name,
			Type:     inputStorageType,
			Data:     inputStorageData,
			Region:   inputRegion,
			Resource: "disk",
			Discount: discount,
			Cost:     price,
		})
	}
	return price
}

// Google Compute Engine license

func CheckComputeLicense(pricingYml StructPricing, inputMachineType string) License {
	licenses := pricingYml.Compute.License
	license, ok := licenses[inputMachineType]
	if ok {
		//pterm.Success.Printf("Google Compute Engine machine type '%s' found.\n", inputMachineType)
	} else {
		pterm.Error.Printf("License for Google Compute Engine machine type '%s' not found!\n", inputMachineType)
		os.Exit(1)
	}
	return license
}

func CostComputeLicense(pricingYml StructPricing, inputMachineType string, inputOperatingSystem string) Cost {
	license := CheckComputeLicense(pricingYml, inputMachineType)
	cost, ok := license.Cost[inputOperatingSystem]
	if ok {
		pterm.Success.Printf("License '%s' for GCE machine type '%s' found.\n", inputOperatingSystem, inputMachineType)
	} else {
		pterm.Error.Printf("License '%s' for GCE machine type '%s' not found!\n", inputOperatingSystem, inputMachineType)
		os.Exit(1)
	}
	return cost
}

func CalcComputeLicense(pricingYml StructPricing, inputName string, inputMachineType string, inputOperatingSystem string, inputDiscount float32, inputCommitment int, inputTerminated bool) float32 {
	name := returnComputeInstanceName("", inputName)
	commitment := returnComputeInstanceCommitment(inputCommitment)
	terminated := returnComputeInstanceTerminated(inputTerminated)
	discount, discountText := returnDiscount(inputDiscount)
	var price float32
	if len(inputOperatingSystem) > 0 {
		cost := CostComputeLicense(pricingYml, inputMachineType, inputOperatingSystem)
		if commitment == 1 {
			price = Month1Y(cost) * discount
			pterm.Info.Printf("1Y CUD price '%s' license per month: $%.2f %s\n", name, price, discountText)
		} else if commitment == 3 {
			price = Month3Y(cost) * discount
			pterm.Info.Printf("3Y CUD price '%s' license per month: $%.2f %s\n", name, price, discountText)
		} else if terminated {
			price = 0
			pterm.Info.Printf("Price '%s' license per month: $%.2f (terminated instance)\n", name, price)
		} else {
			price = Month(cost) * discount
			pterm.Info.Printf("Price '%s' license per month: $%.2f %s\n", name, price, discountText)
		}
	}
	if price > 0 {
		LineItems = append(LineItems, LineItem{
			File:       File,
			Project:    Project,
			Name:       name,
			Type:       inputMachineType,
			Resource:   inputOperatingSystem,
			Commitment: commitment,
			Discount:   discount,
			Cost:       price,
		})
	}
	return price
}
