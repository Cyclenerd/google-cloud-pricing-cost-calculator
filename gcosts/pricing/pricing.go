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
	"gopkg.in/yaml.v3"
)

var CostSum float32

type Region struct {
	Location string
}

type DualRegion struct {
	Regions []string
}

type MultiRegion struct {
	Description string
}

type Bucket struct {
	Cost map[string]Cost
}

type Storage struct {
	Type string
	Cost map[string]Cost
}

type Instance struct {
	Cpu float32
	Ram float32
	Cost map[string]Cost
}

type License struct {
	Cost map[string]Cost
}

type Cost struct {
	Hour float32
	HourSpot float32 `yaml:"hour_spot"`
	Month float32
	Month1Y float32 `yaml:"month_1y"`
	Month3Y float32 `yaml:"month_3y"`
	MonthSpot float32 `yaml:"month_spot"`
}

type StructPricing struct {
	About struct {
		Copyright string
		Generated string
		Timestamp string
		Url string
	}
	Region map[string]Region
	DualRegion map[string]DualRegion `yaml:"dual-region"`
	MultiRegion map[string]MultiRegion `yaml:"multi-region"`
	Monitoring struct {
		Data struct {
			Cost struct {
				MiB0_100000 map[string]Cost `yaml:"0-100000"`
				MiB0_100000_250000 map[string]Cost `yaml:"100000-250000"`
				MiB0_250000n map[string]Cost `yaml:"250000n"`
			}
		}
	}
	Storage struct {
		Bucket map[string]Bucket
	}
	Compute struct {
		Storage map[string]Storage
		Instance map[string]Instance
		License map[string]License
		Network struct {
			Ip struct {
				Unused struct {
					Cost map[string]Cost
				}
				Vm struct {
					Cost map[string]Cost
				}
			}
			Vpn struct {
				Tunnel struct {
					Cost map[string]Cost
				}
			}
			Nat struct {
				Gateway struct {
					Cost map[string]Cost
				}
				Data struct {
					Cost map[string]Cost
				}
			}
			Traffic struct {
				Egress struct {
					Internet struct {
						China struct {
							Cost struct {
								TiB0_1 map[string]Cost `yaml:"0-1"`
								TiB1_10 map[string]Cost `yaml:"1-10"`
								TiB10n map[string]Cost `yaml:"10n"`
							}
						}
						Australia struct {
							Cost struct {
								TiB0_1 map[string]Cost `yaml:"0-1"`
								TiB1_10 map[string]Cost `yaml:"1-10"`
								TiB10n map[string]Cost `yaml:"10n"`
							}
						}
						Cost struct {
							TiB0_1 map[string]Cost `yaml:"0-1"`
							TiB1_10 map[string]Cost `yaml:"1-10"`
							TiB10n map[string]Cost `yaml:"10n"`
						}
					}
				}
			}
		}
	}
}

func readPricingYmlFile(file string) []byte {
	pterm.Info.Printf("YAML file with GCP pricing informations: '%s'\n", file)
	f, err := os.ReadFile(file)
	if err != nil {
		pterm.Error.Println(err)
		os.Exit(9)
	}
	return f
}

func Yml(file string) StructPricing {
	filecontent := readPricingYmlFile(file)

	s := StructPricing{}
	err := yaml.Unmarshal([]byte(filecontent), &s)
	if err != nil {
		pterm.Error.Println(err)
		os.Exit(8)
	}

	return s
}
