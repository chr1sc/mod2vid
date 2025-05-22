# mod2vid template   << MANDATORY
# Name:   Green Screen
# Author: Christian Czinzoll
# Date:   2025-05-21
# Normalize each track if the sound output is below headroom
NORMALIZE=1

# This is a command for ImageMagic to create a background
BACKGROUND_COLOR='gradient:#003300-#007700'
# If there is a background video or image present
# BACKGROUND_COLOR will be ignored
# If there is an image pool present, one of the
# images will randomly be chosen. The path is
# relative to the template script path or
# execution path. Wherever it finds the image

TITLE_TEXT='[{artist}] {title}'
# track info is at this absolute position
TITLE_TEXT_POS_X="w-text_w-20"
TITLE_TEXT_POS_Y="h-text_h-120"
TITLE_FONT_FILE=/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf
TITLE_FONT_COLOR="0xa0ffc0"

# wide and flat (calculate rows*2 to get an approx aspect ratio ~ 25/8)
TERMINAL_COLS=80
TERMINAL_ROWS=16

SHOW_WAVES=0



# the pattern view has a height of 800px the width will adjust automatically
# if set to -2
PATTERN_HEIGHT=800
# we're moving the pattern view 400px to the right of the center
PATTERN_OFFSET_X=-400
PATTERN_OFFSET_Y=0

PATTERN_GAMMA_R=0.7
PATTERN_GAMMA_G=1.0
PATTERN_GAMMA_B=0.7

# Do not display openmpt123's --info output
# This will be displayed by default if there was no background
# image or video specified
NO_TRACK_INFO=1

# bar | dot | line
FREQ_MODE=bar
FREQ_COL_1=green
FREQ_COL_2=yellow
FREQ_COL_ALPHA=0.2
FREQ_WIDTH=1920
FREQ_HEIGHT=600
FREQ_POS_X=0
FREQ_POS_Y=140
FREQ_TRANSPOSE=5
FREQ_FSCALE=log
FREQ_ASCALE=sqrt

