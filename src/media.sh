
get_media_duration() {
	local file="$1"
	ffprobe -hide_banner -v error -show_entries format=duration \
		-of default=nokey=1:noprint_wrappers=1 "$file"
}

is_image_file() {
	local file="$1"
	file "$file" | grep -qE 'image|bitmap'
}

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
		:scale=log[overview];\
		${overlay_input}[overview]overlay=${OVERVIEW_POS}[vis${overlay_count}];"
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

	# EQ
	if [[ "$SHOW_EQ" -eq 1 ]]; then
		filter_complex+="\
		[0:a]showfreqs=s=${EQ_WIDTH}x${EQ_HEIGHT}:\
		mode=${EQ_MODE}:\
		fscale=${EQ_FSCALE}:\
		ascale=${EQ_ASCALE}:\
		colors=${EQ_COL_1}@${EQ_COL_ALPHA}|${EQ_COL_2}@${EQ_COL_ALPHA}:\
		win_size=${EQ_WINSIZE}:\
		overlap=0[eq];"
		case "$EQ_TRANSPOSE" in
			0) filter_complex+="[eq]copy[eq2];" ;;
			1) filter_complex+="[eq]transpose=1[eq2];" ;;
			2) filter_complex+="[eq]transpose=1,transpose=1[eq2];" ;;
			3) filter_complex+="[eq]transpose=3[eq2];" ;;
			4) filter_complex+="[eq]hflip[eq2];" ;;
			5) filter_complex+="[eq]vflip[eq2];" ;;
			6) filter_complex+="[eq]transpose=1,hflip[eq2];" ;;
			7) filter_complex+="[eq]transpose=3,vflip[eq2];" ;;
			*) echo "Ungültiger Wert für EQ_TRANSPOSE: $EQ_TRANSPOSE" >&2; exit 1 ;;
		esac
		filter_complex+="\
		${overlay_input}[eq2]overlay=${EQ_POS_X}:${EQ_POS_Y}[vis${overlay_count}];"
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
		fontcolor=${TITLE_FONT_COLOR}:\
		fontsize=${TITLE_FONT_SIZE}:\
		fontfile=${TITLE_FONT_FILE}:\
		${TITLE_TEXT_POSITION}:\
		shadowx=${TITLE_SHADOW_X}:shadowy=${TITLE_SHADOW_Y}[with_title];"

	# SUBTITLE
	if [[ "$SHOW_SUBTITLES" -eq 1 ]]; then
		filter_complex+="\
		[with_title]subtitles=filename='${SUBTITLE_FILE}':\
		force_style='\
		Fontname=${SUBTITLE_FONT_FILE##*/},\
		Fontsize=${SUBTITLE_FONT_SIZE},\
		PrimaryColour=${SUBTITLE_COLOR},\
		OutlineColour=&H000000,\
		BackColour=&H80000000,\
		BorderStyle=3,\
		Outline=1,\
		Shadow=1,\
		Alignment=2'[subtitled];"
		overlay_input="[subtitled]"
	else
		filter_complex+="[with_title]copy[subtitled];"
	fi

	# LOGO BRANCH
	if [[ "$SHOW_LOGO" -eq 1 ]]; then
		filter_complex+="\
		[4:v]scale=${LOGO_SIZE},format=rgba,colorkey=black:0.1:0.1[logo];\
		[subtitled][logo]overlay=${LOGO_POSITION}[outv];"
	else
		filter_complex+="[subtitled]copy[wm];"
	fi
	filter_complex+="\
		[wm]drawtext=text='github.com/chr1sc/mod2wav':x=4:y=h-th-4:fontsize=20:\
      fontcolor=white@0.3:shadowx=2:shadowy=2[outv]"

	echo "${filter_complex}"
}

render_audio() {
	[[ -n "$CUSTOM_WAV" ]] && {
		echo "Using provided audio: $CUSTOM_WAV"
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

		# Calculate gain
		if (( $(echo "$peak == 0" | bc -l) )); then
			GAIN=0
		else
			db=$(echo "20*l($peak)/l(10)" | bc -l)
			GAIN=$(echo "$TARGET_DBFS - $db" | bc | awk '{print int($1 + ($1>0?0.5:-0.5))}')
			# Clamp between -20 and 20
			(( GAIN > 20 )) && GAIN=20
			(( GAIN < -20 )) && GAIN=-20
		fi

		# no need to render the wav a second time if there is nothing
		# to gain :D
		if [[ "$GAIN" -le 0 ]]; then
			return
		fi
		echo "Will gain the audio by $GAIN dB"
	fi

	openmpt123 --render --force --gain "$GAIN" "$MODULE"
}

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

	local metadata_flag=()
	[[ "$META" -eq 1 ]] && metadata_flag=(-map_metadata -1)

	local filter_complex=$(get_filter_complex)
	local map_out="[outv]"

	ffmpeg -hide_banner -y \
		-i "$AUDIO" \
		-i "$TERMVID" \
		"${image_input[@]}" -i "$BACKGROUND_IMAGE" \
		$( [ "$SHOW_LOGO" -eq 1 ] && echo "-i" "$LOGO_FILE" ) \
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

generate_track_info_image() {
	local module_file="$1"
	local basename="$2"
	local font="$TITLE_FONT_MONO"
	local output="${basename}_info.png"

	# just generate a black background
	if (( NO_TRACK_INFO == 1 )); then
		if ! convert -size 1920x1080 "${BACKGROUND_COLOR}" \
					"$output"; then
			echo "Error: Failed to create image with convert" >&2
			exit 1
		fi
		return
	fi

	if ! convert -size 1920x1080 "$BACKGROUND_COLOR" -fill white \
				-font "$font" \
				-pointsize 16 -annotate +10+100 "$TRACK_INFO" \
				"$output"; then
		echo "Error: Failed to create image with convert" >&2
		exit 1
	fi
}

