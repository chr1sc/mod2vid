
################################################################################
# template functions to substitute placeholders in -t with their values
read_openmpt_info() {
  local file="$1"
  openmpt123 --info "$file"|grep -F '.:'|grep -vF 'warning:'
}
get_info_field() {
	local field="$1"
	echo "$TRACK_INFO" | awk -F': +' -v key="$field" '
		{
			gsub(/^[ \t.]+|[ \t.]+$/, "", $1)
			if ($1 == key) print $2
		}
	'
}

# year is unreliable
get_module_year_label() {
	local file="$1"
	local raw_date
	raw_date=$(get_info_field "Date")

	if [[ -n "$raw_date" ]]; then
		echo "$(cut -c1-4 <<< "$raw_date")"
	else
		#local fake_date=$(stat -c %w "$file" 2>/dev/null | cut -c1-4)
		#echo "${fake_date}"
		echo "?"
	fi
}

build_text() {
	[[ -z "$TITLE_TEXT" ]] && return
	local template="$1"
	local artist=$(get_info_field "Artist")
	local title=$(get_info_field "Title")
	local filename=$(basename "${MODULE%%.*}")
	local size=$(get_info_field "Size")
	local duration=$(get_info_field "Duration")
	local year=$(get_module_year_label "$MODULE")
	# fallback values
	[[ -z "$title" ]] && title="$filename"
	[[ -z "$artist" ]] && artist="?"

	local result="$template"
	result=${result//\{artist\}/$artist}
	result=${result//\{title\}/$title}
	result=${result//\{filename\}/$filename}
	result=${result//\{size\}/$size}
	result=${result//\{duration\}/$duration}
	result=${result//\{year\}/$year}

	echo "$result"
}
