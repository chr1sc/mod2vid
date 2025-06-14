
# TODO Reduce use of globals ... but then, it's Bash

# Function:    get_media_duration
# Outputs:     Length of an audio or video in seconds.milliseconds
get_media_duration() {
	local file="$1"
	ffprobe -hide_banner -v error -show_entries format=duration \
		-of default=nokey=1:noprint_wrappers=1 "$file"
}

# Function:    is_image_file
# Returns:     0 on success, otherwise 1
is_image_file() {
	local file="$1"
	file "$file" | grep -qE 'image|bitmap'
}

# Function:    escape_text_for_ffmpeg
# Description: Escape some characters that are not allowed inside an
#              ffmpeg filter complex string
# Outputs:     the escaped string safe for use in filter_complex
escape_text_for_ffmpeg() {
    local text="$1"
    if [[ -n "$text" ]]; then
        # Escape \ and ' (backslash and single quote)
        text="${text//\\/\\\\}"
        text="${text//\'/\\\'}"
        # Escape : and , by prefixing with backslash
        text="${text//:/\\:}"
        text="${text//,/\\,}"
        echo "$text"
    fi
}

# Function:    get_filter_complex
# Description: Conditional construction of the filter string
# Outputs:     filter complex string for ffmpeg
get_filter_complex() {
	local filter_complex="\
		[1:v]\
			lut=\
				r='pow(val/255\,1/${PATTERN_GAMMA_R})*255':\
				g='pow(val/255\,1/${PATTERN_GAMMA_G})*255':\
				b='pow(val/255\,1/${PATTERN_GAMMA_B})*255',\
			colorchannelmixer=\
				rr=${PATTERN_COLOR_BOOST_R}:\
				gg=${PATTERN_COLOR_BOOST_G}:\
				bb=${PATTERN_COLOR_BOOST_B},\
			colorkey=black:0.1:0.2,\
			split=2[original][for_glow];\
		[for_glow]\
			boxblur=${PATTERN_GLOW_RADIUS},\
			colorchannelmixer=aa=${PATTERN_GLOW_OPACITY},\
			[original]blend=all_mode=${PATTERN_GLOW_MODE}:all_opacity=1[glowed];\
		[glowed]\
			scale=${PATTERN_WIDTH}:${PATTERN_HEIGHT},\
			pad=\
			width=max(iw\,1920):\
			height=max(ih\,1080):\
			x='(ow-iw)/2 + if(gt(${PATTERN_OFFSET_X}\, (ow-iw)/2)\, (ow-iw)/2\, if(lt(${PATTERN_OFFSET_X}\, -(ow-iw)/2)\, -(ow-iw)/2\, ${PATTERN_OFFSET_X}))':\
			y='(oh-ih)/2 + if(gt(${PATTERN_OFFSET_Y}\, (oh-ih)/2)\, (oh-ih)/2\, if(lt(${PATTERN_OFFSET_Y}\, -(oh-ih)/2)\, -(oh-ih)/2\, ${PATTERN_OFFSET_Y}))'\
		[term];\
		[2:v]\
			scale=1920:1080,\
			format=yuva420p,\
			colorchannelmixer=aa=0.5\
			[innerbg];\
		[2:v]\
			scale=1920:1080,\
			format=yuva420p,\
			colorchannelmixer=aa=0.5\
			[outerbg];\
		[innerbg]\
		[term]\
			overlay=format=auto\
			[tmp];\
		[tmp]\
		[outerbg]\
			overlay=(W-w)/1.0:(H-h)/1.0\
			[base];"

	local overlay_input="[base]"
	local overlay_count=0

	# SHOW_OVERVIEW
	if [[ "$SHOW_OVERVIEW" -eq 1 ]]; then
		filter_complex+="[0:a]showspectrumpic=s=${OVERVIEW_WIDTH}x${OVERVIEW_HEIGHT}\
		:legend=disabled:scale=log[overview];\
		${overlay_input}[overview]overlay=${OVERVIEW_POS_X}:${OVERVIEW_POS_Y}[vis${overlay_count}];"
		overlay_input="[vis${overlay_count}]"
		((overlay_count++))
	fi

	# SHOW_SPECTRUM
	if [[ "$SHOW_SPECTRUM" -eq 1 ]]; then
		filter_complex+="\
		[0:a]showspectrum=s=${SPECTRUM_WIDTH}x${SPECTRUM_HEIGHT}:\
		mode=combined:color=${SPECTRUM_COLOR}[spec_raw];\
		[spec_raw]colorkey=black:0.4:0.3[specvis];\
		${overlay_input}[specvis]overlay=${SPECTRUM_POS_X}:${SPECTRUM_POS_Y}[vis${overlay_count}];"
		overlay_input="[vis${overlay_count}]"
		((overlay_count++))
	fi

	# SHOW_WAVES
	if [[ "$SHOW_WAVES" -eq 1 ]]; then
		filter_complex+="[0:a]showwaves=s=${WAVES_SIZE}:mode=${WAVES_MODE}:colors=${WAVES_COLOR}[wavevis];\
		${overlay_input}[wavevis]overlay=${WAVES_POS_X}:${WAVES_POS_Y}[vis${overlay_count}];"
		overlay_input="[vis${overlay_count}]"
		((overlay_count++))
	fi

	# FREQ
	if [[ "$SHOW_FREQ" -eq 1 ]]; then
		filter_complex+="\
		[0:a]showfreqs=s=${FREQ_WIDTH}x${FREQ_HEIGHT}:\
		mode=${FREQ_MODE}:\
		fscale=${FREQ_FSCALE}:\
		ascale=${FREQ_ASCALE}:\
		colors=${FREQ_COL_1}@${FREQ_COL_ALPHA}|${FREQ_COL_2}@${FREQ_COL_ALPHA}:\
		win_size=${FREQ_WINSIZE}:\
		overlap=0[eq];"
		case "$FREQ_TRANSPOSE" in
			0) filter_complex+="[eq]copy[eq2];" ;;
			1) filter_complex+="[eq]transpose=1[eq2];" ;;
			2) filter_complex+="[eq]transpose=1,transpose=1[eq2];" ;;
			3) filter_complex+="[eq]transpose=3[eq2];" ;;
			4) filter_complex+="[eq]hflip[eq2];" ;;
			5) filter_complex+="[eq]vflip[eq2];" ;;
			6) filter_complex+="[eq]transpose=1,hflip[eq2];" ;;
			7) filter_complex+="[eq]transpose=3,vflip[eq2];" ;;
			*) echo "Ungültiger Wert für FREQ_TRANSPOSE: $FREQ_TRANSPOSE" >&2; exit 1 ;;
		esac
		filter_complex+="\
		${overlay_input}[eq2]overlay=${FREQ_POS_X}:${FREQ_POS_Y}[vis${overlay_count}];"
		overlay_input="[vis${overlay_count}]"
		((overlay_count++))
	# no EQ
	else
		filter_complex+="\
		${overlay_input}copy[vis${overlay_count}];"
		overlay_input="[vis${overlay_count}]"
		((overlay_count++))
	fi

	filter_complex+="\
		${overlay_input}drawtext=text='${TITLE_TEXT}':\
		fontcolor=${TITLE_FONT_COLOR}@${TITLE_FONT_ALPHA}:\
		fontsize=${TITLE_FONT_SIZE}:\
		fontfile=${TITLE_FONT_FILE}:\
		x=${TITLE_TEXT_POS_X}:y=${TITLE_TEXT_POS_Y}:\
		shadowx=${TITLE_SHADOW_X}:shadowy=${TITLE_SHADOW_Y}[with_title];"

	# SUBTITLE
	if [[ -n "$SUBTITLE_FILE" ]]; then
		filter_complex+="\
		[with_title]subtitles=filename='${SUBTITLE_FILE}'[subtitled];"
		overlay_input="[subtitled]"
	else
		filter_complex+="[with_title]copy[subtitled];"
	fi

	# LOGO BRANCH
	if [[ -n "$LOGO_FILE" ]]; then
		filter_complex+="\
		[4:v]scale=${LOGO_SIZE},format=rgba,colorkey=black:0.1:0.1[logo];\
		[subtitled][logo]overlay=${LOGO_POSITION}[outv];"
	else
		filter_complex+="[subtitled]copy[wm];"
	fi
	filter_complex+="\
		[wm]drawtext=text='github.com/chr1sc/mod2vid':x=4:y=h-th-4:fontsize=20:\
      fontcolor=white@0.3:shadowx=2:shadowy=2[outv]"

	echo "${filter_complex}"
}

# Function:    render_audio
# Description: Calls openmpt123 to render a module file to wav.
#              If NORMALIZE==1 the maximum gain is calculated
#              and openmpt123 is invoked a 2nd time, now with
#              the new GAIN value
# Returns
render_audio() {

	# user provided an audio file (-i): Do nothing
	[[ -n "$CUSTOM_WAV" ]] && {
		echo "Using provided audio: $CUSTOM_WAV"
		WAV="$CUSTOM_WAV"
		return
	}

	echo "Rendering audio..."

	if [[ "$NORMALIZE" == 1 ]]; then
		# when NORMALIZE is active
		# we have to do the wav render twice in order to determine
		# the level of amplification we can apply
		# TODO RMS instead of simple peak
		openmpt123 --render --force "$MODULE" 2>&1 >/dev/null

		# calculate peak amplitude
		local peak=$(sox "$WAV" -n stat 2>&1 | awk '/Maximum amplitude/ {print $3 < 0 ? -$3 : $3}')

		if (( $(echo "$peak == 0" | bc -l) )); then
			GAIN=0
		# Calculate gain
		else
			db=$(echo "20*l($peak)/l(10)" | bc -l)
			GAIN=$(echo "$TARGET_DBFS - $db" | bc | awk '{print int($1 + ($1>0?0.5:-0.5))}')
			# Clamp between -20 and 20
			(( GAIN > 20 )) && GAIN=20
			(( GAIN < -20 )) && GAIN=-20
		fi

		if [[ "$GAIN" -le 0 ]]; then
			return
		fi
		echo "Will gain the audio by $GAIN dB"
	fi

	openmpt123 --render --force --gain "$GAIN" "$MODULE"
}

# Function:    compose_final_video
# Description: The 'main' function of this file, creating the
#              final video
compose_final_video() {
	echo "Creating final video..."
	AUDIO_DURATION=$(get_media_duration "$AUDIO")

	# is our background an image or a video
	local image_input=()
	if is_image_file "$BACKGROUND_IMAGE"; then
		image_input=(-loop 1 -framerate 30)
	else
		image_input=(-stream_loop -1)
	fi

	# strip all meta data from the final video
	local metadata_flag=()
	[[ "$NO_META" -eq 1 ]] && \
		metadata_flag=(-map_metadata -1)

	local filter_complex=$(get_filter_complex)
	local map_out="[outv]"

	ffmpeg -hide_banner -y \
		-i "$AUDIO" \
		-i "$TERMVID" \
		"${image_input[@]}" -i "$BACKGROUND_IMAGE" \
		$( [ -n "$LOGO_FILE" ] && echo "-i" "$LOGO_FILE" ) \
		"${metadata_flag[@]}" \
		-filter_complex "$filter_complex" -filter_threads 4 \
		-map 0:a \
		-map "$map_out" \
		-c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p \
		-c:a aac -b:a 192k \
		-movflags +faststart \
		-shortest \
		"$OUTVID"
}

# Function:    generate_track_info_image
# Description: Generates an *_info.png file of a module with some
#              module infos.
# Parameters:
#       $1     the module filename
#       $2     basename XXX can be derived from $1
# Exits on error
generate_track_info_image() {
	local module_file="$1"
	local basename="$2"
	local font="$TITLE_FONT_MONO"
	local output="${basename}_info.png"

	# just generate a black background if NO_TRACK_INFO is set
	if (( NO_TRACK_INFO == 1 )); then
		if ! convert -size 1920x1080 "${BACKGROUND_COLOR}" \
					"$output"; then
			die "Error: Failed to create image with convert" 1
		fi
		return
	fi

	# generate the backgorund with the track info written on it
	if ! convert -size 1920x1080 "$BACKGROUND_COLOR" -fill white \
				-font "$font" \
				-pointsize 16 -annotate +10+100 "$TRACK_INFO" \
				"$output"; then
		die "Error: Failed to create image with convert" 1
	fi
}

