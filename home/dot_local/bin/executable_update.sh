#!/bin/bash
# update.sh — Run periodically to update all tools.

echo "=== Updating mise ==="
mise self-update

echo "=== Updating mise tools ==="
mise upgrade

echo "=== Updating RTK ==="
rtk upgrade

echo "=== Updating npm globals ==="
npm update -g
