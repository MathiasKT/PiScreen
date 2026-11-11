#!/bin/bash
set -e

echo "=== Installing System Dependencies ==="
#sudo apt update
sudo apt install -y chromium-browser=1:148.0.7778.167-1~deb12u1+rpt1  python3-opencv=4.10.0+dfsg-5 python3-pil=11.1.0-5+deb13u4 nodejs=20.19.2+dfsg-1+deb13u2 npm=9.2.0~ds1-3 git=1:2.47.3-0+deb13u1 python-dev-is-python3=3.13.3-1 cython3=3.0.11+dfsg-2+b1 python3-setuptools=78.1.1-0.1

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


echo "=== Setup Complete ==="
