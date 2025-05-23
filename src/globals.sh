################################################################################
# CONSTANTS AND DEFAULTS
readonly DEFAULT_DELAY=1.0
readonly MAX_DELAY=5.0
readonly MIN_DELAY=0.1

# DELAY
# This value is important.  Depending on the speed of your computer, this
# value may need to be increased (for slower computers) or set lower (for
# faster ones). It refers to the wait time between opening an xterm
# window and starting openmpt123. The terminal video recorded here may
# be asynchronous in the final video accordingly. You can modify the
# value with the --delay|-d option or set the
: "${DELAY:=$DEFAULT_DELAY}"

# Normalize to this peak
readonly TARGET_DBFS=-0.2

################################################################################
# CONFIGURABLE OPTIONS (CAN BE SET AS ENVIRONMENT VARIABLES)
# Do not normalize by default
: "${NORMALIZE:=0}"

# TERMINAL SETTINGS
# Keep in mind that the height of a terminal character is approx twice its
# width. So if you want to know if you have the perfect ratio just double
# the TERMINAL_ROWS (not for real): 80/(24*2) =~ 1.66 = 5(w)/3(h)
: "${TERMINAL_COLS:=80}"
: "${TERMINAL_ROWS:=24}"

# Pattern display
: "${TERM_THEME:=black}"  # "white" for inverted
: "${TERM_FONT_SIZE:=16}"

# SUPPRESS_AUDIO
# XXX Currently NOT Working with dummy device: $ sudo modprobe snd-dummy
# Just a nasty hack that starts openmpt123 with --gain -80
# This option will also remove the vu meters at the top as they are
# showing nothing anyway at -80dB
: "${SUPPRESS_AUDIO:=0}"  # 1 to mute playback

# BACKGROUND_COLOR
# This one goes to ImageMagick
: "${BACKGROUND_COLOR:=xc:black}"
# can be video or image

# BACKGROUND_IMAGE
: "${BACKGROUND_IMAGE:=}"

# BACKGROUND_IMAGE_POOL
# Background image pool. You can specify a pool of images where
# one will be randomly selected as the background image
declare -a BACKGROUND_IMAGE_POOL
: "${BACKGROUND_IMAGE_POOL:=}"

# FONT FOR openmpt123 --info output
: "${TITLE_FONT_MONO:=/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf}"
# VIDEO TITLE
: "${TITLE_FONT_FILE:=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf}"
: "${TITLE_FONT_SIZE:=60}"
: "${TITLE_FONT_COLOR:=yellow}"
: "${TITLE_FONT_ALPHA:=1.0}"
: "${TITLE_TEXT_POS_X:=(w-text_w)/2}"
: "${TITLE_TEXT_POS_Y:=60}"
: "${TITLE_TEXT:="\{artist\} - \{title\}"}"
: "${TITLE_SHADOW_X:=4}"
: "${TITLE_SHADOW_Y:=4}"

# FR SETTINGS
: "${SHOW_FREQ:=1}"
: "${FREQ_MODE:=line}"	# allowed: bar, dot, line
: "${FREQ_FSCALE:=log}"	# Frequency scale; allowed: lin, log, rlog
: "${FREQ_ASCALE:=log}"	# Amplitude scale; allowed: lin, sqrt, cbrt, log
: "${FREQ_COL_1:=cyan}"	# color string, no strict check here
: "${FREQ_COL_2:=magenta}"
: "${FREQ_COL_ALPHA:=0.6}"
: "${FREQ_WIDTH:=1920}"
: "${FREQ_HEIGHT:=200}"
: "${FREQ_POS_X:=0}"
: "${FREQ_POS_Y:=$((1080 - FREQ_HEIGHT))}"
: "${FREQ_WINSIZE:=2048}"	# usually a power of 2
: "${FREQ_TRANSPOSE:=0}"	# 0=0deg; 1=90deg; 2=180deg; 3=270deg, 4=hflip, 5=vflip, 6=90deg+hflip, 7=270deg+vflip

: "${SHOW_WAVES:=1}"
: "${WAVES_COLOR:=yellow}"
: "${WAVES_MODE:=p2p}"	# point,line,p2p,cline
: "${WAVES_SIZE:=600x60}"
: "${WAVES_WIDTH:=600}"
: "${WAVES_HEIGHT:=60}"
: "${WAVES_POS_X:=$(( (1920 - WAVES_WIDTH) / 2 ))}"
: "${WAVES_POS_Y:=100}"

: "${SHOW_SPECTRUM:=0}"
: "${SPECTRUM_WIDTH:=400}"
: "${SPECTRUM_HEIGHT:=400}"
: "${SPECTRUM_POS_X:=0}"
: "${SPECTRUM_POS_Y:=400}"
: "${SPECTRUM_COLOR:=rainbow}"
# channel|intensity|rainbow|moreland|nebulae|fire|fiery|fruit|cool|magma|green|viridis|plasma|cividis|terrain

: "${SHOW_OVERVIEW:=1}"
: "${OVERVIEW_WIDTH:=1180}"
: "${OVERVIEW_HEIGHT:=40}"
: "${OVERVIEW_POS_X:=$(( (1920 - OVERVIEW_WIDTH) / 2 ))}"
: "${OVERVIEW_POS_Y:=140}"
: "${OVERVIEW_COLOR:=nebulae}"
: "${OVERVIEW_MARKER_COLOR:=red@0.8}"

: "${PATTERN_WIDTH:=-2}"	# pattern view width (-2: keep aspect)
: "${PATTERN_HEIGHT:=720}"	# pattern view height(-2: keep aspect)
: "${PATTERN_OFFSET_X:=0}"	# positive value: position right of the center
: "${PATTERN_OFFSET_Y:=0}"	# positive value: position below the center

# Subtitle Settings
: "${SUBTITLE_FILE:=}"

# Logo settings
: "${LOGO_FILE:=}"
: "${LOGO_SIZE:=200:-1}"	# Width 200px, height auto
: "${LOGO_POSITION:=20:20}"	# 20px from top-left


: "${PATTERN_GAMMA_R:=1.0}"
: "${PATTERN_GAMMA_G:=1.0}"
: "${PATTERN_GAMMA_B:=1.0}"


: "${PATTERN_COLOR_BOOST_R:=1.0}"
: "${PATTERN_COLOR_BOOST_G:=1.0}"
: "${PATTERN_COLOR_BOOST_B:=1.0}"
# Glow Effect Settings
: "${PATTERN_GLOW_RADIUS:=0}"		# Blur strength (pixels)
: "${PATTERN_GLOW_OPACITY:=1.0}"	# 0.0-1.0 (transparent-opaque)
: "${PATTERN_GLOW_MODE:=screen}"	# Other options: "screen", "lighten"
: "${PATTERN_GLOW_COLOR:=white}"	# Optional color tint

# if -Q (NO_TRACK_INFO) was specified and no background image or
# video was loaded there will be no track info either
: "${NO_TRACK_INFO:=0}"

export DISPLAY=":99"

################################################################################
# COMMAND LINE OVERRIDES
BACKGROUND_IMAGE_CMDLINE=""
TITLE_TEXT_CMDLINE=""
TERMINAL_COLS_CMDLINE=""
TERMINAL_ROWS_CMDLINE=""

################################################################################
# OTHER GLOBALS
SKIP_TERM=0
SETTINGS_FILE=""
MODULE=""
CUSTOM_WAV=""
AUDIO=""
WAV=""
AUDIO_DURATION=0
BASENAME=""
GAIN=0
GEOM=""
NO_META=0
POSITIONAL=()
TERMVID=""
OUTVID=""
TRACK_INFO=""
NUM_CHANNELS=0
PRINT_SETTINGS=0
TITLE_TEXT_ORIG="$TITLE_TEXT"

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
BOLD=$(tput bold)
RESET=$(tput sgr0)
