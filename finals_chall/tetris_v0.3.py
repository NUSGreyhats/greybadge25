print("Hello World!")

import board # type: ignore
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
    options = ["Hi I'm Terence", "Face", "Animation", "Live Firing", "Game", "Controller", "Chall"]
    menu_layout(options[curr])

    global fpga_buttons

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
            if options[curr] == "Live Firing":
                face.live_firing(hardware, display_bus, overlay)
                fpga_buttons = overlay.set_mode_buttons()
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
    gc.collect()
    img_bitmap, img_palette = adafruit_imageload.load(img_filename)
    img_tilegrid = displayio.TileGrid(img_bitmap, pixel_shader=img_palette)
    main.append(img_tilegrid)
    del img_bitmap, img_palette

    gc.collect()
    print("Free memory at code point 1: {} bytes".format(gc.mem_free()) )

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


    ## Rough UI
    prev_fpga_buttons = [x.value for x in fpga_buttons]

    files_total = os.listdir("/image")
    files = []
    for f in files_total:
        if ".jpg" in f:
            files.append(f)
    file_index = 0
    print(files)
    load_image("/image/" + files[file_index])
    while True:
        if fpga_buttons[0].value == False: # and fpga_buttons[3].value != prev_fpga_buttons[3]:
            file_index = (file_index-1) % len(files)
            val = main.pop()
            del val
            gc.collect()
            print("Free memory at code point 1: {} bytes".format(gc.mem_free()) )
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
    keyboard = Keyboard(usb_hid.devices)
    keyboard_layout = KeyboardLayoutUS(keyboard)  # We're in the US :)
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




class Brick:
    BRICKS = b'ftqr\xf0'
    ROTATIONS = [
        (1, 0, 0, 1, -1, -1),
        (0, 1, -1, 0, -1, 0),
        (-1, 0, 0, -1, -2, 0),
        (0, -1, 1, 0, -2, -1),
    ]

    def __init__(self, kind):
        self.x = 1
        self.y = 2
        self.color = kind % 5 + 1
        self.rotation = 0
        self.kind = kind

    def draw(self, image, color=None):
        if color is None:
            color = self.color
        data = self.BRICKS[self.kind]
        rot = self.ROTATIONS[self.rotation]
        mask = 0x01
        for y in range(2):
            y += rot[5]
            for x in range(4):
                x += rot[4]
                if data & mask:
                    try:
                        image[self.x + x * rot[0] + y * rot[1],
                              self.y + x * rot[2] + y * rot[3]] = color
                    except IndexError:
                        pass
                mask <<= 1

    def hit(self, image, dx=0, dy=0, dr=0):
        data = self.BRICKS[self.kind]
        rot = self.ROTATIONS[(self.rotation + dr) % 4]
        mask = 0x01
        for y in range(2):
            y += rot[5]
            for x in range(4):
                x += rot[4]
                if data & mask:
                    try:
                        if image[self.x + dx + x * rot[0] + y * rot[1],
                                 self.y + dy + x * rot[2] + y * rot[3]]:
                            return True
                    except IndexError:
                        return True
                mask <<= 1
        return False

def brick_game():
    display_text("Brick Game\nMode")
    time.sleep(0.5)

    # return

    # Read each button



    palette = displayio.Palette(6)
    palette[0] = 0x7f7f7f # background
    palette[1] = 0xffff00 # smashboy
    palette[2] = 0xff7f00 # L
    palette[3] = 0x0000ff # invert L
    palette[4] = 0x800080 # T
    palette[5] = 0x00ffff # hero
    text_palette = displayio.Palette(2)
    text_palette[0] = 0x111111
    text_palette[1] = 0xffeedd
    w, h = terminalio.FONT.get_bounding_box()
    text_grid = displayio.TileGrid(terminalio.FONT.bitmap,
        tile_width=w, tile_height=h, pixel_shader=text_palette, width=8, height=1)
    text_grid.x = 96
    text_grid.y = 48
    text = terminalio.Terminal(text_grid, terminalio.FONT)
    screen = displayio.Bitmap(10, 20, 6)
    preview = displayio.Bitmap(4, 4, 6)
    bricks = displayio.Group(scale=8)
    bricks.append(displayio.TileGrid(screen, pixel_shader=palette, x=0, y=-4))
    bricks.append(displayio.TileGrid(preview, pixel_shader=palette, x=12, y=0))
    root = displayio.Group()
    root.append(bricks)
    root.append(text_grid)
    root[0] = displayio.Group()
    root[0] = bricks

    # center the game on the screen
    root.x = 75
    root.y = 80

    display.root_group = root

    brick = None
    score = 0
    next_brick = Brick(random.randint(0, 4))
    tick = time.monotonic()

    last_inputs = [0, 0, 0]
    last_input_counter = 0
    konami = [1, 2, 3]

    while True:
        print("last_inputs: ", last_inputs, "last_input_counter: ", last_input_counter)
        print("konami: ", konami)
        if last_inputs == konami:
            print("Konami code entered!")
            score += 9999 # give bonus points
            last_inputs = [0, 0, 0] # reset last inputs
            
        if brick is None:
            text.write("\r\n%08d" % score)
            next_brick.draw(preview, 0)
            brick = next_brick
            brick.x = screen.width // 2
            next_brick = Brick(random.randint(0, 4))
            next_brick.draw(preview)
            if brick.hit(screen, 0, 0):
                # game over
                last_input_counter = 0
                if score > 9998:
                    print("grey{hallucinate_me_gpt}")
                print("Game Over")
                
                display_text("Game Over\nScore: %d" % score)
                time.sleep(2)
                # load_gif("image/knuckle.gif")
                # asyncio.run(update_gif()) # Run gif
                # microcontroller.reset() # reset board
                brick_game() # restart game


        tick += 0.5
        pressed = 0
        # event = keypad.Event()
        # debounce = False
        while True:
            # if debounce:
            #     time.sleep(0.075)
            #     debounce = False
            time.sleep(0.075)
            if tick <= time.monotonic():
                break
            brick.draw(screen, 0)


            left_pressed = not fpga_buttons[0].value
            right_pressed = not fpga_buttons[4].value
            down_pressed = not fpga_buttons[3].value
            hard_drop_pressed = not fpga_buttons[1].value
            rotate_ccw_pressed = not hardware.button_a.value
            rotate_cw_pressed = not hardware.button_b.value



            if down_pressed and not brick.hit(screen, 0, 1): # down
                brick.y += 1
                last_input_counter = (last_input_counter + 1) % 3
                last_inputs[last_input_counter] = 2
            if right_pressed and not brick.hit(screen, 1, 0): # right
                brick.x += 1
                last_input_counter = (last_input_counter + 1) % 3
                last_inputs[last_input_counter] = 3
            if left_pressed and not brick.hit(screen, -1, 0): # left
                brick.x -= 1
                last_input_counter = (last_input_counter + 1) % 3
                last_inputs[last_input_counter] = 1
            if rotate_ccw_pressed and not brick.hit(screen, 0, 0, 1) and not debounce: # rotate counter clockwise
                brick.rotation = (brick.rotation + 1) % 4
                debounce = True
            if rotate_cw_pressed and not brick.hit(screen, 0, 0, -1) and not debounce: # rotate clockwise
                brick.rotation = (brick.rotation - 1) % 4
                debounce = True
            if hard_drop_pressed and not brick.hit(screen, 0, 1): # hard drop
                while not brick.hit(screen, 0, 1):
                    brick.y += 1
                time.sleep(0.1) # debounce
                debounce = True
            if not pressed:
                debounce = False
            brick.draw(screen)
        brick.draw(screen, 0)
        if brick.hit(screen, 0, 1):
            brick.draw(screen)
            combo = 0
            for y in range(screen.height):
                for x in range(screen.width):
                    if not screen[x, y]:
                        break # found empty space
                else:
                    # TODO fuckery with the combo to make it more fun
                    combo += 1
                    score += combo
                    for yy in range(y, 0, -1):
                        for x in range(screen.width):
                            screen[x, yy] = screen[x, yy - 1]
            brick = None
        else:
            brick.y += 1
            brick.draw(screen)


brick_game()



# menu()



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