_info() {
	echo "mod2vid __VERSION__"
	echo "Usage: ${0##*/} [OPTIONS] <modfile>"
	echo "Use --help for more infos."
	exit 2
}

usage() {
	cat <<EOF
mod2vid v__VERSION__ -- 2025 by Christian Czinzoll
Usage: ${0##*/} [OPTIONS] <module file>

Create music videos from tracker modules with pattern visualization

Arguments:
  <module.it>         Path to a .it/.mod/.xm file for openmpt123

Options:
  -l, --load-settings <file> Load settings from a file
  -b, --background <file>    Background image/video
  -i, --input-audio <file>   Use custom audio file instead of rendering module
                             (Useful for tracks with VST plugins that need
                             to be rendered in OpenMPT first)
  -o, --output-file <file>   Save the final video to this file
  -t, --title "text"         Text overlay displayed at top of video
  -S, --subtitle-file <file> Play a subtitle file (.ass)
  -g, --gain <db>            Amplify output by <db> (0-10, default: 0)
  -n, --normalize            Amplify to 0dB
  -c, --columns <width>      Terminal width in characters (default: 80)
  -r, --rows <height>        Terminal height in characters (default: 24)
  -d, --delay <seconds>      Delay before recording starts (default: $DEFAULT_DELAY)
  -s, --skip-term            Skip terminal recording if _term.mp4 exists
  -N, --no-metadata          Strip all metadata from output video
  -Q, --no-trackinfo         If no background was specified, the video will
                             show some track info.
                             You can turn off this behavior with this switch.
  -p, --print-settings       Print current settings, including from template file
  -h, --help                 Show this help message

Examples:
  ${0##*/} song.it -t "Epic Track" -n
  ${0##*/} -i final.wav -b background.jpg song.mptm -o final_song.mp4
  ${0##*/} --title "{artist} - {title}" module.mod
  ${0##*/} -t "Retro" -c 100 -r 30 song.it
EOF
	exit 0
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-l|--load-settings) SETTINGS_FILE="$2"; shift 2 ;;
			-b|--background)
				BACKGROUND_IMAGE="$2"
				BACKGROUND_IMAGE_CMDLINE="$2"
				shift 2 ;;
			-i|--input-audio) CUSTOM_WAV="$2"; AUDIO="$2"; shift 2 ;;
			-o|--output-file) OUTVID_CMDLINE="$2"; shift 2 ;;
			-S|--subtitle-file) SUBTITLE_FILE="$2"; shift 2 ;;
			-t|--title)
				TITLE_TEXT="$2"
				TITLE_TEXT_CMDLINE="$2"
				shift 2 ;;
			-g|--gain)
				GAIN="$2"; shift 2 ;;
			-c|--columns)
				TERMINAL_COLS="$2"
				TERMINAL_COLS_CMDLINE="$2"
				shift 2 ;;
			-r|--rows)
				TERMINAL_ROWS="$2"
				TERMINAL_ROWS_CMDLINE="$2"
				shift 2 ;;
			-d|--delay)
				DELAY="$2"
				DELAY_CMDLINE="$2"
				shift 2 ;;
			-s|--skip-term)   SKIP_TERM=1; shift ;;
			-Q|--no-trackinfo)NO_TRACK_INFO=1; shift ;;
			-N|--no-metadata) NO_META=1; shift ;;
			-n|--normalize)   NORMALIZE=1; shift ;;
			-p|--print-settings) PRINT_SETTINGS=1; shift ;;
			-h|--help)        usage; exit 0 ;;
			--)               shift; POSITIONAL+=("$@"); break ;;
			-*|--*)           die "Unknown Option: $1" 1 ;;
			*)                POSITIONAL+=("$1"); shift ;;
		esac
	done
}

check_bounds() {
	local val="$1"
	local min="${2:- -2.0}"
	local max="${3:- 2.0}"
	if ! [[ "$val" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
		echo "1.0"
		return 1
	fi
	awk -v val="$val" -v min="$min" -v max="$max" \
	'BEGIN {
		printf "%.2f",(val<min)?min:(val>max)?max:val
	}'
}

handle_cmdline_overrides() {
	# command line arguments override template settings
	if [[ -n "$TITLE_TEXT_CMDLINE" ]]; then
		TITLE_TEXT="$TITLE_TEXT_CMDLINE"
	fi
	if [[ -n "$TERMINAL_COLS_CMDLINE" ]]; then
		TERMINAL_COLS="$TERMINAL_COLS_CMDLINE"
	fi
	if [[ -n "$TERMINAL_ROWS_CMDLINE" ]]; then
		TERMINAL_ROWS="$TERMINAL_ROWS_CMDLINE"
	fi
}

resolve_background_path() {
	local image_path="$1"

	# try absolute path first
	[[ -f "$image_path" ]] && {
		echo "$image_path"
		return 0
	}

	# try relative to settings file directory
	if [[ -n "$SETTINGS_FILE" ]]; then
		local settings_dir="$(dirname "$(realpath "$SETTINGS_FILE")")"
		local resolved_path="${settings_dir}/${image_path}"
		[[ -f "$resolved_path" ]] && {
			echo "$resolved_path"
			return 0
		}
	fi

	# try relative to execution directory
	local exec_dir="$(pwd)"
	local resolved_path="${exec_dir}/${image_path}"
	[[ -f "$resolved_path" ]] && {
		echo "$resolved_path"
		return 0
	}

	return 1
}

select_background_image() {

	# check command-line override first
	if [[ -n "$BACKGROUND_IMAGE_CMDLINE" ]]; then
		BACKGROUND_IMAGE="$(resolve_background_path "$BACKGROUND_IMAGE_CMDLINE")" || {
			die "Could not resolve background image: $BACKGROUND_IMAGE_CMDLINE" 1
		}
	# random selection from pool if available
	elif [[ ${#BACKGROUND_IMAGE_POOL[@]} -gt 1 ]]; then
		local random_index=$((RANDOM % ${#BACKGROUND_IMAGE_POOL[@]}))
		local selected_image="${BACKGROUND_IMAGE_POOL[random_index]}"

		BACKGROUND_IMAGE="$(resolve_background_path "$selected_image")" || {
			#warn "Could not resolve pool image '$selected_image', trying next..."
			unset "BACKGROUND_IMAGE_POOL[random_index]"
			BACKGROUND_IMAGE_POOL=("${BACKGROUND_IMAGE_POOL[@]}")
			select_background_image
			return
		}
		echo "Selected random background: $BACKGROUND_IMAGE" >&2

	# fallback
	elif [[ -z "$BACKGROUND_IMAGE" ]]; then
		generate_track_info_image "$MODULE" "$BASENAME" || {
			die "Failed to generate track info image" 1
		}
		BACKGROUND_IMAGE="$(realpath "${BASENAME}_info.png")"
		echo "Using generated track info as background" >&2
	fi

	ensure_file_readable "$BACKGROUND_IMAGE" || {
		die "Background image not accessible: $BACKGROUND_IMAGE" 1
	}

	echo "Using Background: $BACKGROUND_IMAGE" >&2
}

validate_template_variables() {
	PATTERN_COLOR_BOOST_R=$(check_bounds $PATTERN_COLOR_BOOST_R -2.0 2.0)
	PATTERN_COLOR_BOOST_G=$(check_bounds $PATTERN_COLOR_BOOST_G -2.0 2.0)
	PATTERN_COLOR_BOOST_B=$(check_bounds $PATTERN_COLOR_BOOST_B -2.0 2.0)
	TERM_FONT_SIZE=$(check_bounds "$TERM_FONT_SIZE" 6 36)
}

include_settings_file() {
	if [[ -n "$SETTINGS_FILE" ]]; then
		ensure_file_readable "$SETTINGS_FILE"
		if head -n 1 "$SETTINGS_FILE" | grep -q "^# mod2vid template"; then
			source "$SETTINGS_FILE"
		else
			die "'$SETTINGS_FILE' is not a valid mod2vid settings file (missing header '# mod2vid template')." 1
		fi
	fi
}

validate_freqwav_settings() {
	case "$FREQ_MODE" in
		bar|dot|line) ;;
		*)
			warn "FREQ_MODE='$FREQ_MODE' invalid, falling back to default 'dot'"
			FREQ_MODE=dot
			;;
	esac
	case "$FREQ_FSCALE" in
		lin|log|rlog) ;;
		*)
			warn "FREQ_FSCALE='$FREQ_FSCALE' invalid, falling back to default 'log'"
			FREQ_FSCALE=log
			;;
	esac
	case "$FREQ_ASCALE" in
		lin|sqrt|cbrt|log) ;;
		*)
			warn "FREQ_ASCALE='$FREQ_ASCALE' invalid, falling back to default 'lin'"
			FREQ_ASCALE=lin
			;;
	esac
	if ! [[ "$FREQ_HEIGHT" =~ ^[0-9]+$ ]] || (( FREQ_HEIGHT <= 0 )); then
		warn "FREQ_HEIGHT='$FREQ_HEIGHT' is not a number"
		FREQ_HEIGHT=200
	fi
	if ! [[ "$FREQ_WINSIZE" =~ ^[0-9]+$ ]] || (( FREQ_WINSIZE <= 0 )); then
		warn "FREQ_WINSIZE='$FREQ_WINSIZE' is not a number. Ideally use a power of two"
		FREQ_WINSIZE=512
	fi

	# currently not in use
	if ! [[ "$FREQ_COL_ALPHA" =~ ^0(\.[0-9]+)?$|^1(\.0*)?$ ]]; then
		warn "FREQ_COLS_ALPHA='$FREQ_COL_ALPHA' invalid, falling back to default 0.6"
		FREQ_COL_ALPHA=0.6
	fi
	if ! [[ "$FREQ_TRANSPOSE" =~ ^[0-7]$ ]]; then
		warn "FREQ_TRANSPOSE='$FREQ_TRANSPOSE' invalid falling back to default 0"
		FREQ_TRANSPOSE=0
	fi
}

validate_args() {
	if [[ ! -f "$TITLE_FONT_FILE" ]]; then
		warn "Font file not found: $TITLE_FONT_FILE (using default)"
	fi

	include_settings_file

	# command line arguments override template settings
	handle_cmdline_overrides

	validate_template_variables

	#get the module name
	if [[ ${#POSITIONAL[@]} -gt 0 ]]; then
		MODULE="${POSITIONAL[0]}"
		if [[ ${#POSITIONAL[@]} -gt 1 ]]; then
			warn "Extra arguments ignored: ${POSITIONAL[*]:1}"
		fi
	fi

	# no module nor -p: print info
	[[ -z "$MODULE" && "$PRINT_SETTINGS" -ne 1 ]] && {
		_info
	}

	# only handle module if given as arg
	if [[ -n "$MODULE" ]]; then
		ensure_file_readable "$MODULE"
		BASENAME="${MODULE%.*}"
		WAV="${MODULE}.wav"
		# get the module and track info (-t)
		TRACK_INFO=$(read_openmpt_info "$MODULE");
	fi

	[[ -z "$CUSTOM_WAV" ]] && AUDIO="$WAV"

	if [[ $NORMALIZE -eq 1 && -n $CUSTOM_WAV ]]; then
		warn "Will not normalize (-n) pre-recorded (-i) audio files"
	fi
	if [[ $NORMALIZE -eq 1 && $GAIN -ne 0 && $SUPPRESS_AUDIO -eq 0 ]]; then
		die "Normalize (-n) and Gain (-g) collision" 2
	fi
	[[ -z "$TITLE_TEXT" ]] && {
		TITLE_TEXT="$(basename "${BASENAME//_/ }")"
	}

	TERMVID="${BASENAME}_term.mp4"
	OUTVID="${BASENAME}.mp4"
	if [[ -n "$OUTVID_CMDLINE" ]]; then
		OUTVID="$OUTVID_CMDLINE"
	fi

	GEOM="${TERMINAL_COLS}x${TERMINAL_ROWS}"

	TITLE_TEXT="$(build_text "$TITLE_TEXT")"
	TITLE_TEXT="$(escape_text_for_ffmpeg "$TITLE_TEXT")"
	[[ -n "$MODULE" ]] && echo "${YELLOW}TITLE TEXT: $TITLE_TEXT${RESET}"

	if [[ -n "$LOGO_FILE" ]]; then
		ensure_file_readable "$LOGO_FILE"
	fi
	if [[ -n "$SUBTITLE_FILE" ]]; then
		ensure_file_readable "$SUBTITLE_FILE"
	fi
	if ! [[ "$GAIN" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
		die "Gain is not a valid number" 2
	fi
	# just some arbitrary bounds
	if ! bc <<< "$GAIN >= -80 && $GAIN <= 80" | grep -q 1; then
		die "Gain is out of range (-80..80)" 2
	fi
	# ditto
	if (( $(bc <<< "$DELAY < $MIN_DELAY || $DELAY > $MAX_DELAY") )); then
		die "Delay value must be between $MIN_DELAY and $MAX_DELAY seconds" 2
	fi

	[[ -n "$MODULE" ]] && select_background_image

	# will only validate if used
	if (( SHOW_FREQ == 1 )); then
		validate_freqwav_settings
	fi

	case "$SPECTRUM_COLOR" in
		channel|intensity|rainbow|moreland|nebulae|fire|fiery|fruit|cool|magma|green|viridis|plasma|cividis|terrain)
			;;
		*)
			warn "Invalid SPECTRUM_COLOR '$SPECTRUM_COLOR', using default 'channel'"
			SPECTRUM_COLOR="channel"
			;;
	esac
	case "$OVERVIEW_COLOR" in
		channel|intensity|rainbow|moreland|nebulae|fire|fiery|fruit|cool|magma|green|viridis|plasma|cividis|terrain)
			;;
		*)
			warn "Invalid OVERVIEW_COLOR '$OVERVIEW_COLOR', using default 'channel'"
			OVERVIEW_COLOR="channel"
			;;
	esac

	if (( PRINT_SETTINGS == 1 )); then
		print_settings
		[[ -z "$MODULE" ]] && exit 0
	fi
}
