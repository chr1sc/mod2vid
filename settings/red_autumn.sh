# mod2vid template   << MANDATORY
# Name:   Red Autumn
# Author: Christian Czinzoll
# Date:   2025-05-21

TITLE_TEXT_POS_X="(w-text_w-20)"
TITLE_TEXT_POS_Y="(text_h-20)"
TITLE_FONT_COLOR="red"
TITLE_FONT_ALPHA="0.8"
TITLE_TEXT='{artist} // {title}'

# Normalize each track if the sound output is below headroom
NORMALIZE=1

# This is a command for ImageMagic to create a background with a nice gradient
BACKGROUND_COLOR='gradient:#452209-#7F4600'

# If there is a background video or image present
# BACKGROUND_COLOR will be ignored
BACKGROUND_IMAGE="$HOME/Downloads/854569-hd_1920_1080_25fps.mp4"

# the pattern view has a height of 900px the width will adjust automatically
PATTERN_HEIGHT=840

# we're moving the pattern view 200px to the left of the center
PATTERN_OFFSET_X=200
# moving it down a little
PATTERN_OFFSET_Y=50

PATTERN_GLOW_RADIUS=20
PATTERN_GLOW_OPACITY=1.0
PATTERN_GLOW_MODE=screen
PATTERN_GLOW_COLOR=yellow


# Do not display openmpt123's --info output
# This will be displayed by default if there was no background
# image or video specified
NO_TRACK_INFO=1

SHOW_SPECTRUM=0
SHOW_WAVES=0

FREQ_MODE=bar
FREQ_FSCALE=log
FREQ_ASCALE=sqrt
FREQ_COL_1=brown
FREQ_COL_2=green
FREQ_COL_ALPHA=0.3
FREQ_POS_X=0
FREQ_POS_Y=0
# if you turn it to the side, height becomes width
FREQ_WIDTH=1080
FREQ_HEIGHT=400
FREQ_WINSIZE=1024
FREQ_TRANSPOSE=7

TERMINAL_GAMMA_R=1.2
TERMINAL_GAMMA_G=1.3
TERMINAL_GAMMA_B=1.9
