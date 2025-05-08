print("Hello World!")

import board
import busio
import fourwire
import displayio
import gc9a01

import time
import math
import terminalio
from adafruit_display_text import label

displayio.release_displays()
# Raspberry Pi Pico pinout, one possibility, at "southwest" of board
tft_clk = board.GP2 # must be a SPI CLK
tft_mosi= board.GP3 # must be a SPI TX
tft_rst = board.GP6
tft_dc  = board.GP4
tft_cs  = board.GP5  # optional, can be "None"
tft_bl  = None  # optional, can be "None"  
spi = busio.SPI(clock=tft_clk, MOSI=tft_mosi)

### https://github.com/todbot/CircuitPython_GC9A01_demos/blob/main/examples/gc9a01_helloworld.py
# Make the displayio SPI bus and the GC9A01 display
display_bus = displayio.FourWire(spi, command=tft_dc, chip_select=tft_cs, reset=tft_rst)
display = gc9a01.GC9A01(display_bus, width=240, height=240, backlight_pin=tft_bl)

# Make the main display context
main = displayio.Group()
display.root_group = main

# Draw a text label
text = "Loading\nFPGA"
text_area = label.Label(terminalio.FONT, text=text, color=0xFFFF00,
                        anchor_point=(0.5,0.5), anchored_position=(0,0))
text_group = displayio.Group(scale=2)
text_group.append(text_area) 
main.append(text_group)
text_group.x = 120 #+ int(r * math.sin(theta))
text_group.y = 120 #+ int(r * math.cos(theta))

# Animate the text 
theta = math.pi
r = 75
'''
while True:
    print(time.monotonic(),"hello")
    text_group.x = 120 + int(r * math.sin(theta))
    text_group.y = 120 + int(r * math.cos(theta))
    theta -= 0.05
    time.sleep(0.01)
'''


### ECP5 Programming #####################
import jtag
print("0x%08x" % jtag.idcode())

import ecp5p, digitalio, board 
jtag_rst = digitalio.DigitalInOut(board.GP20)
jtag_rst.direction = digitalio.Direction.OUTPUT
jtag_rst.value = False
time.sleep(0.1)
jtag_rst.value = True
ecp5p.prog("test.bit")

### Face ############################################
import random
#import asyncio, random
import board, busio, time, gc, os
import gc9a01, displayio, adafruit_imageload
#import bitmaptools, gifio, struct
# Load image
def load_image(img_filename):
    img_bitmap, img_palette = adafruit_imageload.load(img_filename)
    img_tilegrid = displayio.TileGrid(img_bitmap, pixel_shader=img_palette)
    main.append(img_tilegrid)
    del img_bitmap, img_palette

for i in range(1):
    load_image("/image/greymecha_angy.jpg")
    

while True:
    pass
'''
files = os.listdir("/image")
while F := random.choice(files):
    if F.lower().endswith('.jpg') or F.lower().endswith('.bmp'):
        load_image("/image/" + F)
        break
    if F.lower().endswith('.gif'):
        load_gif("/image/" + F)
        break
'''

### Programming
import jtag
print("0x%08x" % jtag.idcode())

import ecp5p, digitalio, board 
jtag_rst = digitalio.DigitalInOut(board.GP20)
jtag_rst.direction = digitalio.Direction.OUTPUT
jtag_rst.value = False
time.sleep(0.1)
jtag_rst.value = True
ecp5p.prog("test.bit")


#jtag_rst.value = False

