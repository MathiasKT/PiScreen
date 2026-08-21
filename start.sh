#!/bin/bash

echo "starting screen capture (runchrome/run2.js)"
cd /home/ktl/runchrome || exit 1
node run2.js &
NODE_PID=$!

echo "Starting lcd screen display (double_buffering_auto_update.py)"
cd /home/ktl || exit 1
sudo python3 double_buffering_auto_update.py &
PYTHON_PID=$!




trap 'sudo kill $PYTHON_PID 2>/dev/null; kill $NODE_PID 2>/dev/null' EXIT INT TERM

wait
