#!/bin/bash

filename="$1"

raw=($(convert $filename txt: | sed 's/(\|)//g' | tr ',' ';'))

width="$(cut -d';' -f1 <<< ${raw[4]})"
height="$(cut -d';' -f2 <<< ${raw[4]})"
depth="$(cut -d';' -f3 <<< ${raw[4]})"
format="$(cut -d';' -f4 <<< ${raw[4]})"

declare -A pixels

for i in $(seq 1 $(expr $width \* $height)); do
    pixels["${raw[$i*4+1]}"]="${raw[$i*4+2]}"
done

echo -ne "\e[?25l"

for y in $(seq 0 $(expr $height / 2 - 1)); do
    ybg="$(expr $y \* 2)"
    yfg="$(expr $y \* 2 + 1)"
    echo -ne '  '
    for x in $(seq 0 $(expr $width - 1)); do
        bgcolor=${pixels["$x;$ybg:"]}
        fgcolor=${pixels["$x;$yfg:"]}

        bgrgb="$(cut -d ';' -f1-3 <<< $bgcolor)"
        bga="$(cut -d ';' -f4 <<< $bgcolor)"

        fgrgb="$(cut -d ';' -f1-3 <<< $fgcolor)"
        fga="$(cut -d ';' -f4 <<< $fgcolor)"

        echo -ne "\e[0m"
        [ "$bga" = 0 ] && [ "$fga" = 0 ] && echo -ne ' '
        [ "$bga" = 0 ] && [ "$fga" != 0 ] && echo -ne "\e[38;2;${fgrgb}m▄"
        #[ "$bga" != 0 ] && [ "$fga" = 0 ] && echo -ne "\e[38;2;0;0;0m\e[48;2;${bgrgb}m▄"
        #[ "$bga" != 0 ] && [ "$fga" = 0 ] && echo -ne ' '
        [ "$bga" != 0 ] && [ "$fga" = 0 ] && echo -ne "\e[38;2;${bgrgb}m\e[48;2;${bgrgb}m▄"
        [ "$bga" != 0 ] && [ "$fga" != 0 ] && echo -ne "\e[38;2;${fgrgb}m\e[48;2;${bgrgb}m▄"
    done
    echo -e "\e[0m"
done

echo -ne "\e[?25h"
