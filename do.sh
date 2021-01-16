#!/usr/bin/env bash

# https://github.com/Taiwanese-Corpus/hue7jip8/blob/master/匯入/教育部閩南語常用詞辭典/下載臺語教典音檔-官網沓沓掠.sh

# https://stackoverflow.com/questions/14811979/write-bash-script-that-reads-from-pipe
# `cat |`

# https://unix.stackexchange.com/questions/52762/trying-to-sort-on-two-fields-second-then-first
# `sort -k...`

# `printf` newlines are not saved in variables? so output `;` and ask `sed` to make newlines

# 主編碼,屬性,詞目,音讀,文白,部首
# 7,1,一日到暗,tsi̍t-ji̍t-kàu-àm/tsi̍t-li̍t-kàu-àm,0,
# 22957,2,讓,jiōng/liōng,1,言

# 屬性 2 words (單字?) apparently do not have audio

url_csv="https://github.com/Taiwanese-Corpus/hue7jip8/raw/master/匯入/教育部閩南語常用詞辭典/詞目總檔.csv"
file_path_csv="./zungdong.csv"

url_audio="https://twblg.dict.edu.tw/holodict_new/audio/%s.mp3"
file_path_audios_list="./jamdong_jatlaam.txt"

sed_xlit_tones="y/́̀̂̄̍̋/235789/"
sed_sub_syllablefinal_tone="s/([0-9])([a-z]+)/\2\1/g"
sed_sub_neutral_tone="s/--([a-z]+)[0-9]?/\10/g"
sed_sub_1_4_tone="s/([ptkh])$/\14/g; s/([^0-9])$/\11/g"
sed_xlit_2lc="y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"

tl2ascii() {
	cat | uconv -x any-nfd | sed -E "$sed_xlit_tones; $sed_sub_syllablefinal_tone"
}

if [ ! -e "$file_path_csv" ]
then
	wget "$url_csv" -O "$file_path_csv"
fi

# do as much as we can here, instead of in the loop. all lines, all at once
# grep: find $屬性 == 1 and len($詞目) == 1
# cut: remove unneeded fields. probably makes subsequent operations faster
# sed: remove alternate pronunciation ($音讀)
# tl2ascii: 臺羅 to ASCII
# sort: sort by $音讀
# sed: mark tones 1 and 4; uppercase to lowercase
csv_filtered=$(grep -P '([^,]),(1),([^,]{1}),.+' "$file_path_csv" | cut -d',' -f1,4 | sed -E 's/\/([^,]+)//g' | tl2ascii | sed -E "$sed_sub_neutral_tone; $sed_sub_1_4_tone; $sed_xlit_2lc" | sort -t ',' -k 2,2 -k 1,1 --version-sort)

if [ ! -e "$file_path_audios_list" ]
then
	audios_list=""
	while IFS=',' read zyupinmaa jamduk
	do
		zyupinmaa=$(printf "%05d" "$zyupinmaa")
		audios_list+=$(printf "${url_audio}#%s;" "$zyupinmaa" "$jamduk")
	done < <(echo "$csv_filtered")
	echo "$audios_list" | sed "s/;/\n/g" | tee "$file_path_audios_list"
fi
