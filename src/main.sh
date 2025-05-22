#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$DIR/globals.sh"
source "$DIR/env.sh"
source "$DIR/title_templates.sh"
source "$DIR/terminal.sh"
source "$DIR/media.sh"
source "$DIR/cli.sh

main() {
	check_environment
	parse_args "$@"
	validate_args
	check_environment
	render_audio
	record_terminal
	compose_final_video
	echo "Done: $OUTVID"
}

main "$@"
