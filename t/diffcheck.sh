#!/usr/bin/env bash

#
# Check if more was deleted than added
# Used in build-pricing.yml GitHub Action
#

MY_ADD_COUNT=$(git diff --color=always ../pricing.yml | perl -wlne 'print $1 if /^\e\[32m\+\e\[m\e\[32m(.*)\e\[m$/' | wc -l )
MY_DEL_COUNT=$(git diff --color=always ../pricing.yml | perl -wlne 'print $1 if /^\e\[31m-(.*)\e\[m$/' | wc -l )

if [ "$MY_DEL_COUNT" -gt "$MY_ADD_COUNT" ]; then
	echo "🛑 ERROR: There was more deleted than added. $MY_DEL_COUNT vs. $MY_ADD_COUNT !!!"
	echo "          This should not be the case under normal circumstances."
	echo "          To be on the safe side, we better stop the pipeline at this point."
	exit 9
else
	echo "✅ OK: Not more deletions than additions. $MY_DEL_COUNT vs. $MY_ADD_COUNT."
fi