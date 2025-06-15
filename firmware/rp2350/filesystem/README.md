# GreyMecha/Army

This is the GreyMecha/Army Firmware (for the RP2350 part anyway). It's based off circuitpython, and includes various challenges.


## Images

To customise the badge with your own (`.jpg` and `.gif`), just put them in the `images` folder. 
Make sure they are 240x240 pixels.

You may use EzGif to convert a video to Gif format. https://ezgif.com/video-to-gif

You may also use EzGif to resize to 240 x 240 pixels. https://ezgif.com/maker


## Challenges

Check the `/challenge` folder for more information

### Hornet Revenge

I want revenge.

Run this in Thonny to start the challenge.

```python
from challenge.hornet_revenge import *
```

### LeakyPin

I wonder if there's something special in the secret pin GP22....

Run this in Thonny to start the challenge.

```python
from challenge.leaky_gpio22 import *
```

### Shooting Flags

During Live Firing, the cats were told to "follow the standards" and shoot accordingly. I wonder if it could mean something...


### Secure Memory

Oh wait, the flag is not supposed to be accessed by anyone? Hmm, this should do the trick...

Access the stored values of secure memory at pmod_j2.
