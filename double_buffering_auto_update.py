import os
import time
import glob
import sys
import cv2
from PIL import Image, ImageSequence
from rgbmatrix import RGBMatrix, RGBMatrixOptions

DISPLAY_FOLDER = "screen-display-files"
#DIMS = [32, 64]
DIMS = [64,128]

options = RGBMatrixOptions()
options.rows, options.cols = DIMS[0], DIMS[1]
options.hardware_mapping = "regular"
options.disable_hardware_pulsing =True
options.gpio_slowdown = 4
options.drop_privileges = False
options.chain_length =2
#options.chain_length = 1
#options.parallel = 1
#options.brightness = 0 - 100
#options.scan_mode = 0 or 1 
#options.multiplexing = 0 / 1/ 2

matrix = RGBMatrix(options=options)

def get_newest_file():
	files = glob.glob(os.path.join(DISPLAY_FOLDER,"*"))
	#print(f"found files:{files}")
	if not files:
		return None
	return max(files, key=os.path.getctime)


def check_file_ready(filepath):
	prev_size=-1
	while True:
		current_size = os.path.getsize(filepath)
		if current_size == prev_size and current_size >0:
			return True
		prev_size = current_size
		time.sleep(0.05)

def play_media(path,prev_ctime):
	ext = path.lower().split(".")[-1]
	canvas = matrix.CreateFrameCanvas()
	
	# if video
	if ext in  ["mp4", "mov", "mkv", "avi"]:
		cap = cv2.VideoCapture(path)
		fps = cap.get(cv2.CAP_PROP_FPS)
		
		if fps <=0:
			fps = 30.0

		frame_delay = 1.0/fps
		last_check_time = time.time()
		
		while True:
			start_time = time.time()
			if start_time - last_check_time > 0.5:
				new = get_newest_file()
				if new != path or os.path.getctime(path) != prev_ctime:
					cap.release()
					return
				last_check_time =  start_time

			
			ret, frame = cap.read()
			if not ret:
				cap.set(cv2.CAP_PROP_POS_FRAMES, 0)			
				continue

			frame_resized =  cv2.resize(frame, (matrix.width, matrix.height))
			frame_rgb = cv2.cvtColor(frame_resized, cv2.COLOR_BGR2RGB)
			image = Image.fromarray(frame_rgb)
			
			canvas.SetImage(image)
			canvas = matrix.SwapOnVSync(canvas)
			#matrix.SetImage(image)
			
			elapsed = time.time() - start_time
			sleep_time = frame_delay - elapsed
			if sleep_time > 0:
				time.sleep(sleep_time)

		
	else:
		#if img
		image = Image.open(path).convert("RGB").resize((matrix.width,matrix.height))
		#matrix.SetImage(image)
		canvas.SetImage(image)
		canvas = matrix.SwapOnVSync(canvas)
		while True:
			new = get_newest_file()
			if new != path or os.path.getctime(path) != prev_ctime:
				return
			time.sleep(1)

def start():
	#os.chdir("/home/ktl")	
	curr_file = None
	curr_play_time = 0
	print("curr pwd ", os.getcwd())
	try:
		matrix.Clear()
		while True:
			newest_file = get_newest_file()
			
			if newest_file:
				newest_time = os.path.getctime(newest_file)
	
				if newest_file != curr_file or newest_time != curr_play_time:
					print(f"playing new file {newest_file}")
					time.sleep(0.5)
					check_file_ready(newest_file)
					curr_file = newest_file
					curr_play_time = os.path.getctime(newest_file)
					#print("playing new file" )
					play_media(curr_file, curr_play_time)
			else:
				time.sleep(1)
	except Exception as e:
		# if downloading file to folder and  check_file fails 
		print(f"error: {e}")
		matrix.Clear()
		#sys.exit(0)
		start()

start()
