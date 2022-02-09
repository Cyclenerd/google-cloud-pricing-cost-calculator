#!/usr/bin/env bash

if ! perl ../gcosts.pl -pricing=../build/pricing.yml; then
	echo "🔥 ERROR"
	exit 9
fi