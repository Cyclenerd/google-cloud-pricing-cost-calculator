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
	"fmt"
	"encoding/csv"
	"github.com/pterm/pterm"
)

var File string
var Project string

type LineItem struct {
	Project string
	Region string
	Resource string
	Name string
	Cost float32
	Type string // Type or Class
	Data float32
	Commitment int
	Discount float32
	File string
}

var LineItems []LineItem

func Hour(cost Cost) float32 {
	hour := cost.Hour
	if !(hour > 0) {
		pterm.Error.Println("Price per hour not found!")
		os.Exit(1)
	}
	return hour
}

func HourSpot(cost Cost) float32 {
	var hour float32 = cost.HourSpot
	if !(hour > 0) {
		pterm.Warning.Println("Spot price per hour not found! Apply normal hour price.")
		hour = Hour(cost)
	}
	return hour
}

func Month(cost Cost) float32 {
	var month float32 = cost.Month
	if !(month > 0) {
		pterm.Error.Println("Price per month not found!")
		os.Exit(1)
	}
	return month
}

func Month1Y(cost Cost) float32 {
	var month float32 = cost.Month1Y
	if !(month > 0) {
		pterm.Warning.Println("1Y CUD price per month not found! Apply normal monthly price.")
		month = Month(cost)
	}
	return month
}

func Month3Y(cost Cost) float32 {
	var month float32 = cost.Month3Y
	if !(month > 0) {
		pterm.Warning.Println("3Y CUD price per month not found! Apply normal monthly price.")
		month = Month(cost)
	}
	return month
}

func MonthSpot(cost Cost) float32 {
	var month float32 = cost.MonthSpot
	if !(month > 0) {
		pterm.Warning.Println("Spot price per month not found! Apply normal monthly price.")
		month = Month(cost)
	}
	return month
}

func returnDiscount(inputDiscount float32) (float32, string) {
	var discount float32
	var discountText string
	if inputDiscount > 0 {
		discount = inputDiscount
		discountText = fmt.Sprintf("(%.2f discount applied)", discount)
	} else {
		discount = 1.0000
	}
	return discount, discountText
}

func ReturnProject(defaultProject string, inputProject string) string {
	var project string
	if len(defaultProject) > 0 {
		project = defaultProject
	} else {
		project = "default-project-id"
	}
	if len(inputProject) > 0 {
		project = inputProject
	}
	pterm.Info.Printf("Project: '%s'\n", project)
	return project
}

func ReturnDiscount(defaultDiscount float32, inputDiscount float32) float32 {
	var discount float32
	if defaultDiscount > 0 {
		discount = defaultDiscount
		pterm.Info.Printf("Default discount: '%.2f'\n", discount)
	} else {
		discount = 0.000000
	}
	if inputDiscount > 0 {
		discount = inputDiscount
		pterm.Info.Printf("Discount: '%.2f'\n", discount)
	}
	return discount
}

func OverwirteDefault(pricingYml StructPricing, defaultRegion string, inputRegion string, defaultDiscount float32, inputDiscount float32) (string, float32) {
	region := ReturnRegion(pricingYml, defaultRegion, inputRegion)
	discount := ReturnDiscount(defaultDiscount, inputDiscount)
	return region, discount
}

func ExportCsv(lineItems []LineItem, inputExportCsv string) {
	file, err := os.Create(inputExportCsv)
	if err != nil {
		pterm.Error.Println(err)
		os.Exit(9)
	}

	w := csv.NewWriter(file)

	// Old (<3.0.0) header
	// PROJECT;REGION;RESOURCE;NAME;COST;TYPE;DATA;CLASS;COMMITMENT;DISCOUNT;FILE
	data := [][]string{
		{"Project", "Region", "Resource", "Type/Class", "Name", "Cost", "Data", "CUD", "Discount", "File"},
	}
	for _, lineItem := range lineItems {
		data = append(data, []string{
			lineItem.Project,
			lineItem.Region,
			lineItem.Resource,
			lineItem.Type,
			lineItem.Name,
			fmt.Sprintf("%f", lineItem.Cost),
			fmt.Sprintf("%f", lineItem.Data),
			fmt.Sprintf("%v", lineItem.Commitment),
			fmt.Sprintf("%f", lineItem.Discount),
			lineItem.File,
		})
	}
	if err := w.WriteAll(data); err != nil {
		pterm.Error.Println(err)
		os.Exit(8)
	}
}