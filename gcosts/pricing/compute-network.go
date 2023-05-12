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

// Google Compute Engine external public IP attached but unused

func CostComputeNetworkIpUnused(pricingYml StructPricing, inputRegion string) Cost {
	cost, ok := pricingYml.Compute.Network.Ip.Unused.Cost[inputRegion]
	if ok {
		pterm.Success.Printf("GCE external public unused IP in region '%s' found.\n", inputRegion)
	} else {
		pterm.Error.Printf("GCE external public unused IP in region '%s' not found!\n", inputRegion)
		os.Exit(1)
	}
	return cost
}

// Google Compute Engine external public IP attached and used on VM

func CostComputeNetworkIpVm(pricingYml StructPricing, inputRegion string) Cost {
	cost, ok := pricingYml.Compute.Network.Ip.Vm.Cost[inputRegion]
	if ok {
		pterm.Success.Printf("GCE external public IP in region '%s' found.\n", inputRegion)
	} else {
		pterm.Error.Printf("GCE external public IP in region '%s' not found!\n", inputRegion)
		os.Exit(1)
	}
	return cost
}

func CalcComputeNetworkIp(pricingYml StructPricing, inputName string, inputExternalIp int, inputRegion string, inputDiscount float32, inputTerminated bool) float32 {
	name := returnComputeInstanceName("", inputName)
	// TODO: Calc spot price
	//spot := returnComputeInstanceSpot(inputSpot)
	terminated := returnComputeInstanceTerminated(inputTerminated)
	discount, discountText := returnDiscount(inputDiscount)
	var externalIp = float32(inputExternalIp)
	var price float32
	if externalIp > 0 {
		if terminated {
			price = (Month(CostComputeNetworkIpUnused(pricingYml, inputRegion))*externalIp)*discount
			pterm.Info.Printf("Price '%s' %v unused IP per month: $%.2f (terminated instance) %s\n", name, inputExternalIp, price, discountText)
		} else {
			price = (Month(CostComputeNetworkIpVm(pricingYml, inputRegion))*externalIp)*discount
			pterm.Info.Printf("Price '%s' %v IP per month: $%.2f %s\n", name, inputExternalIp, price, discountText)
		}
	}
	if price > 0 {
		LineItems = append(LineItems, LineItem{
			File: File,
			Project: Project,
			Region: inputRegion,
			Name: name,
			Type: "ip",
			Data: externalIp,
			Resource: "network",
			Discount: discount,
			Cost: price,
		})
	}
	return price
}

// Google Compute Engine network NAT ingress and egress data

func CostComputeNetworkNatData(pricingYml StructPricing, inputRegion string) Cost {
	cost, ok := pricingYml.Compute.Network.Nat.Data.Cost[inputRegion]
	if ok {
		pterm.Success.Printf("GCE network NAT data in region '%s' found.\n", inputRegion)
	} else {
		pterm.Error.Printf("GCE network NAT data in region '%s' not found!\n", inputRegion)
		os.Exit(1)
	}
	return cost
}

// Google Compute Engine network NAT gateway

func CostComputeNetworkNatGateway(pricingYml StructPricing, inputRegion string) Cost {
	cost, ok := pricingYml.Compute.Network.Nat.Gateway.Cost[inputRegion]
	if ok {
		pterm.Success.Printf("GCE network NAT gateway in region '%s' found.\n", inputRegion)
	} else {
		pterm.Error.Printf("GCE network NAT gateway in region '%s' not found!\n", inputRegion)
		os.Exit(1)
	}
	return cost
}

func returnComputeNetworkNatGatewayName(defaultName string, inputName string) string {
	var name string
	if len(defaultName) > 0 {
		name = defaultName
	} else {
		name = "default-nat-gateway"
	}
	if len(inputName) > 0 {
		name = inputName
	}
	pterm.Info.Printf("GCE network NAT gateway name: '%s'\n", name)
	return name
}

func CalcComputeNetworkNatGateway(pricingYml StructPricing, inputName string, inputData float32, inputRegion string, inputDiscount float32) float32 {
	name := returnComputeNetworkNatGatewayName("", inputName)
	discount, discountText := returnDiscount(inputDiscount)
	// Gateway
	costComputeNetworkNatGateway := CostComputeNetworkNatGateway(pricingYml, inputRegion)
	priceComputeNetworkNatGateway := Month(costComputeNetworkNatGateway)*discount
	pterm.Info.Printf("Price '%s' NAT gateway per month: $%.2f %s\n", name, priceComputeNetworkNatGateway, discountText)
	// Data
	costComputeNetworkNatData := CostComputeNetworkNatData(pricingYml, inputRegion)
	priceComputeNetworkNatData := (Month(costComputeNetworkNatData)*inputData)*discount
	pterm.Info.Printf("Price '%s' %.2f MiB NAT data per month: $%.2f %s\n", name, inputData, priceComputeNetworkNatData, discountText)
	// Sum
	price := priceComputeNetworkNatGateway+priceComputeNetworkNatData
	pterm.Info.Printf("Price '%s' NAT total per month: $%.2f %s\n", name, price, discountText)
	if price > 0 {
		LineItems = append(LineItems, LineItem{
			File: File,
			Project: Project,
			Region: inputRegion,
			Name: name,
			Type: "nat-gateway",
			Data: inputData,
			Resource: "network",
			Discount: discount,
			Cost: price,
		})
	}
	return price
}

// Google Compute Engine network VPN tunnel

func CostComputeNetworkVpnTunnel(pricingYml StructPricing, inputRegion string) Cost {
	cost, ok := pricingYml.Compute.Network.Vpn.Tunnel.Cost[inputRegion]
	if ok {
		pterm.Success.Printf("GCE network VPN tunnel in region '%s' found.\n", inputRegion)
	} else {
		pterm.Error.Printf("GCE network VPN tunnel in region '%s' not found!\n", inputRegion)
		os.Exit(1)
	}
	return cost
}

func returnComputeNetworkVpnTunnelName(defaultName string, inputName string) string {
	var name string
	if len(defaultName) > 0 {
		name = defaultName
	} else {
		name = "default-vpn-tunnel"
	}
	if len(inputName) > 0 {
		name = inputName
	}
	pterm.Info.Printf("GCE network VPN tunnel name: '%s'\n", name)
	return name
}

func CalcComputeNetworkVpnTunnel(pricingYml StructPricing, inputName string, inputRegion string, inputDiscount float32) float32 {
	name := returnComputeNetworkVpnTunnelName("", inputName)
	cost := CostComputeNetworkVpnTunnel(pricingYml, inputRegion)
	discount, discountText := returnDiscount(inputDiscount)
	price := Month(cost)*discount
	pterm.Info.Printf("Price '%s' tunnel per month: $%.2f %s\n", name, price, discountText)
	if price > 0 {
		LineItems = append(LineItems, LineItem{
			File: File,
			Project: Project,
			Region: inputRegion,
			Name: name,
			Type: "vpn-tunnel",
			Resource: "network",
			Discount: discount,
			Cost: price,
		})
	}
	return price
}

// Google Cloud internet egress traffic

func CostComputeNetworkTrafficEgressTiB0_1(pricingYml StructPricing, inputRegion string) Cost {
	cost, ok := pricingYml.Compute.Network.Traffic.Egress.Internet.Cost.TiB0_1[inputRegion]
	if ok {
		pterm.Success.Printf("Google Cloud internet egress traffic (0-1 TiB) in region '%s' found.\n", inputRegion)
	} else {
		pterm.Error.Printf("Google Cloud internet egress traffic (0-1 TiB) in region '%s' not found!\n", inputRegion)
		os.Exit(1)
	}
	return cost
}

func CostComputeNetworkTrafficEgressTiB1_10(pricingYml StructPricing, inputRegion string) Cost {
	cost, ok := pricingYml.Compute.Network.Traffic.Egress.Internet.Cost.TiB1_10[inputRegion]
	if ok {
		pterm.Success.Printf("Google Cloud internet egress traffic (1-10 TiB) in region '%s' found.\n", inputRegion)
	} else {
		pterm.Error.Printf("Google Cloud internet egress traffic (1-10 TiB) in region '%s' not found!\n", inputRegion)
		os.Exit(1)
	}
	return cost
}

func CostComputeNetworkTrafficEgressTiB10n(pricingYml StructPricing, inputRegion string) Cost {
	cost, ok := pricingYml.Compute.Network.Traffic.Egress.Internet.Cost.TiB10n[inputRegion]
	if ok {
		pterm.Success.Printf("Google Cloud internet egress traffic (10n TiB) in region '%s' found.\n", inputRegion)
	} else {
		pterm.Error.Printf("Google Cloud internet egress traffic (10n TiB) in region '%s' not found!\n", inputRegion)
		os.Exit(1)
	}
	return cost
}

// Google Cloud internet egress traffic with China destinations

func CostComputeNetworkTrafficEgressChinaTiB0_1(pricingYml StructPricing, inputRegion string) Cost {
	cost, ok := pricingYml.Compute.Network.Traffic.Egress.Internet.China.Cost.TiB0_1[inputRegion]
	if ok {
		pterm.Success.Printf("Internet egress traffic (0-1 TiB) with China destinations in region '%s' found.\n", inputRegion)
	} else {
		pterm.Error.Printf("Internet egress traffic (0-1 TiB) with China destinations in region '%s' not found!\n", inputRegion)
		os.Exit(1)
	}
	return cost
}

func CostComputeNetworkTrafficEgressChinaTiB1_10(pricingYml StructPricing, inputRegion string) Cost {
	cost, ok := pricingYml.Compute.Network.Traffic.Egress.Internet.China.Cost.TiB1_10[inputRegion]
	if ok {
		pterm.Success.Printf("Internet egress traffic (1-10 TiB) with China destinations in region '%s' found.\n", inputRegion)
	} else {
		pterm.Error.Printf("Internet egress traffic (1-10 TiB) with China destinations in region '%s' not found!\n", inputRegion)
		os.Exit(1)
	}
	return cost
}

func CostComputeNetworkTrafficEgressChinaTiB10n(pricingYml StructPricing, inputRegion string) Cost {
	cost, ok := pricingYml.Compute.Network.Traffic.Egress.Internet.China.Cost.TiB10n[inputRegion]
	if ok {
		pterm.Success.Printf("Internet egress traffic (10n TiB) with China destinations in region '%s' found.\n", inputRegion)
	} else {
		pterm.Error.Printf("Internet egress traffic (10n TiB) with China destinations in region '%s' not found!\n", inputRegion)
		os.Exit(1)
	}
	return cost
}

// Google Cloud internet egress traffic with Australia destinations

func CostComputeNetworkTrafficEgressAustraliaTiB0_1(pricingYml StructPricing, inputRegion string) Cost {
	cost, ok := pricingYml.Compute.Network.Traffic.Egress.Internet.Australia.Cost.TiB0_1[inputRegion]
	if ok {
		pterm.Success.Printf("Internet egress traffic (0-1 TiB) with Australia destinations in region '%s' found.\n", inputRegion)
	} else {
		pterm.Error.Printf("Internet egress traffic (0-1 TiB) with Australia destinations in region '%s' not found!\n", inputRegion)
		os.Exit(1)
	}
	return cost
}

func CostComputeNetworkTrafficEgressAustraliaTiB1_10(pricingYml StructPricing, inputRegion string) Cost {
	cost, ok := pricingYml.Compute.Network.Traffic.Egress.Internet.Australia.Cost.TiB1_10[inputRegion]
	if ok {
		pterm.Success.Printf("Internet egress traffic (1-10 TiB) with Australia destinations in region '%s' found.\n", inputRegion)
	} else {
		pterm.Error.Printf("Internet egress traffic (1-10 TiB) with Australia destinations in region '%s' not found!\n", inputRegion)
		os.Exit(1)
	}
	return cost
}

func CostComputeNetworkTrafficEgressAustraliaTiB10n(pricingYml StructPricing, inputRegion string) Cost {
	cost, ok := pricingYml.Compute.Network.Traffic.Egress.Internet.Australia.Cost.TiB10n[inputRegion]
	if ok {
		pterm.Success.Printf("Internet egress traffic (10n TiB) with Australia destinations in region '%s' found.\n", inputRegion)
	} else {
		pterm.Error.Printf("Internet egress traffic (10n TiB) with Australia destinations in region '%s' not found!\n", inputRegion)
		os.Exit(1)
	}
	return cost
}

func returnComputeNetworkTrafficEgressName(defaultName string, inputName string) string {
	var name string
	if len(defaultName) > 0 {
		name = defaultName
	} else {
		name = "default-internet-traffic"
	}
	if len(inputName) > 0 {
		name = inputName
	}
	pterm.Info.Printf("Internet egress traffic name: '%s'\n", name)
	return name
}

func CalcComputeNetworkTrafficEgress(pricingYml StructPricing, inputName string, inputWorld float32, inputChina float32, inputAustralia float32, inputRegion string, inputDiscount float32) float32 {
	name := returnComputeNetworkTrafficEgressName("", inputName)
	discount, discountText := returnDiscount(inputDiscount)
	var range1 float32 = 1024 // 0-1 TiB
	var range2 float32 = 10240 // 1-10 TiB
	var price float32
	if inputWorld > 0 {
		// 0-1 TiB
		month1 := Month(CostComputeNetworkTrafficEgressTiB0_1(pricingYml, inputRegion))
		monthRange1 := range1*month1
		// 1-10 TiB
		month2 := Month(CostComputeNetworkTrafficEgressTiB1_10(pricingYml, inputRegion))
		monthRange2 := (range2-range1)*month2
		// 10n TiB
		month3 := Month(CostComputeNetworkTrafficEgressTiB10n(pricingYml, inputRegion))
		var priceTraffic float32
		if (inputWorld > range2) {
			priceTraffic = (inputWorld-range2)*month3
			priceTraffic = priceTraffic + monthRange2 + monthRange1
		} else if inputWorld > range1 {
			priceTraffic = (inputWorld-range1)*month2
			priceTraffic = priceTraffic + monthRange1
		} else {
			priceTraffic = inputWorld*month1
		}
		priceTraffic = priceTraffic*discount
		pterm.Info.Printf("Price '%s' %.2f GiB traffic per month: $%.2f %s\n", name, inputWorld, priceTraffic, discountText)
		if priceTraffic > 0 {
			LineItems = append(LineItems, LineItem{
				File: File,
				Project: Project,
				Region: inputRegion,
				Name: name,
				Data: inputWorld,
				Type: "traffic",
				Resource: "network",
				Discount: discount,
				Cost: priceTraffic,
			})
		}
		price = price + priceTraffic
	}
	if inputChina > 0 {
		// 0-1 TiB
		month1 := Month(CostComputeNetworkTrafficEgressChinaTiB0_1(pricingYml, inputRegion))
		monthRange1 := range1*month1
		// 1-10 TiB
		month2 := Month(CostComputeNetworkTrafficEgressChinaTiB1_10(pricingYml, inputRegion))
		monthRange2 := (range2-range1)*month2
		// 10n TiB
		month3 := Month(CostComputeNetworkTrafficEgressChinaTiB10n(pricingYml, inputRegion))
		var priceTraffic float32
		if (inputChina > range2) {
			priceTraffic = (inputChina-range2)*month3
			priceTraffic = priceTraffic + monthRange2 + monthRange1
		} else if inputWorld > range1 {
			priceTraffic = (inputChina-range1)*month2
			priceTraffic = priceTraffic + monthRange1
		} else {
			priceTraffic = inputChina*month1
		}
		priceTraffic = priceTraffic*discount
		pterm.Info.Printf("Price '%s' %.2f GiB traffic w. CN dest. per month: $%.2f %s\n", name, inputChina, priceTraffic, discountText)
		if priceTraffic > 0 {
			LineItems = append(LineItems, LineItem{
				File: File,
				Project: Project,
				Region: inputRegion,
				Name: name,
				Data: inputChina,
				Type: "traffic-cn",
				Resource: "network",
				Discount: discount,
				Cost: priceTraffic,
			})
		}
		price = price + priceTraffic
	}
	if inputAustralia > 0 {
		// 0-1 TiB
		month1 := Month(CostComputeNetworkTrafficEgressAustraliaTiB0_1(pricingYml, inputRegion))
		monthRange1 := range1*month1
		// 1-10 TiB
		month2 := Month(CostComputeNetworkTrafficEgressAustraliaTiB1_10(pricingYml, inputRegion))
		monthRange2 := (range2-range1)*month2
		// 10n TiB
		month3 := Month(CostComputeNetworkTrafficEgressAustraliaTiB10n(pricingYml, inputRegion))
		var priceTraffic float32
		if (inputAustralia > range2) {
			priceTraffic = (inputAustralia-range2)*month3
			priceTraffic = priceTraffic + monthRange2 + monthRange1
		} else if inputWorld > range1 {
			priceTraffic = (inputAustralia-range1)*month2
			priceTraffic = priceTraffic + monthRange1
		} else {
			priceTraffic = inputAustralia*month1
		}
		priceTraffic = priceTraffic*discount
		pterm.Info.Printf("Price '%s' %.2f GiB traffic w. AU dest. per month: $%.2f %s\n", name, inputAustralia, priceTraffic, discountText)
		if priceTraffic > 0 {
			LineItems = append(LineItems, LineItem{
				File: File,
				Project: Project,
				Region: inputRegion,
				Name: name,
				Data: inputAustralia,
				Type: "traffic-au",
				Resource: "network",
				Discount: discount,
				Cost: priceTraffic,
			})
		}
		price = price + priceTraffic
	}
	pterm.Info.Printf("Price '%s' total internet egress traffic per month: $%.2f %s\n", name, price, discountText)
	return price
}