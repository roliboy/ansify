#!/bin/bash

while [ "$#" -gt 0 ]; do
case "$1" in
    -h|--help)
        echo "usage:"
        echo "    $0 [options] filename"
        echo "options:"
        echo "    -a, --alpha: specify method for handling transparency on filled background and transparent foreground edge case"
        echo "        duplicate (default): draw the foreground with the same color as the background"
        echo "        skip: don't draw background either"
        echo "        <custom>: fill transparency with custom color, where <custom> is a rgb triplet of the form 'r,g,b'"
        exit 0
        shift
        ;;
    -a|--alpha)
        alpha_method="$2"
        if [ "$alpha_method" = duplicate ]; then
            :
        elif [ "$alpha_method" = skip ]; then
            :
        elif [ "$(awk -F',' '{print NF-1}' <<< $alpha_method)" = 2 ]; then
            alpha_method="$(tr ',' ';' <<< $alpha_method)"
        else
            echo invalid argument for --alpha
            exit 2
        fi
        shift 2
        ;;
    *)
        filename="$1"
        shift
        ;;
esac
done

[ -z "$filename" ] && echo no file provided && exit 1
[ -z "$alpha_method" ] && alpha_method="duplicate"

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
    for x in $(seq 0 $(expr $width - 1)); do
        bgcolor=${pixels["$x;$ybg:"]}
        fgcolor=${pixels["$x;$yfg:"]}

        bgrgb="$(cut -d ';' -f1-3 <<< $bgcolor)"
        bga="$(cut -d ';' -f4 <<< $bgcolor)"

        fgrgb="$(cut -d ';' -f1-3 <<< $fgcolor)"
        fga="$(cut -d ';' -f4 <<< $fgcolor)"

        if [ "$alpha_method" = duplicate ]; then
            [ "$bga" = 0 ] && [ "$fga" = 0 ] && echo -ne "\e[0m "
            [ "$bga" = 0 ] && [ "$fga" != 0 ] && echo -ne "\e[0m\e[38;2;${fgrgb}m▄"
            [ "$bga" != 0 ] && [ "$fga" = 0 ] && echo -ne "\e[38;2;${bgrgb}m\e[48;2;${bgrgb}m▄"
        elif [ "$alpha_method" = skip ]; then
            [ "$bga" = 0 ] && [ "$fga" = 0 ] && echo -ne "\e[0m "
            [ "$bga" = 0 ] && [ "$fga" != 0 ] && echo -ne "\e[0m\e[38;2;${fgrgb}m▄"
            [ "$bga" != 0 ] && [ "$fga" = 0 ] && echo -ne "\e[0m "
        else
            [ "$bga" = 0 ] && [ "$fga" = 0 ] && echo -ne "\e[38;2;${alpha_method}m\e[48;2;${alpha_method}m▄"
            [ "$bga" = 0 ] && [ "$fga" != 0 ] && echo -ne "\e[38;2;${fgrgb}m\e[48;2;${alpha_method}m▄"
            [ "$bga" != 0 ] && [ "$fga" = 0 ] && echo -ne "\e[38;2;${alpha_method}m\e[48;2;${bgrgb}m▄"
        fi
        [ "$bga" != 0 ] && [ "$fga" != 0 ] && echo -ne "\e[38;2;${fgrgb}m\e[48;2;${bgrgb}m▄"
    done
    echo -e "\e[0m"
done

echo -ne "\e[?25h"
