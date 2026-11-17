#!/bin/bash

ADOPT_FILE="/home/ktl/ADOPT.url"

if [ ! -f "$ADOPT_FILE" ]; then
    #not configured
    #display ip and error
    cd /home/ktl/rpi-rgb-led-matrix/examples-api-use/ || exit 1
    IP=$(hostname -I | awk '{print $1}') 
    sudo ./scrolling-text-example -s 1 -f ../8x13.bdf --led-cols 64 --led-rows 32 "Awaiting connection, IP: $IP"
else 
    # configured
    # read url in ADOPT.url

    echo "starting screen capture (runchrome/run2.js)"
    cd /home/ktl/runchrome || exit 1

    ADOPT_URL=$(tr -d '\r\n' < /home/ktl/ADOPT.url)
    echo "Starting screen capture: $ADOPT_URL"
    node runLEDWatcher.js "$ADOPT_URL" &
    NODE_PID=$!

    echo "Starting lcd screen display (double_buffering_auto_update.py)"
    cd /home/ktl || exit 1
    #sudo python3 double_buffering_auto_update.py &
    sudo /home/ktl/venv/bin/python3 double_buffering_auto_update.py &

    PYTHON_PID=$!

     cleanup() {
        sudo kill "$PYTHON_PID" 2>/dev/null || true
        kill "$NODE_PID" 2>/dev/null || true
        wait "$PYTHON_PID" 2>/dev/null || true
        wait "$NODE_PID" 2>/dev/null || true
    }

    trap cleanup EXIT
    trap 'exit 0' INT TERM

    wait
fi


