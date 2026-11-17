#!/bin/bash
set -e

echo "=== 1) Installing System Dependencies ==="
#sudo apt update
sudo apt install -y chromium-browser=1:148.0.7778.167-1~deb12u1+rpt1  python3-opencv=4.10.0+dfsg-5 python3-pil=11.1.0-5+deb13u4 nodejs=20.19.2+dfsg-1+deb13u3 npm=9.2.0~ds1-3 git=1:2.47.3-0+deb13u1 python-dev-is-python3=3.13.3-1 cython3=3.0.11+dfsg-2+b1 python3-pip=25.1.1+dfsg-1 python3-setuptools=78.1.1-0.1 python3-venv=3.13.5-1

echo "=== 2) Setting up Directories ==="
mkdir -p /home/ktl/runchrome
mkdir -p /home/ktl/screen-display-files

echo "=== 3) Copying Files ==="
cp double_buffering_auto_update.py /home/ktl/
cp -r runchrome/* /home/ktl/runchrome/

echo "=== 4) Installing NPM Packages ==="
cd /home/ktl/runchrome
npm install puppeteer

echo "=== 5) Setup https://github.com/hzeller/rpi-rgb-led-matrix ==="
cd /home/ktl

if [ ! -d "/home/ktl/rpi-rgb-led-matrix" ]; then
    git clone https://github.com/hzeller/rpi-rgb-led-matrix.git
fi

cd rpi-rgb-led-matrix
git checkout b449780d17c0ed6fcd293f9c808105b83cfe78fc



echo "=== 6) Creating Python venv ==="
python3 -m venv --system-site-packages /home/ktl/venv

echo "=== 7) Installing rgbmatrix into venv ==="
/home/ktl/venv/bin/python -m pip install .

#sudo PIP_BREAK_SYSTEM_PACKAGES=1 python3 -m pip install .
echo "=== 8) Make startLED.sh executable ==="
sudo chmod +x /home/ktl/PIScreen/startLED.sh

echo "=== 9) Creating System services ==="
# After = network connected
# Restart = restart on exit
# StartLimitIntervalSec = how many times to fail starting before exiting default 10
sudo tee /etc/systemd/system/PiDisplay.service > /dev/null <<'EOF'
[Unit]
Description=Pi led service
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
WorkingDirectory=/home/ktl
Restart=always
RestartSec=2.5
User=ktl
ExecStart=/home/ktl/startLED.sh

[Install]
WantedBy=multi-user.target"
EOF

echo "=== 10) Enabling and Starting Service ==="
sudo systemctl daemon-reload
systemctl start PiDisplay
systemctl enable PiDisplay

echo "*************************"
echo "***** Setup Complete ****"
echo "*************************"
