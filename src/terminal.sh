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

build_xterm_command() {
	local cmd=(-fa Monospace -fs 10 -geometry "$GEOM")
	if [[ "$TERM_THEME" == "white" ]]; then
		cmd+=(-bg white -fg black -cr black)
	else
		cmd+=(-bg black -fg white -cr white)
	fi

	local mpt_args=(--progress --channel-meters --pattern "$MODULE")
	if [[ "$SUPPRESS_AUDIO" == 1 ]]; then
		mpt_args+=(--no-meters --gain -80)
	else
		mpt_args+=(--gain "$GAIN")
	fi

	local exec_cmd="sleep $DELAY; openmpt123 ${mpt_args[*]}; clear; sleep 2"
	cmd+=(-e "$exec_cmd")
	printf '%q ' "${cmd[@]}"
}

run_xterm() {
	eval xterm "$1"
}

detect_window_geometry() {
	W=800 H=600
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
