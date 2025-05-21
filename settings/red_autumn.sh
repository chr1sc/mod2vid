# mod2vid template   << MANDATORY
# Name:   Red Autumn
# Author: Christian Czinzoll
# Date:   2025-05-21

TITLE_TEXT_POSITION="x=(w-text_w-20):y=(text_h-20)"
TITLE_FONT_COLOR="red@0.8"
TITLE_TEXT='{artist} // {title}'

# Normalize each track if the sound output is below headroom
NORMALIZE=1

# This is a command for ImageMagic to create a background with a nice gradient
BACKGROUND_COLOR='gradient:#452209-#7F4600'

# If there is a background video or image present
# BACKGROUND_COLOR will be ignored
#BACKGROUND_IMAGE="$HOME/Downloads/854569-hd_1920_1080_25fps.mp4"

# the pattern view has a height of 900px the width will adjust automatically
PATTERN_HEIGHT=840

# we're moving the pattern view 200px to the left of the center
PATTERN_OFFSET_X=200
# moving it down a little
PATTERN_OFFSET_Y=50

# Do not display openmpt123's --info output
# This will be displayed by default if there was no background
# image or video specified
NO_TRACK_INFO=1

SHOW_SPECTRUM=0
SHOW_WAVES=0

EQ_MODE=bar
EQ_FSCALE=log
EQ_ASCALE=sqrt
EQ_COL_1=brown
EQ_COL_2=green
EQ_COL_ALPHA=0.3
EQ_POS_X=0
EQ_POS_Y=0
EQ_WIDTH=1920
EQ_HEIGHT=1920
EQ_WINSIZE=1024
EQ_TRANSPOSE=7

TERMINAL_GAMMA_R=1.2
TERMINAL_GAMMA_G=1.3
TERMINAL_GAMMA_B=1.9
