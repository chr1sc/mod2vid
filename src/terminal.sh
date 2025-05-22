record_terminal() {
	if [[ "$SKIP_TERM" == 1 && -f "$TERMVID" ]]; then
		echo "Skipping terminal recording (using existing: $TERMVID)"
		return
	fi

	echo "Starting headless terminal recording..."
	start_xvfb

	local xterm_cmd
	xterm_cmd=$(build_xterm_command)
	run_xterm "$xterm_cmd" &
	local XTERM_PID=$!
	sleep 1

	detect_window_geometry
	AUDIO_DURATION=$(get_media_duration "$WAV")

	record_x11 "$AUDIO_DURATION"
	local FFMPEG_PID=$!

	wait "$XTERM_PID"
	sleep 1
	kill "$FFMPEG_PID" "$XVFB_PID" 2>/dev/null || true
}

start_xvfb() {
	Xvfb ":99" -screen 0 1920x1080x24 +extension RANDR &>/dev/null &
	XVFB_PID=$!
	#trap 'cleanup' EXIT ERR
	sleep 1
}

calculate_max_font_size() {
	local screen_w=1920 screen_h=1080
	local cols=$TERMINAL_COLS
	local rows=$TERMINAL_ROWS
	local font_aspect=0.5
	local margin_factor=0.58

	local max_w=$(awk -v sw="$screen_w" -v c="$cols" -v fa="$font_aspect" -v mf="$margin_factor" \
		'BEGIN { printf "%.0f", sw / (c * fa) * mf }')

	local max_h=$(awk -v sh="$screen_h" -v r="$rows" -v mf="$margin_factor" \
		'BEGIN { printf "%.0f", sh / r * mf }')

	# Return the smaller value
	if (( max_w < max_h )); then
		echo "$max_w"
	else
		echo "$max_h"
	fi
}

build_xterm_command() {

# 	NUM_CHANNELS=$(openmpt123 --info "$MODULE"|grep ^Channels|awk '{print $2}')
# 	TERMINAL_COLS=$(( NUM_CHANNELS * 14))

	local max_font_size=$(calculate_max_font_size)
    if (( $(echo "$TERM_FONT_SIZE > $max_font_size" | bc -l) )); then
        TERM_FONT_SIZE=$max_font_size
        echo "TERM_FONT_SIZE: Using safe value: $TERM_FONT_SIZE" >&2
    fi
	local cmd=(-fa "Monospace" -fs $TERM_FONT_SIZE -geometry "$GEOM")
	if [[ "$TERM_THEME" == "white" ]]; then
		cmd+=(-bg white -fg black -cr black)
	else
		cmd+=(-bg black -fg white -cr white)
	fi

	local mpt_args=(--progress --channel-meters --pattern "$(printf "%q" "$MODULE")")
	if [[ "$SUPPRESS_AUDIO" == 1 ]]; then
		mpt_args+=(--no-meters --gain -80)
	else
		mpt_args+=(--gain "$GAIN")
	fi

	local exec_cmd="sleep $DELAY; openmpt123 ${mpt_args[*]}; clear; sleep 2"
	cmd+=(-e "bash" "-c" "$(printf "%q" "$exec_cmd")")

	printf '%s ' "${cmd[@]}"
}

run_xterm() {
	eval xterm "$1"
}

detect_window_geometry() {
	W=1920 H=1080
	if WIN_ID=$(xwininfo -root -children | awk '/xterm/ {print $1; exit}'); then
		eval "$(xwininfo -id "$WIN_ID" | awk -F: '
			/Width/  { gsub(/^[ \t]+/, "", $2); w=$2 }
			/Height/ { gsub(/^[ \t]+/, "", $2); h=$2 }
			END      { printf "W=%s\nH=%s\n", w, h }
		')"
	fi
}

record_x11() {
	local duration="$1"
	ffmpeg -hide_banner -y -f x11grab -video_size "${W}x${H}" \
		-framerate 30 -i ":99+0,0" \
		-pix_fmt yuv420p -c:v libx264 -preset ultrafast \
		-t "$duration" "$TERMVID"
}
