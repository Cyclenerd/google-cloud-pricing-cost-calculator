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
	"path/filepath"
	"github.com/spf13/cobra"
	"github.com/pterm/pterm"
)

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "gcosts",
	Version: "v3.0.0",
	Short: "Calculate and save the costs of Google Cloud Platform products and resources.",
	Long: `Calculate estimated monthly costs of Google Cloud Platform products and resources.

Optimized for 
* DevOps,
* architects and 
* engineers
to quickly see a cost breakdown and compare different options upfront.

More help: <https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator>`,
	// PersistentPreRun: children of this command will inherit and execute.
	PersistentPreRun: func(cmd *cobra.Command, args []string) {
		pterm.DefaultHeader.WithFullWidth().Println("💸 gcosts - Google Cloud Platform Pricing and Cost Calculator")
	},
	// PersistentPostRun: children of this command will inherit and execute after PostRun.
	/*PersistentPostRun: func(cmd *cobra.Command, args []string) {
		pterm.Success.Println("Tschuess")
	},*/
	// Uncomment the following line if your bare application
	// has an action associated with it:
	//Run: func(cmd *cobra.Command, args []string) { },
}

var defaultDir string // current working directory
var defaultPricing string // pricing.yml in current working directory
var defaultExportCsv string // costs.csv in current working directory

var defaultRegion string = "us-central1"
var defaultProject string = "default-project-id"
var defaultDiscount float32 = 0.0000

var inputPricing string
var inputUsageDir string
var inputExportCsv string
var inputRegion string
var inputStorageClass string
var inputDiskType string
var inputMachineType string
var inputOperatingSystem string

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

func init() {
	// current working directory
	dir, err := os.Getwd()
	if err != nil {
		pterm.Error.Println(err)
	}

	// Set defaults
	defaultDir = dir
	defaultPricing = filepath.Join(dir, "pricing.yml")
	defaultExportCsv = filepath.Join(dir, "costs.csv")

	// Here you will define your flags and configuration settings.
	// Cobra supports persistent flags, which, if defined here,
	// will be global for your application.
	rootCmd.PersistentFlags().StringVarP(&inputPricing, "pricing", "p", defaultPricing, "YAML file with GCP pricing informations")
}