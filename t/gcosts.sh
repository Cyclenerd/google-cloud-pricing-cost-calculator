#!/usr/bin/env bash

if ! ./../gcosts/gcosts calc --pricing=../build/pricing.yml; then
	echo "🔥 ERROR"
	exit 9
fi