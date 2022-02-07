#!/usr/bin/env bash

# https://stackoverflow.com/questions/1527049/how-can-i-join-elements-of-an-array-in-bash

file_path_audios_list="./jamdong_jatlaam.txt"
tones="01234578"
tones_priority="17253048" # prioritize high flat tone contour
sed_xlit_priority="y/$tones_priority/$tones/"
sed_xlit_unpriority="y/$tones/$tones_priority/"

syllables_or=$(IFS="|"; echo "($*)")

dir_out_mp3="mp3"
dir_out_wav="wav"

csv_filtered=$(grep -P "#$syllables_or[0-9]$" "$file_path_audios_list" | sed "$sed_xlit_priority" | sort -t '#' -k 2,2 -k 1,1 --version-sort | sed "$sed_xlit_unpriority")

error=""

for syllable in "$@"
do
	url=$(echo "$csv_filtered" | grep -P --max-count=1 "#$syllable")
	if [ -z "$url" ]
	then
		error+="Search failed for $syllable"
		continue
	fi
	name_clean=$(basename "$url" | sed -E "s/(.+)\.mp3#(.+)/\2-\1/g")
	if [ -e "$dir_out_wav/$name_clean.wav" ]
	then
		error+="Already downloaded for $syllable;"
		continue
	else
		result_wget=$(LANG=C wget "$url" -O "$dir_out_mp3/$name_clean.mp3" --no-clobber)
		ffmpeg -i "$dir_out_mp3/$name_clean.mp3" "$dir_out_wav/$name_clean.wav"
		echo "$name_clean.wav=$syllable,,,,," >> "$dir_out_wav/oto.ini"
	fi
done

if [ "$error" ]
then
	echo "$error" | sed "s/;/\n/g"
fi