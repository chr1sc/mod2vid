

XVFB_PID=""
cleanup() {
  # kill Xvfb if running
  [[ -n "$XVFB_PID" ]] && kill "$XVFB_PID" 2>/dev/null
  rm -f "$TMP_WAV" "$TERMVID.lock" 2>/dev/null
}


die() {
	local code=${2:-1}
	echo "${RED}Error: $1${RESET}" >&2
	exit "$code"
}

warn() {
	echo "${YELLOW}Warning: $1${RESET}" >&2
}

ensure_file_exists() {
	[[ -f "$1" ]] || die "File does not exist: $1"
}

ensure_file_readable() {
    ensure_file_exists "$1" && [[ -r "$1" ]] || die "File not readable: $1"
}

# Only Debian help for now
check_environment() {
	local tools=(openmpt123 ffmpeg sox convert xterm Xvfb xwininfo)
	for tool in "${tools[@]}"; do
		command -v "$tool" >/dev/null || {
			echo "${RED}Missing: $BOLD$tool$RESET"
			echo -en "If you're on Debian/Ubuntu/Mint, install packages with"
			echo "  sudo apt install openmpt123 ffmpeg sox imagemagick xterm xvfb x11-utils"
			exit 1
		}
	done
}
