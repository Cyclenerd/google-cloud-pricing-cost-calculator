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
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/pterm/pterm"
	"github.com/spf13/cobra"
)

var version string = "v?.?.?"

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:     "gcosts",
	Version: version,
	Short:   "Calculate and save the costs of Google Cloud Platform products and resources.",
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

		// Handle pricing file download if requested
		if downloadPricing {
			inputPricing = ensurePricingFile()
		}
	},
	// PersistentPostRun: children of this command will inherit and execute after PostRun.
	/*PersistentPostRun: func(cmd *cobra.Command, args []string) {
		pterm.Success.Println("Tschuess")
	},*/
	// Uncomment the following line if your bare application
	// has an action associated with it:
	//Run: func(cmd *cobra.Command, args []string) { },
}

var defaultDir string       // current working directory
var defaultPricing string   // pricing.yml in current working directory
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

// Download-related variables
var downloadPricing bool
var pricingFileURL string
var forceRedownload bool

// getCachedPricingPath returns the path for the cached pricing file
func getCachedPricingPath() string {
	year, week := time.Now().ISOWeek()
	return fmt.Sprintf("/tmp/pricing_%d%02d", year, week)
}

// downloadPricingFile downloads the pricing file from the given URL and saves it to the specified path
func downloadPricingFile(url, filepath string) error {
	pterm.Info.Printf("Downloading pricing file from: %s\n", url)

	resp, err := http.Get(url)
	if err != nil {
		return fmt.Errorf("failed to download pricing file: %w", err)
	}
	defer func() {
		if closeErr := resp.Body.Close(); closeErr != nil {
			pterm.Warning.Printf("Failed to close response body: %v\n", closeErr)
		}
	}()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("failed to download pricing file: HTTP %d", resp.StatusCode)
	}

	file, err := os.Create(filepath)
	if err != nil {
		return fmt.Errorf("failed to create pricing file: %w", err)
	}
	defer func() {
		if closeErr := file.Close(); closeErr != nil {
			pterm.Warning.Printf("Failed to close file: %v\n", closeErr)
		}
	}()

	_, err = io.Copy(file, resp.Body)
	if err != nil {
		return fmt.Errorf("failed to write pricing file: %w", err)
	}

	pterm.Success.Printf("Pricing file downloaded successfully to: %s\n", filepath)
	return nil
}

// ensurePricingFile ensures the pricing file is available, downloading it if necessary
func ensurePricingFile() string {
	if !downloadPricing {
		return inputPricing
	}

	cachedPath := getCachedPricingPath()

	// Check if file exists and we're not forcing redownload
	if !forceRedownload {
		if _, err := os.Stat(cachedPath); err == nil {
			pterm.Info.Printf("Using cached pricing file: %s\n", cachedPath)
			return cachedPath
		}
	}

	// Download the file
	err := downloadPricingFile(pricingFileURL, cachedPath)
	if err != nil {
		pterm.Error.Printf("Failed to download pricing file: %v\n", err)
		pterm.Warning.Println("Falling back to default pricing file")
		return inputPricing
	}

	return cachedPath
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

func init() {
	// Disable the default completion command:
	rootCmd.CompletionOptions.DisableDefaultCmd = true

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

	// Download-related flags
	rootCmd.PersistentFlags().BoolVarP(&downloadPricing, "download", false, "Download and cache pricing file automatically")
	rootCmd.PersistentFlags().StringVar(&pricingFileURL, "pricing-file-url", "https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/raw/master/pricing.yml", "URL for pricing file if different than default")
	rootCmd.PersistentFlags().BoolVar(&forceRedownload, "force-redownload", false, "Force redownload of pricing file even if it exists")
}
