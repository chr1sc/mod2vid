# mod2vid template   << MANDATORY
# Name:   Blue Night
# Author: Christian Czinzoll
# Date:   2025-05-21

# Normalize each track if the sound output is below headroom
NORMALIZE=1

# This is a command for ImageMagic to create a background
BACKGROUND_COLOR='gradient:#000022-#001144'
# If there is a background video or image present
# BACKGROUND_COLOR will be ignored
# If there is an image pool present, one of the
# images will randomly be chosen. The path is
# relative to the template script path or
# execution path. Wherever it finds the image
BACKGROUND_IMAGE_POOL=(
	blue_night/blue_night_1_bing_image_creator.jpeg
	blue_night/blue_night_2_bing_image_creator.jpeg
	blue_night/blue_night_3_bing_image_creator.jpeg
	blue_night/blue_night_4_bing_image_creator.jpeg
	blue_night/blue_night_5_bing_image_creator.jpeg
	blue_night/blue_night_6_bing_image_creator.jpeg
	blue_night/blue_night_7_bing_image_creator.jpeg
	blue_night/blue_night_8_bing_image_creator.jpeg
)

TITLE_TEXT='[{artist}] {title}'
# track info is at this absolute position
TITLE_TEXT_POSITION="x=20:y=40"

# wide and flat (calculate rows*2 to get an approx aspect ratio ~ 25/8)
TERMINAL_COLS=100
TERMINAL_ROWS=24

SHOW_WAVES=0
# the pattern view has a height of 800px the width will adjust automatically
# if set to -2
PATTERN_HEIGHT=800
# we're moving the pattern view 400px to the right of the center
PATTERN_OFFSET_X=400

PATTERN_GAMMA_R=1.6
PATTERN_GAMMA_G=1.8
PATTERN_GAMMA_B=1.0

# Do not display openmpt123's --info output
# This will be displayed by default if there was no background
# image or video specified
NO_TRACK_INFO=1

EQ_MODE=bar
EQ_HEIGHT=400
EQ_FSCALE=log

