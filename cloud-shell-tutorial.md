# How to set up GCP Cost Calculator

## Welcome 👋!

In this tutorial, you are going to set up [Google Cloud Platform Pricing and Cost Calculator](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator) on Google Cloud Shell.

<walkthrough-tutorial-duration duration="10"></walkthrough-tutorial-duration>

Click the **Start** button to move to the next step.

## Get `gcosts` program

Download the executable `gcosts` Linux CLI program and save it to your home folder:
```bash
curl -L "https://bit.ly/gcosts" \
     -o ~/gcosts
```

Make it executable:
```bash
chmod +x ~/gcosts
```

Test:
```bash
~/gcosts --help
```

## Download price information

Download the latest and tested price information file `pricing.yml` and save it to your home folder:
```bash
curl -L "https://bit.ly/pricing_yml" \
     -o ~/pricing.yml
```

## Add alias

Add `gcosts` to your Bash aliases with absolute pathnames:
```bash
echo "alias gcosts='$HOME/gcosts -pricing=$HOME/pricing.yml'" >> ~/.bash_aliases
```

Reload aliases:
```bash
source ~/.bash_aliases
```

You can then execute `gcosts`:
```bash
gcosts --help
```

## First usage file

Create your first YAML usage file.
To make it easier for you, you can use the prepared example.

Change to the directory `usage`:
```bash
cd usage
```

Edit the file `example.yml`:
```bash
edit example.yml
```

<walkthrough-editor-open-file filePath="cloudshell_open/google-cloud-pricing-cost-calculator/usage/example.yml">Edit example.yml</walkthrough-editor-open-file>

## Run it

Run `gcosts` in the current folder.
All YAML usage files (`*.yml`) of the current directory are imported and the costs of the resources are calculated:
```bash
gcosts
```

## Download

Two CSV (semicolon) files with the costs are created:

1. `COSTS.csv`  : Costs for the resources
1. `TOTALS.csv` : Total costs per name, resource, project, region and file.

Download the CSV files:
```bash
dl COSTS.csv TOTALS.csv
```

You can import the CSV files with MS Excel, LibreOffice or Google Sheets.

## Done 🎉

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

Continue to familiarize yourself with the options.
The following documentations are prepared for this purpose:

* [Create usage files](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/tree/master/usage)
* [Build pricing information file](https://github.com/Cyclenerd/google-cloud-pricing-cost-calculator/tree/master/build)