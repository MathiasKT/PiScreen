const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

//const TARGET_URL = 'https://flipclock.us';
const TARGET_URL = 'http://192.168.2.1:10002/device/LED2/9415';
const OUTPUT_DIR = '/home/ktl/screen-display-files';
const CHECK_INTERVAL_MS = 1000; 
const SCREEN_WIDTH = 768;
const SCREEN_HEIGHT = 192;
const FILES_TO_KEEP = 10;

if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

(async () => {
    console.log('Starting headless browser...');

    const browser = await puppeteer.launch({
        headless: true,
        executablePath: '/usr/bin/chromium',
        timeout: 60000,
	args: [
	    '--kiosk',
	    '--no-first-run',
	    '--no-default-browser-check',
	    '--disable-infobars',
            '--no-sandbox',
            '--disable-setuid-sandbox',
	    '--disable-gpu'
        ]
    });

    const page = await browser.newPage();

    await page.setViewport({
        width: SCREEN_WIDTH,
        height: SCREEN_HEIGHT
    });

    console.log(`Loading ${TARGET_URL}...`);

    // Load the page ONCE
    await page.goto(TARGET_URL, {
        waitUntil: 'networkidle2'
    });

    console.log('Page loaded.');

    let previousImageBuffer = null;

    async function checkScreen() {
        try {
            const currentImageBuffer = await page.screenshot({
                type: 'png'
            });

            // First screenshot
            if (!previousImageBuffer) {
                console.log('Initial screenshot detected.');
                saveScreenshot(currentImageBuffer);
                previousImageBuffer = currentImageBuffer;
                return;
            }

            // Check whether screenshot changed
            if (!previousImageBuffer.equals(currentImageBuffer)) {
                console.log('Screen changed!');

                saveScreenshot(currentImageBuffer);

                previousImageBuffer = currentImageBuffer;
            }

        } catch (error) {
            console.error('Screenshot error:', error.message);
        }
    }

    function saveScreenshot(imageBuffer) {
        const timestamp = Date.now();

        const filename = `screen_${timestamp}.png`;
        const filepath = path.join(OUTPUT_DIR, filename);

        fs.writeFileSync(filepath, imageBuffer);

        console.log(`Saved: ${filepath}`);

        cleanupOldFiles();
    }

    function cleanupOldFiles() {
        const files = fs.readdirSync(OUTPUT_DIR)
            .map(name => path.join(OUTPUT_DIR, name))
            .filter(file => {
                try {
                    return fs.lstatSync(file).isFile();
                } catch {
                    return false;
                }
            })
            .sort((a, b) => {
                return fs.lstatSync(b).ctimeMs -
                       fs.lstatSync(a).ctimeMs;
            });

        // Keep x newest files
        if (files.length > FILES_TO_KEEP) {
            files.slice(5).forEach(file => {
                try {
                    fs.unlinkSync(file);
                    console.log(`Deleted: ${file}`);
                } catch (error) {
                    console.error(
                        `Failed to delete ${file}:`,
                        error.message
                    );
                }
            });
        }
    }

    // Check every x
    setInterval(checkScreen, CHECK_INTERVAL_MS);

    // First check immediately
    await checkScreen();

})();
