#!/bin/bash

ADOPT_FILE="/home/ktl/ADOPT.url"
POLL_SECONDS=2

NODE_PID=""
PYTHON_PID=""
SCROLL_PID=""

read_url() {
    if [ -f "$ADOPT_FILE" ]; then
        tr -d '\r\n' < "$ADOPT_FILE"
    fi
}

stop_all() {
    if [ -n "$SCROLL_PID" ]; then
        sudo kill "$SCROLL_PID" 2>/dev/null || true
        wait "$SCROLL_PID" 2>/dev/null || true
        sudo pkill -f scrolling-text-example 2>/dev/null || true
        SCROLL_PID=""
    fi
    if [ -n "$PYTHON_PID" ]; then
        sudo kill "$PYTHON_PID" 2>/dev/null || true
        wait "$PYTHON_PID" 2>/dev/null || true
        sudo pkill -f double_buffering_auto_update.py 2>/dev/null || true
        PYTHON_PID=""
    fi
    if [ -n "$NODE_PID" ]; then
        kill "$NODE_PID" 2>/dev/null || true
        wait "$NODE_PID" 2>/dev/null || true
        NODE_PID=""
    fi
}

start_scroller() {
    echo "Not configured, showing IP"
    IP=$(hostname -I | awk '{print $1}')
    (
        cd /home/ktl/rpi-rgb-led-matrix/examples-api-use/ || exit 1
        exec sudo ./scrolling-text-example -s 1 -f ../fonts/8x13.bdf \
            --led-cols 64 --led-rows 32 --led-no-hardware-pulse \
            --led-slowdown-gpio 4 --led-chains 2 --led-parallel 3 \
            "Awaiting connection, IP: $IP"
    ) &
    SCROLL_PID=$!
}

start_display() {
    local url="$1"
    echo "Starting screen capture: $url"
    (
        cd /home/ktl/runchrome || exit 1
        exec node runLEDWatcher.js "$url"
    ) &
    NODE_PID=$!

    echo "Starting LED display (double_buffering_auto_update.py)"
    (
        cd /home/ktl || exit 1
        exec sudo /home/ktl/venv/bin/python3 double_buffering_auto_update.py
    ) &
    PYTHON_PID=$!
}

trap stop_all EXIT
trap 'exit 0' INT TERM

CURRENT_URL="__init__"

while true; do
    NEW_URL=$(read_url)

    # If we're configured but a child died, force a restart
    if [ -n "$CURRENT_URL" ] && [ "$CURRENT_URL" != "__init__" ]; then
        if [ ! -d "/proc/$NODE_PID" ] || [ ! -d "/proc/$PYTHON_PID" ]; then
            echo "A child process exited, restarting"
            CURRENT_URL="__restart__"
        fi
    fi

    if [ "$NEW_URL" != "$CURRENT_URL" ]; then
        echo "State changed: '$CURRENT_URL' -> '$NEW_URL'"
        stop_all
        CURRENT_URL="$NEW_URL"

        if [ -z "$NEW_URL" ]; then
            start_scroller
        else
            start_display "$NEW_URL"
        fi
    fi

    sleep "$POLL_SECONDS"
done