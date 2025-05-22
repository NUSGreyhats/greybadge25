print("Hello World!")

import board
import busio
import fourwire
import displayio

import time
import math
import terminalio
from adafruit_display_text import label

import random
import gc, os
import gc9a01, displayio, adafruit_imageload
#import bitmaptools, gifio, struct

import hardware
import hardware.fpga
import hardware.default_overlay
import face

gc.enable()
gc.collect()
### Initialisation ####################################

display, display_bus = hardware.rp2350_init_display()
main = displayio.Group()
display.root_group = main

#face.live_firing(hardware, display_bus)
#gc.collect()

# Draw a text label
text = "Loading\nFPGA..."
text_area = label.Label(terminalio.FONT, text=text, color=0xFFFF00,
                        anchor_point=(0.5,0.5), anchored_position=(0,0))
text_group = displayio.Group(scale=2)
text_group.append(text_area) 
main.append(text_group)
text_group.x = 120 #+ int(r * math.sin(theta))
text_group.y = 120 #+ int(r * math.cos(theta))

#hardware.fpga.upload_bitstream("main.bit")
overlay = hardware.default_overlay.Overlay()
overlay.init()
### Menu ############################################
fpga_buttons = overlay.set_mode_buttons()
    
def splashscreen():
    val = main.pop()
    text = "Welcome to \nGreyMecha/Army"
    text_area = label.Label(terminalio.FONT, text=text, color=0xFFFF00,
                            anchor_point=(0.5,0.5), anchored_position=(0,0))
    text_group = displayio.Group(scale=2)
    text_group.append(text_area) 
    main.append(text_group)
    text_group.x = 120 #+ int(r * math.sin(theta))
    text_group.y = 120 #+ int(r * math.cos(theta))
    
def menu_layout(text_in):
    val = main.pop()
    
    header_text_area = label.Label(terminalio.FONT, text="Welcome to \nGreyMecha/Army", color=0xFFFF00,
                            anchor_point=(0.5,0.5), anchored_position=(0,0))
    #header_text_area.x = 0
    header_text_area.y = -20
    ## Menu Text
    text = text_in
    text_area = label.Label(terminalio.FONT, text=text, color=0xFFFF00,
                            anchor_point=(0.5,0.5), anchored_position=(0,0))
    #text_area.x = 0
    text_area.y = 15
    
    text_group = displayio.Group(scale=2)
    
    text_group.append(header_text_area) 
    text_group.append(text_area) 
    main.append(text_group)
    text_group.x = 120 
    text_group.y = 120 
    

def menu():
    splashscreen()
    time.sleep(0.5)
    
    print("menu")
    curr = 0
    options = ["Hi I'm Terence", "Face", "Animation", "Animation2", "Game", "Controller", "Chall"]
    menu_layout(options[curr])
    
    
    trigger = False
    while True:
        # Menu Display Code
        if fpga_buttons[0].value == False:
            curr = (curr - 1) % len(options)
            trigger = True
        if fpga_buttons[4].value == False:
            curr = (curr + 1) % len(options)
            trigger = True
        if trigger:
            menu_layout(options[curr])
            time.sleep(0.5)
            trigger = False
        
        # Select Code
        if hardware.button_a.value == False:
            if options[curr] == "Face":
                face_mode()
            if options[curr] == "Animation":
                load_gif("image/greycat.gif")
                asyncio.run(update_gif()) # Run gif
            if options[curr] == "Animation2":
                face.live_firing(hardware, display_bus, overlay)
            if options[curr] == "Game":
                pass
            if options[curr] == "Controller":
                controller()
            if options[curr] == "Chall":
                return
            menu_layout(options[curr])
            time.sleep(0.5)
        
### Random Animation Mode ###########################

    


### Face ############################################
# Load image
def load_image(img_filename):
    print(img_filename)
    img_bitmap, img_palette = adafruit_imageload.load(img_filename)
    img_tilegrid = displayio.TileGrid(img_bitmap, pixel_shader=img_palette)
    main.append(img_tilegrid)
    del img_bitmap, img_palette
    gc.collect()

import gifio, asyncio, struct
def load_gif(filename):
    odg = gifio.OnDiskGif(filename)
    next_delay = odg.next_frame()  # Load the first frame

    async def update_fn():
        while True:
            # Direct write to LCD
            next_delay = odg.next_frame()
            await asyncio.sleep(next_delay / 1.2)
            display_bus.send(42, struct.pack(">hh", 0, odg.bitmap.width - 1))
            display_bus.send(43, struct.pack(">hh", 0, odg.bitmap.height - 1))
            display_bus.send(44, odg.bitmap)
    
    global update_gif
    update_gif = update_fn
async def update_gif():
    tasks = []
    #tasks.append(asyncio.create_task(update_pixel()))
    if update_gif:
        tasks.append(asyncio.create_task(update_gif()))
    await asyncio.gather(*tasks)


def face_mode():
    #asyncio.run(main()) # Run gif
    time.sleep(0.5)
    val = main.pop()
    del val
    load_image("/image/greymecha_angy.jpg")
    
    ## Rough UI
    prev_fpga_buttons = [x.value for x in fpga_buttons]
    
    files_total = os.listdir("/image")
    files = []
    for f in files_total:
        if ".png" in f:
            files.append(f)
    file_index = 0
    while True:
        
        if fpga_buttons[0].value == False: # and fpga_buttons[3].value != prev_fpga_buttons[3]:
            file_index = (file_index-1) % len(files)
            val = main.pop()
            del val
            load_image("/image/" + files[file_index])
            time.sleep(0.5)
            
        if fpga_buttons[4].value == False: # and fpga_buttons[3].value != prev_fpga_buttons[3]:
            file_index = (file_index+1) % len(files)
            val = main.pop()
            del val
            load_image("/image/" + files[file_index])
            time.sleep(0.5)
        prev_fpga_buttons = [x.value for x in fpga_buttons]
        if hardware.button_a.value == False:
            print("exit")
            break

#face_mode()
        
### Controller #############################################
import usb_hid
from adafruit_hid.keyboard import Keyboard
from adafruit_hid.keyboard_layout_us import KeyboardLayoutUS
from adafruit_hid.keycode import Keycode

keyboard = Keyboard(usb_hid.devices)
keyboard_layout = KeyboardLayoutUS(keyboard)  # We're in the US :)

def display_text(text):
    val = main.pop()
    #text = "stuff"
    text_area = label.Label(terminalio.FONT, text=text, color=0xFFFF00,
                            anchor_point=(0.5,0.5), anchored_position=(0,0))
    text_group = displayio.Group(scale=2)
    text_group.append(text_area) 
    main.append(text_group)
    text_group.x = 120 #+ int(r * math.sin(theta))
    text_group.y = 120 #+ int(r * math.cos(theta))
        
def controller():
    time.sleep(0.5)
    display_text("Controller\nMode")
    
    button_list = fpga_buttons[:5] + [hardware.button_a, hardware.button_b]
    keycode_list = [Keycode.LEFT_ARROW, Keycode.UP_ARROW, Keycode.A, Keycode.DOWN_ARROW, Keycode.RIGHT_ARROW, Keycode.A, Keycode.B]
    
    while True:
        for i in range(len(button_list)):
            if i==2: continue
            if button_list[i].value == False:
                keyboard.press(keycode_list[i])
            else:
                keyboard.release(keycode_list[i])
        if button_list[2].value == False:
            return
                
    


menu()



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

### USB HID Hack ###############################################################
'''
print("Exploit")

import usb_hid
from adafruit_hid.keyboard import Keyboard
from adafruit_hid.keyboard_layout_us import KeyboardLayoutUS
from adafruit_hid.keycode import Keycode




def payload():
    for i in range(1000):
        if hardware.button_b.value == False:
            return
        keyboard.press(Keycode.F)
        time.sleep(0.001)
        keyboard.release(Keycode.F)
        
while True:
    if hardware.button_a.value == False:
        payload()
        time.sleep(0.5)

input("enter to continue to main program")
'''
#################################################################################