package main

import (
	"encoding/csv"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
)

func TestCalcCostDetails(t *testing.T) {
	binary := filepath.Join(t.TempDir(), "gcosts.exe")
	if output, err := exec.Command("go", "build", "-o", binary, ".").CombinedOutput(); err != nil {
		t.Fatalf("build gcosts: %v\n%s", err, output)
	}
	pricing, err := filepath.Abs("../pricing.yml")
	if err != nil {
		t.Fatal(err)
	}
	for _, tc := range []struct {
		name     string
		usage    string
		resource string
		detail   string
	}{
		{
			name:     "retrieval",
			usage:    "region: europe-west4\nbuckets:\n  - name: archive\n    class: nearline\n    data: 1000\n    retrieval: 300\n",
			resource: "retrieval",
			detail:   "Retrieval fee 'archive' '300.00' GiB per month: $%.2f",
		},
		{
			name:     "discounted retrieval",
			usage:    "region: europe-west4\ndiscount: 0.85\nbuckets:\n  - name: archive\n    class: nearline\n    data: 1000\n    retrieval: 300\n",
			resource: "retrieval",
			detail:   "Retrieval fee 'archive' '300.00' GiB per month: $%.2f",
		},
		{
			name:   "NAT units",
			usage:  "region: europe-west4\nnat-gateways:\n  - name: gateway\n    data: 300\n",
			detail: "Price 'gateway' 300.00 GiB NAT data per month:",
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			dir := t.TempDir()
			if err := os.WriteFile(filepath.Join(dir, "resources.yml"), []byte(tc.usage), 0600); err != nil {
				t.Fatal(err)
			}
			output, err := exec.Command(binary, "calc", "--dir", dir, "--pricing", pricing, "--csv", filepath.Join(dir, "costs.csv")).CombinedOutput()
			if err != nil {
				t.Fatalf("calc: %v\n%s", err, output)
			}
			want := tc.detail
			if tc.resource != "" {
				data, err := os.ReadFile(filepath.Join(dir, "costs.csv"))
				if err != nil {
					t.Fatal(err)
				}
				rows, err := csv.NewReader(strings.NewReader(string(data))).ReadAll()
				if err != nil {
					t.Fatal(err)
				}
				found := false
				for _, row := range rows[1:] {
					if row[2] == tc.resource {
						cost, err := strconv.ParseFloat(row[5], 32)
						if err != nil {
							t.Fatal(err)
						}
						want = fmt.Sprintf(tc.detail, cost)
						found = true
					}
				}
				if !found {
					t.Fatalf("CSV has no %s row", tc.resource)
				}
			}
			if !strings.Contains(string(output), want) {
				t.Fatalf("calc output does not contain %q:\n%s", want, output)
			}
		})
	}
}
