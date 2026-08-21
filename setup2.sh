#!/bin/bash
set -e

echo "=== Installing System Dependencies ==="
sudo apt update
sudo apt install -y chromium-browser python3-opencv python3-pil nodejs npm git python-dev-is-python3 cython3 python3-setuptools

echo "=== Setting up Directories ==="
mkdir -p /home/ktl/runchrome
mkdir -p /home/ktl/screen-display-files

echo "=== Copying Files ==="
cp double_buffering_auto_update.py /home/ktl/
cp -r runchrome/* /home/ktl/runchrome/

echo "=== Installing NPM Packages ==="
cd /home/ktl/runchrome
npm install puppeteer

echo "=== Setup https://github.com/hzeller/rpi-rgb-led-matrix ==="
cd /home/ktl

if [ ! -d "/home/ktl/rpi-rgb-led-matrix" ]; then
    git clone https://github.com/hzeller/rpi-rgb-led-matrix.git
fi

cd rpi-rgb-led-matrix
git checkout b449780d17c0ed6fcd293f9c808105b83cfe78fc


make build-python PYTHON=$(which python3)
sudo make install-python PYTHON=$(which python3)


echo "=== Setup Complete! ==="
