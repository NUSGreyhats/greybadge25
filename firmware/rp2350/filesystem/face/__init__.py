import gifio, asyncio, struct, time, random

def load_image(img_filename):
    print(img_filename)
    img_bitmap, img_palette = adafruit_imageload.load(img_filename)
    img_tilegrid = displayio.TileGrid(img_bitmap, pixel_shader=img_palette)
    main.append(img_tilegrid)
    del img_bitmap, img_palette
    gc.collect()

### Load Gif Continuous ############################################
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
    
### Load Gif Oneshot ############################################
def load_gif_oneshot(display_bus, filename):
    odg = gifio.OnDiskGif(filename)
    #next_delay = odg.next_frame()  # Load the first frame

    for i in range(odg.frame_count):
        # Direct write to LCD
        next_delay = odg.next_frame()
        time.sleep(next_delay)
        display_bus.send(42, struct.pack(">hh", 0, odg.bitmap.width - 1))
        display_bus.send(43, struct.pack(">hh", 0, odg.bitmap.height - 1))
        display_bus.send(44, odg.bitmap)

def load_gif_oneshot_selective(display_bus, filename, frame_gen=None):
    odg = gifio.OnDiskGif(filename)
    #next_delay = odg.next_frame()  # Load the first frame
    
    if frame_gen == None:
        frame_gen = reversed(range(odg.frame_count))
    for i in frame_gen:
        # damn stupid way to play in reverse
        
        # go forward
        for j in range(i - 1):
            next_delay = odg.next_frame()
        
        next_delay = odg.next_frame()
        # Direct write to LCD
        time.sleep(next_delay)
        display_bus.send(42, struct.pack(">hh", 0, odg.bitmap.width - 1))
        display_bus.send(43, struct.pack(">hh", 0, odg.bitmap.height - 1))
        display_bus.send(44, odg.bitmap)
        
        # go backward
        for j in range(odg.frame_count - i): 
            next_delay = odg.next_frame()

def load_gif_oneshot_reverse(display_bus, filename, frame_gen=None):
    load_gif_oneshot_selective(display_bus, filename, None)


expressions = [
    #"face/expressions/greycat_eyes_middle_to_left.gif",
    #"face/expressions/greycat_eyes_middle_to_right.gif",
    #"face/expressions/greycat_cheeks.gif",
    #"face/expressions/greycat_sad.gif",
    #"face/expressions/greycat_angy.gif"
    "lazer"
]

def live_firing(hardware, display_bus, overlay):
    # Awakening
    #load_gif_oneshot_selective(display_bus, "face/expressions/greycat_awakening.gif", [8])
    load_gif_oneshot(display_bus, "face/expressions/greycat_awakening.gif")
    overlay.deinit_mode_buttons()
    u = overlay.set_mode_uart()
    
    # Random Choice
    time.sleep(1)
    while hardware.button_a.value == True and hardware.button_b.value == True:
        expression = expressions[random.randint(0, len(expressions)-1)]
        if expression == "lazer":
            load_gif_oneshot(display_bus, "face/expressions/greycat_angy.gif")
            load_gif_oneshot_selective(display_bus, "face/expressions/greycat_lazer_attack.gif", range(4))
            time.sleep(1)
            
            # Lazer Attack
            target = random.randint(0, 3)
            #for i in range(target, target+4): u.write(chr(ord("A")+target))
            load_gif_oneshot_selective(display_bus, "face/expressions/greycat_lazer_attack.gif", [5])
            hardware.buzzer.frequency = 329
            hardware.buzzer.duty_cycle = hardware.BUZZ_ON
            u.write(chr(ord("A")+target))
            time.sleep(1)
            hardware.buzzer.duty_cycle = hardware.BUZZ_OFF
            
            # Resume
            load_gif_oneshot_selective(display_bus, "face/expressions/greycat_lazer_attack.gif", range(4, 0, -1))
            load_gif_oneshot_reverse(display_bus, "face/expressions/greycat_angy.gif")
            time.sleep(0.5)
            u.write("`")
            time.sleep(1)
            continue
        load_gif_oneshot(display_bus, expression)
        time.sleep(1)
        load_gif_oneshot_reverse(display_bus, expression)
        time.sleep(1)
        
    
    # Sleeping
    load_gif_oneshot_reverse(display_bus, "face/expressions/greycat_awakening.gif")
    #u.write("abcdefg")
    u.deinit()
    