# ────────────────────────────────────────────────────────────────────── << A T L A S >> ────────────────────────────────────────────────────────────────────── #

atlas() {

#  ┌── configuration ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐

    {

        local default_commands=irfosudc
        local save_path="/tmp/atlas"
        local update_interval=6
        local cache_limit=6
        local delay_decimal=6

    }

#  ├── execution ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    (( executing == 66 )) || {

        local executing=66 cmds=$1

        local hide=$'\e[?25l' show=$'\e[?25h' clear=$'\e[K' origin=$'\e[7G'
        local bold=$'\e[1m' dim=$'\e[2m' red=$'\e[31m' reset=$'\e[m'
        local n=$'\n' r=$'\r'

        local auth cache children flatpaks log orphans pulse root scanned
        local -A modified nullarr rlineage

        echo
        atlas .resolve
        atlas .dispatch
        echo

    }

#  ├── cortex ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    [[ $1 = .resolve ]] && {

        pacman -Q base &>/dev/null || {
            echo "you're not even using arch silly$n"
            atlas .suicide
        }

        [[ $cmds =~ \? ]] && atlas .error s
        [[ $cmds =~ [^-qyirfosudcX] ]] && atlas .error c
        [[ ${cmds//[-qyi]} ]] || cmds+=$default_commands

        log=$(pacman-conf LogFile)
        cache=$(pacman-conf CacheDir)
        (( EUID )) && auth=sudo

    }

    [[ $1 = .dispatch ]] && {

        local i

        atlas .signal 1

        atlas .scan $cmds
        for i in $(fold -w1 <<< $cmds)
        do
            atlas .scan $i
            atlas .$i
        done

        atlas .signal 0

    }

#  ├── operations ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    [[ $1 = .r ]] && {

        echo "${bold}root (${#root[@]})$reset"
        atlas .render root rlineage

    }

    [[ $1 = .f ]] && {

        [[ $flatpaks ]] && {
            echo "${bold}flatpaks (${#flatpaks[@]})$reset"
            atlas .render flatpaks nullarr
        :;} || {
            [[ $cmds =~ i ]] || echo "${dim}flatpaks: nil$reset$n"
        }

    }

    [[ $1 = .o ]] && {

        [[ $orphans ]] && {
            echo "$red${bold}orphans (${#orphans[@]})$reset"
            atlas .render orphans nullarr "$red"
        :;} || {
            [[ $cmds =~ i ]] || echo "${dim}orphans: nil$reset$n"
        }

    }

    [[ $1 = .s ]] && {

        mkdir -p "$save_path" && {
            printf "%s$n" ${root[@]} > "$save_path/root"
            printf "%s$n" "${flatpaks[@]}" > "$save_path/flatpaks"
            printf "%s$n" ${orphans[@]} > "$save_path/orphans"

            [[ $cmds =~ i ]] || echo "${dim}saved$reset$n"
        :;} || echo "${red}huh…? use a proper save path$reset$n"

    }

    [[ $1 = .u ]] && {

        [[ $cmds =~ i && $(tac "$log" | grep -m1 upgraded) > [$(date -d -${update_interval}days +%F)U ]] || {
            atlas .await 2 "scan for updates? {y/${bold}n$reset} "

            [[ ${REPLY,} = y ]] && {
                [[ $(command -v yay) ]] && {
                    yay
                :;} || {
                    [[ $(command -v paru) ]] && {
                        paru
                    :;} || $auth pacman -Syu
                }

                echo

                [[ $(command -v flatpak) ]] && {
                    flatpak update && flatpak remove --unused
                    echo
                }
            }

            atlas .await 0
        }

    }

    [[ $1 = .d ]] && {

        local i
        local -A delta

        [[ -d $save_path ]] && {
            for i in root flatpaks orphans
            do
                local -n xarr=$i

                {
                    delta[${i}0]=$(grep -vxFf <(printf "%s$n" "${xarr[@]}") "$save_path/$i")
                    delta[${i}1]=$(grep -vxFf "$save_path/$i" <(printf "%s$n" "${xarr[@]}"))
                } 2>/dev/null

                [[ ${delta[${i}0]}${delta[${i}1]} ]] && {
                    echo "$bold▼ $i difference$reset$n"

                    [[ ${delta[${i}0]} ]] && echo "$dim${delta[${i}0]}$reset"

                    [[ ${delta[${i}1]} ]] && {
                        [[ $i = orphans ]] && echo -n "$red"
                        echo "${delta[${i}1]}$reset"
                    }

                    echo
                }
            done

            [[ $cmds =~ i || ${delta[@]} =~ [^\ ] ]] || echo "${dim}difference: nil$reset$n"
        :;} || {
            echo "${red}you forgot to save…$reset$n"
        }

    }

    [[ $1 = .c ]] && {

        [[ $orphans ]] && {
            atlas .await 2 "remove orphans? (${#orphans[@]}) {y/${bold}n$reset} "

            [[ ${REPLY,} = y ]] && {
                $auth pacman -Rns ${orphans[@]}
                echo
            }

            atlas .await 0
        :;} || {
            [[ $cmds =~ i ]] || echo "${dim}no orphans to remove$reset$n"
        }

        local csize=$(du -sh "$cache" 2>/dev/null | cut -f1)

        (( $(numfmt --from=iec "$csize") > cache_limit<<30 )) || [[ ! $cmds =~ i ]] && {
            atlas .await 2 "clear cache ($csize)? {y/${bold}n$reset} "

            [[ ${REPLY,} = y ]] && {
                yes | $auth pacman -Scc &>/dev/null
                csize=$(du -sh "$cache" 2>/dev/null | cut -f1)
                echo "${dim}new cache size: $csize$reset$n"
            }

            atlas .await 0
        }

    }

    [[ $1 = .X ]] && {

        atlas .await 2 "are you sure? {y/${bold}n$reset} "

        [[ ${REPLY,} = y ]] && atlas .suicide || echo "i'm flattered$n"

        atlas .await 0

    }

#  ├── engine ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    [[ $1 = .signal ]] && {

        local stage=$2

        (( stage )) || {
            atlas .await 1
            trap - 2 15
        }

        (( stage )) && {
            atlas .await 0
            trap '
                atlas .pulse 0
                atlas .signal 0
                echo "$r$red⚠︎ atlas terminated$reset$clear$n"
                kill -2 $$
            ' 2 15
        }

    }

    [[ $1 = .scan ]] && {

        local scmds=$2

        [[ $scmds =~ r && ! $cmds =~ q ]] && scmds+=R
        [[ $scmds =~ s || ($scmds =~ d && -d $save_path) ]] && scmds+=rfo
        [[ $scmds =~ c ]] && scmds+=o

        modified[l1]=$(stat -c %Y "$log")
        modified[f1]=$(stat -c %Y /var/lib/flatpak 2>/dev/null)

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
                read -t "0.$delay_decimal"
            }

            [[ $scmds =~ r ]] && {
                echo -n "$origin${dim}atlas: scanning root…$reset$clear"
                root=( $(grep -vxFf <(printf "%s$n" ${orphans[@]}) <(pacman -Qqtt)) )
                read -t "0.$delay_decimal"
            }

            [[ $scmds =~ f ]] && {
                echo -n "$origin${dim}atlas: scanning flatpaks…$reset$clear"
                mapfile -t flatpaks < <(flatpak list --app --columns=name)
                read -t "0.$delay_decimal"
            }

            atlas .extract $scmds
        } 2>/dev/null

        atlas .pulse 0

    }

    [[ $1 = .pulse ]] && {

        local stage=$2

        (( stage )) || {
            echo -n "$r$clear"
            kill $pulse
            wait "$pulse"
        } 2>/dev/null

        (( stage )) && {
            while :
            do
                for f in '/' '—' '\' '|'
                do
                    echo -n "$r$bold( $f )$reset"
                    sleep "0.0$delay_decimal"
                done
            done &pulse=$!
        } 2>/dev/null

    }

    [[ $1 = .extract ]] && {

        local scmds=$2 pkg opt

        [[ $scmds =~ R ]] && {
            rlineage=()

            while read pkg opt
            do [[ " ${root[@]} " =~ " $opt " ]] && rlineage[$pkg]+=" $opt "
            done < <(LC_ALL=C pacman -Qi ${root[@]} | awk '
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

            atlas .cycle "${!rlineage[*]}" rlineage
        }

    }

    [[ $1 = .cycle ]] && {

        local list=$2 arrn=$3 last=$4 recursed=$5 i
        local -n arr=$arrn

        for i in $list
        do
            [[ $recursed =~ " $i " ]] && {
                arr[$last]=${arr[$last]/ $i }
                continue
            }

            atlas .cycle "${arr[$i]}" $arrn $i " $recursed $i "
        done

    }

    [[ $1 = .render ]] && {

        local xarrn=$2 arrn=$3 attr=$4 depth=$5 i x
        local -n xarr=$xarrn arr=$arrn
        local xx=${#xarr[@]}

        for i in "${xarr[@]}"
        do
            [[ ! $depth && ${arr[@]} =~ " $i " ]] && continue

            [[ $cmds =~ q ]] || {
                [[ $depth ]] || {
                    (( x )) || xx=$(grep -cvxFf <(printf "%s$n" ${arr[@]}) <(printf "%s$n" "${xarr[@]}"))
                    echo "$attr│"
                }

                (( ++x == xx )) && local pfx="└─ " indent="   " || local pfx="├─ " indent="│  "

                read -t "0.00$delay_decimal"
            }

            echo "$attr$depth$pfx$i$reset"

            children=( ${arr[$i]} )
            atlas .render children $arrn "$attr" "$depth$indent$dim"
        done

        [[ $depth ]] || echo

    }

    [[ $1 = .await ]] && {

        local stage=$2 prompt=$3

        (( stage )) || {
            stty -echo
            echo -n "$hide"
        } 2>/dev/null

        (( stage )) && {
            echo -n "$show"
            stty echo </dev/tty
        } 2>/dev/null

        (( stage > 1 )) && {
            [[ $cmds =~ y ]] && REPLY=y || {
                while read -t 0
                do read
                done

                echo -n "$prompt"
                read -s -n 1
                echo -n "$r$clear"
            }
        }

    }

    [[ $1 = .error ]] && {

        local mode=$2

        [[ $mode = c ]] && echo "${red}not sure what you mean, run 'atlas ?' for syntax$reset"

        [[ $mode = s ]] && {
            echo "$bold▼ atlas syntax$reset$n"
            echo "  ┌── modifiers ──────────────┐"
            echo "  │ q  ·  quiet output        │"
            echo "  │ y  ·  auto confirm        │"
            echo "  │ i  ·  intelligent mode    │"
            echo "  └───────────────────────────┘$n"
            echo "  ┌── operations ─────────────┐"
            echo "  │ r  ·  view root           │"
            echo "  │ f  ·  view flatpaks       │"
            echo "  │ o  ·  view orphans        │"
            echo "  │ s  ·  save system state   │"
            echo "  │ u  ·  upgrade system      │"
            echo "  │ d  ·  view difference     │"
            echo "  │ c  ·  system cleanup      │"
            echo "  │ X  ·  erase atlas         │"
            echo "  └───────────────────────────┘"
        }

        echo
        kill -2 $$

    }

    [[ $1 = .suicide ]] && {

        rm -rf "$save_path"

        grep -q ' //  ▲  \\\\ ' "$BASH_SOURCE" && sed -i '\L << A T \L A S >> L, \| //  ▲  \\\\ | d' "$BASH_SOURCE"
        grep -q "atlas()" "$BASH_SOURCE" && echo "${red}feeling a little clingy, delete the source code yourself$reset" || echo "${dim}…bye$reset"

        atlas .signal 0
        unset -f atlas

        echo
        kill -2 $$

    }

#  └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

}

# ───────────────────────────────────────────────────────────────────────── //  ▲  \\ ───────────────────────────────────────────────────────────────────────── #
