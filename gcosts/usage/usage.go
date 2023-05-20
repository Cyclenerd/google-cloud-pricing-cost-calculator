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
package usage

import (
	"github.com/pterm/pterm"
	"gopkg.in/yaml.v3"
	"os"
)

type Instance struct {
	Name       string
	Type       string
	Region     string
	Discount   float32
	Commitment int
	Spot       bool
	Os         string
	ExternalIp int `yaml:"external-ip"`
	Disks      []Disk
	Buckets    []Bucket
	Terminated bool
}

type Disk struct {
	Name     string
	Type     string
	Region   string
	Discount float32
	Data     float32
}

type Bucket struct {
	Name     string
	Class    string
	Region   string
	Discount float32
	Data     float32
}

type VpnTunnel struct {
	Name     string
	Region   string
	Discount float32
}

type NatGateway struct {
	Name     string
	Region   string
	Discount float32
	Data     float32
}

type Monitoring struct {
	Name     string
	Region   string
	Discount float32
	Data     float32
}

type Traffic struct {
	Name      string
	Region    string
	Discount  float32
	World     float32
	China     float32
	Australia float32
}

type StructUsage struct {
	Region      string
	Project     string
	Discount    float32
	Instances   []Instance
	Disks       []Disk
	Buckets     []Bucket
	VpnTunnels  []VpnTunnel  `yaml:"vpn-tunnels"`
	NatGateways []NatGateway `yaml:"nat-gateways"`
	Monitoring  []Monitoring
	Traffic     []Traffic
}

func readUsageYmlFile(filepath string) []byte {
	f, err := os.ReadFile(filepath)
	if err != nil {
		pterm.Error.Println(err)
		os.Exit(9)
	}
	return f
}

func Yml(file string) StructUsage {
	filecontent := readUsageYmlFile(file)

	s := StructUsage{}
	err := yaml.Unmarshal([]byte(filecontent), &s)
	if err != nil {
		pterm.Error.Println("Usage YAML file could not be processed.\n" +
			"Please check the file structure and make sure that it is not another YAML file (like the price list).\n\n"+
			"For more help, please see:\n"+
			"  <https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/blob/master/usage/README.md>")
		pterm.Error.Println(err)
		os.Exit(8)
	}

	return s
}
