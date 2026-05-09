# ────────────────────────────────────────────────────────────────────── << A T L A S >> ────────────────────────────────────────────────────────────────────── #

atlas() {

#  ┌── configuration ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐  #

    {

        local default_commands=irfosudc
        local update_interval=3
        local cache_limit=5

        local save_path="/tmp/atlas"

        local log_path="/var/log/pacman.log"
        local flatpak_path="/var/lib/flatpak"
        local cache_path="/var/cache/pacman/pkg"

    }

#  ├── execution ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤  #

    (( executing )) || {

        local executing=1 cmds=$1

        local hide=$'\e[?25l' show=$'\e[?25h' clear=$'\e[K' origin=$'\e[7G'
        local bold=$'\e[1m' dim=$'\e[2m' red=$'\e[31m' reset=$'\e[m'
        local n=$'\n' r=$'\r' s=$'\uA0'

        local children csize flatpaks i indent mods ops opt orphans pfx pkg pulse root scanned
        local -A delta info modified null rlineage

        echo
        atlas .resolve
        atlas .dispatch
        echo

    }

#  ├── cortex ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤  #

    [[ $1 = .resolve ]] && {

        [[ $(command -v pacman) ]] || {
            echo "you're not even using arch silly$n"
            atlas .suicide
        }

        mods=( q y i )
        ops=( r f o s u d c x )

        [[ $cmds =~ \? ]] && atlas .error s
        [[ $cmds =~ [^-${mods[@]}${ops[@]}] ]] && atlas .error c
        [[ ${cmds//[-${mods[@]}]} ]] || cmds+=$default_commands

    }

    [[ $1 = .dispatch ]] && {

        atlas .signal 1

        atlas .scan "$cmds"
        for i in $(fold -w1 <<< "$cmds")
        do
            atlas .scan "$i"
            atlas .$i
        done

        atlas .signal 0

    }

#  ├── operations ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤  #

    [[ $1 = .r ]] && {

        echo "${bold}root (${#root[@]})$reset"
        atlas .render root rlineage

    }

    [[ $1 = .f ]] && {

        [[ $flatpaks ]] && {
            echo "${bold}flatpaks (${#flatpaks[@]})$reset"
            atlas .render flatpaks null
        :;} || {
            [[ $cmds =~ i ]] || echo "${dim}flatpaks: nil$reset$n"
        }

    }

    [[ $1 = .o ]] && {

        [[ $orphans ]] && {
            echo "$red${bold}orphans (${#orphans[@]})$reset"
            atlas .render orphans null "$red"
        :;} || {
            [[ $cmds =~ i ]] || echo "${dim}orphans: nil$reset$n"
        }

    }

    [[ $1 = .s ]] && {

        {
            mkdir -p "$save_path"

            printf "%s$n" "${root[@]}" > "$save_path/root"
            printf "%s$n" "${flatpaks[@]}" > "$save_path/flatpaks"
            printf "%s$n" "${orphans[@]}" > "$save_path/orphans"
        } 2>/dev/null

        [[ -w $save_path ]] && {
            [[ $cmds =~ i ]] || echo "${dim}saved$reset$n"
        :;} || echo "${red}i couldn't save for some reason, check your save path$reset$n"

    }

    [[ $1 = .u ]] && {

        [[ $cmds =~ i && $(tac "$log_path" 2>/dev/null | grep -m1 "upgraded") > [$(date -d -${update_interval}days +%F) ]] || {
            atlas .await 2 "scan for updates? (y/${bold}n$reset) "

            [[ ${REPLY,,} = y ]] && {
                [[ $(command -v yay) ]] && {
                    yay
                :;} || {
                    [[ $(command -v paru) ]] && {
                        paru
                    :;} || sudo pacman -Syu
                }

                echo

                [[ $(command -v flatpak) ]] && {
                    flatpak update && flatpak remove --unused
                    echo
                }
            }
        }

    }

    [[ $1 = .d ]] && {

        [[ -d $save_path ]] && {
            for i in root flatpaks orphans
            do
                local -n xarr=$i

                {
                    delta[${i}0]=$(grep -vxf <(printf "%s$n" "${xarr[@]}") "$save_path/$i")
                    delta[${i}1]=$(grep -vxf "$save_path/$i" <(printf "%s$n" "${xarr[@]}"))
                } 2>/dev/null

                [[ ${delta[${i}0]}${delta[${i}1]} ]] && {
                    echo "$bold▼ $i difference$reset"
                    [[ ${delta[${i}0]} ]] && echo "$red${delta[${i}0]}$reset"
                    [[ ${delta[${i}1]} ]] && echo "${delta[${i}1]}"
                    echo
                :;} || {
                    [[ $cmds =~ i ]] || echo "$dim$i difference: nil$reset$n"
                }
            done
        :;} || {
            echo "${red}i couldn't find a save file$reset$n"
        }

    }

    [[ $1 = .c ]] && {

        [[ $orphans ]] && {
            atlas .await 2 "remove orphans? (y/${bold}n$reset) "

            [[ ${REPLY,,} = y ]] && {
                sudo pacman -Rns "${orphans[@]}"
                echo
            }
        :;} || {
            [[ $cmds =~ i ]] || echo "${dim}no orphans to remove$reset$n"
        }

        csize=$(du -sh "$cache_path" 2>/dev/null | cut -f1)

        {
            [[ $csize ]] && (( $(numfmt --from=iec "$csize") > cache_limit<<30 )) || [[ ! $cmds =~ i ]]
        } && {
            [[ $csize ]] || csize="?"

            atlas .await 2 "clear package cache [$csize]? (y/${bold}n$reset) "

            [[ ${REPLY,,} = y ]] && {
                yes | sudo pacman -Scc &>/dev/null
                csize=$(du -sh "$cache_path" 2>/dev/null | cut -f1)
                [[ $csize ]] && echo "${dim}new cache size: $csize$reset$n"
            }
        }

    }

    [[ $1 = .x ]] && {

        atlas .await 2 "are you sure? (y/${bold}n$reset) "

        [[ ${REPLY,,} = y ]] && atlas .suicide

    }

#  ├── engine ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤  #

    [[ $1 = .signal ]] && {

        local stage=$2

        (( stage )) || {
            atlas .await 1
            trap - 2 15
        }

        (( stage )) && {
            atlas .await 0
            trap '
                atlas .pulse
                atlas .signal
                echo "$r$red> atlas: terminated ⚠$reset$clear"
                kill -2 $$
            ' 2 15
        }

    }

    [[ $1 = .scan ]] && {

        local scmds=$2

        [[ $scmds =~ r && ! $cmds =~ q ]] && scmds+=R
        [[ $scmds =~ s ]] && scmds+=rfo
        [[ $scmds =~ d && -f $save_path/root ]] && scmds+=rfo
        [[ $scmds =~ c ]] && scmds+=o

        {
            modified[l1]=$(stat -c %Y "$log_path")
            modified[f1]=$(stat -c %Y "$flatpak_path")
        } 2>/dev/null

        [[ ${modified[l0]} && ${modified[l0]} = ${modified[l1]} ]] || {
            scanned=${scanned//[roR]}
            modified[l0]=${modified[l1]}
        }

        [[ ${modified[f0]} && ${modified[f0]} = ${modified[f1]} ]] || {
            scanned=${scanned//f}
            modified[f0]=${modified[f1]}
        }

        scmds=${scmds//[$scanned]}
        scanned+=$scmds

        atlas .pulse 1

        {
            [[ $scmds =~ [ro] ]] && {
                echo -n "$origin${dim}atlas: scanning orphans…$reset"
                orphans=( $(pacman -Qqtd) )
            }

            [[ $scmds =~ r ]] && {
                echo -n "$origin${dim}atlas: scanning root…$reset$clear"
                root=( $(grep -vxf <(printf "%s$n" "${orphans[@]}") <(pacman -Qqtt)) )
            }

            [[ $scmds =~ f ]] && {
                echo -n "$origin${dim}atlas: scanning flatpaks…$reset$clear"
                mapfile -t flatpaks < <(flatpak list --app --columns=name)
            }

            atlas .extract "$scmds"
        } 2>/dev/null

        atlas .pulse 0

    }

    [[ $1 = .pulse ]] && {

        local stage=$2

        (( stage )) || {
            echo -n "$r$clear"
            kill $pulse
            wait $pulse
        } 2>/dev/null

        (( stage )) && {
            while :
            do
                for f in '/' '—' '\' '|'
                do
                    echo -n "$r$bold( $f )$reset"
                    sleep 0.05
                done
            done &pulse=$!
        } 2>/dev/null

    }

    [[ $1 = .extract ]] && {

        local scmds=$2

        [[ $scmds =~ R ]] && {
            rlineage=()

            while read pkg opt
            do [[ " ${root[@]} " =~ " $opt " ]] && rlineage[$pkg]+=\ $opt
            done < <(LC_ALL=C pacman -Qi "${root[@]}" | awk '
                proceed && /^ / {
                    gsub(/^ +|:.*/, "")
                    print pkg, $0
                    next
                }

                proceed = 0

                /^Name/ { pkg = $NF }

                /^Optional Deps/ {
                    gsub(/^Optional Deps *: *|:.*/, "")
                    print pkg, $0
                    proceed = 1
                }
            ')
        }

    }

    [[ $1 = .render ]] && {

        local xarrn=$2 arrn=$3 attr=$4 depth=$5

        local -n xarr=$xarrn arr=$arrn
        local x=1 xx=${#xarr[@]}

        for i in "${xarr[@]}"
        do
            [[ $cmds =~ q ]] || {
                [[ $depth ]] || {
                    [[ " ${arr[@]} " =~ " $i " ]] && {
                        ((xx--))
                        continue
                    }

                    echo "$attr│"
                }

                (( x == xx )) && {
                    pfx="└─ "
                    indent="   "
                :;} || {
                    pfx="├─ "
                    indent="│  "
                }

                ((x++))
            }

            echo "$attr$depth$attr$pfx$i$reset"

            children=( ${arr[$i]} )
            atlas .render children "$arrn" "$attr" "$depth$indent$dim"
        done

        [[ $depth ]] || echo

    }

    [[ $1 = .await ]] && {

        local stage=$2 prompt=$3

        (( stage )) || {
            stty -echo
            echo -n "$hide"
        }

        (( stage )) && {
            echo -n "$show"
            stty echo </dev/tty
        }

        (( stage > 1 )) && {
            [[ $cmds =~ y ]] && {
                REPLY=y
                atlas .await 0
            :;} || {
                while read -t 0
                do read
                done

                echo -n "$prompt"
                read
                echo
                atlas .await 0
            }
        }

    }

    [[ $1 = .error ]] && {

        local mode=$2

        [[ $mode = c ]] && echo "${red}not sure what you mean, run 'atlas ?' for syntax$reset$n"

        [[ $mode = s ]] && {
            echo "${bold}▼ atlas syntax$reset$n"

            echo "${bold}mods (${#mods[@]})$reset"
            info[q]="quiet${s}output"
            info[y]="auto${s}confirm"
            info[i]="intelligent${s}mode"
            atlas .render mods info

            echo "${bold}ops (${#ops[@]})$reset"
            info[r]="view${s}root"
            info[f]="view${s}flatpaks"
            info[o]="view${s}orphans"
            info[s]="save${s}system${s}state"
            info[u]="upgrade${s}system"
            info[d]="view${s}difference"
            info[c]="system${s}cleanup"
            info[x]="erase${s}atlas"
            atlas .render ops info
        }

        kill -2 $$

    }

    [[ $1 = .suicide ]] && {

        {
            rm -r "$save_path"
            grep -q ' //  ▲  \\\\ ' "$BASH_SOURCE" && sed -i '/ << A T L A S >> /, \| //  ▲  \\\\ | d' "$BASH_SOURCE"
        } 2>/dev/null

        grep -q "atlas()" "$BASH_SOURCE" && {
            echo "${red}i couldn't remove atlas from $BASH_SOURCE, do it yourself$reset$n"
        :;} || echo "${dim}bye$reset$n"

        atlas .signal 0
        unset -f atlas
        kill -2 $$

    }

#  └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘  #

}

# ───────────────────────────────────────────────────────────────────────── //  ▲  \\ ───────────────────────────────────────────────────────────────────────── #
