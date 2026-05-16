# ══════════════════════════════════════════════════════════════════════ << A T L A S >> ══════════════════════════════════════════════════════════════════════ #

atlas() {

#  ╭── configuration ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮

    {

        local save_path="/tmp/atlas"
        local default_commands=irfosudc
        local upgrade_interval=6
        local cache_limit=6
        local delay_decimal=6

    }

#  ├── execution ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    (( executing - 66 )) && {

        local executing=66 cmds=$1 auth=$(type -P sudo || type -P doas)

        local hide=$'\e[?25l' show=$'\e[?25h' clear=$'\e[K' origin=$'\e[3G'
        local bold=$'\e[1m' dim=$'\e[2m' red=$'\e[31m' reset=$'\e[m'
        local n=$'\n' r=$'\r'

        local apps children flatpaks log orphans pulse root scanned
        local -A modified null lineage

        echo
        atlas :resolve
        atlas :dispatch
        echo

    }

#  ├── cortex ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    [[ $1 = :resolve ]] && {

        pacman -Q base &>/dev/null || {
            echo "you're not even using arch silly$n"
            atlas .suicide
        }

        [[ $cmds =~ \? ]] && atlas .error s
        cmds=${cmds//-}
        [[ $cmds =~ [^qyirfosudcX] ]] && atlas .error c
        [[ ${cmds//[qyi]} ]] || cmds+=$default_commands

        log=$(pacman-conf LogFile)

    }

    [[ $1 = :dispatch ]] && {

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
        atlas .render root lineage

    }

    [[ $1 = .f ]] && {

        [[ $flatpaks ]] && {
            echo "${bold}flatpaks (${#flatpaks[@]})$reset"
            atlas .render flatpaks null
        :;} || [[ $cmds =~ i ]] || echo "$dim► flatpaks: nil$reset$n"

    }

    [[ $1 = .o ]] && {

        [[ $orphans ]] && {
            echo "$red${bold}orphans (${#orphans[@]})$reset"
            atlas .render orphans null "$red"
        :;} || [[ $cmds =~ i ]] || echo "$dim► orphans: nil$reset$n"

    }

    [[ $1 = .s ]] && {

        mkdir -p "$save_path"

        [[ -w $save_path ]] && {
            printf "%s$n" ${root[@]} > "$save_path/root"
            printf "%s$n" ${apps[@]} > "$save_path/apps"
            printf "%s$n" ${orphans[@]} > "$save_path/orphans"

            [[ $cmds =~ i ]] || echo "$dim► saved$reset$n"
        :;} || echo "$red⚠︎ huh…? use a proper save path$reset$n"

    }

    [[ $1 = .u ]] && {

        [[ $cmds =~ i && $(tac "$log" | grep -m1 upgraded) > [$(date -d -${upgrade_interval}days +%F)U ]] || {
            atlas .await 2 "◄ scan for updates? {y/${bold}n$reset} "

            [[ ${REPLY,} = y ]] && {
                $(type -P yay || type -P paru || echo "$auth pacman") -Syu
                echo

                [[ $(type -P flatpak) ]] && {
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

        [[ -r $save_path ]] && {
            for i in root apps orphans
            do
                local -n xarr=$i

                {
                    delta[${i}0]=$(grep -vxFf <(printf "%s$n" ${xarr[@]}) "$save_path/$i")
                    delta[${i}1]=$(grep -vxFf "$save_path/$i" <(printf "%s$n" ${xarr[@]}))
                } 2>/dev/null

                [[ ${delta[${i}0]}${delta[${i}1]} ]] && {
                    echo "$bold▼ $i difference$reset$n"

                    [[ ${delta[${i}0]} ]] && printf "  $dim◎ %s$reset$n" ${delta[${i}0]}

                    [[ ${delta[${i}1]} ]] && {
                        [[ $i = orphans ]] && echo -n "$red"
                        printf "  ◉ %s$n" ${delta[${i}1]}
                        echo -n "$reset"
                    }

                    echo
                }
            done

            [[ $cmds =~ i || ${delta[@]} =~ [^\ ] ]] || echo "$dim► difference: nil$reset$n"
        :;} || [[ $cmds =~ s ]] || echo "$red⚠︎ you forgot to save…$reset$n"

    }

    [[ $1 = .c ]] && {

        local cache=$(pacman-conf CacheDir)
        local csize=$(du -sh "$cache" 2>/dev/null | cut -f1)

        [[ $orphans ]] && {
            atlas .await 2 "◄ remove orphans (${#orphans[@]})? {y/${bold}n$reset} "

            [[ ${REPLY,} = y ]] && {
                $auth pacman -Rns ${orphans[@]}
                echo
            }

            atlas .await 0
        :;} || [[ $cmds =~ i ]] || echo "$dim► no orphans to remove$reset$n"

        [[ $csize != 0 ]] && {
            [[ $cmds =~ i ]] && (( cache_limit<<30 > $(numfmt --from=iec "$csize") )) || {
                atlas .await 2 "◄ clear cache ($csize)? {y/${bold}n$reset} "

                [[ ${REPLY,} = y ]] && {
                    yes | $auth pacman -Scc &>/dev/null
                    echo "$dim► updated cache size: $(du -sh "$cache" 2>/dev/null | cut -f1)$reset$n"
                }

                atlas .await 0
            }
        :;} || [[ $cmds =~ i ]] || echo "$dim► cache is empty$reset$n"

    }

    [[ $1 = .X ]] && {

        atlas .await 2 "$red☢︎ are you sure? {y/${bold}n$reset$red}$reset "

        [[ ${REPLY,} = y ]] && atlas .suicide || echo "$dim► i'm flattered$reset$n"

        atlas .await 0

    }

#  ├── engine ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    [[ $1 = .signal ]] && {

        local stage=$2

        (( stage )) && {
            atlas .await 0
            trap '
                atlas .pulse 0
                atlas .signal 0
                echo "$r$red⚠︎ atlas terminated$reset$clear$n"
                kill -2 $$
            ' 2 15
        :;} || {
            atlas .await 1
            trap - 2 15
        }

    }

    [[ $1 = .scan ]] && {

        local scmds=$2

        [[ $scmds =~ r && ! $cmds =~ q ]] && scmds+=l
        [[ $scmds =~ d && -r $save_path || $scmds =~ s ]] && scmds+=rao
        scmds=${scmds//c/o}

        modified[l1]=$(stat -c %Y "$log")
        modified[f1]=$(stat -c %Y /var/lib/flatpak 2>/dev/null)

        [[ ${modified[l0]} = ${modified[l1]} ]] || {
            scanned=${scanned//[rlo]}
            modified[l0]=${modified[l1]}
        }

        [[ ${modified[f0]} = ${modified[f1]} ]] || {
            scanned=${scanned//[fa]}
            modified[f0]=${modified[f1]}
        }

        scmds=${scmds//[$scanned]}
        scanned+=$scmds

        atlas .pulse 1

        {
            [[ $scmds =~ [ro] ]] && {
                echo -n "$origin${dim}atlas: scanning orphans…$reset"
                orphans=( $(pacman -Qqtd) )
                read -t 0.$delay_decimal
            }

            [[ $scmds =~ r ]] && {
                echo -n "$origin${dim}atlas: scanning root…$reset$clear"
                root=( $(grep -vxFf <(printf "%s$n" ${orphans[@]}) <(pacman -Qqtt)) )
                read -t 0.$delay_decimal
            }

            [[ $scmds =~ f ]] && {
                echo -n "$origin${dim}atlas: scanning flatpaks…$reset$clear"
                mapfile -t flatpaks < <(flatpak list --app --columns=name)
                read -t 0.$delay_decimal
            }

            [[ $scmds =~ a ]] && {
                echo -n "$origin${dim}atlas: scanning app ids…$reset$clear"
                apps=( $(flatpak list --app --columns=app) )
                read -t 0.$delay_decimal
            }

            atlas .extract $scmds
        } 2>/dev/null

        atlas .pulse 0

    }

    [[ $1 = .pulse ]] && {

        local stage=$2

        (( stage )) && {
            while :
            do
                for f in ◜ ◝ ◞ ◟ ○ ◎ ◉ ● ◉ ◎ ○ ○
                do
                    echo -n "$r$bold$f$reset"
                    sleep 0.0$delay_decimal
                done
            done &pulse=$!
        :;} 2>/dev/null || {
            echo -n "$r$clear"
            kill $pulse
            wait "$pulse"
        } 2>/dev/null

    }

    [[ $1 = .extract ]] && {

        local scmds=$2 pkg opt

        [[ $scmds =~ l ]] && {
            lineage=()

            while read pkg opt
            do [[ " ${root[@]} " =~ " $opt " ]] && lineage[$pkg]+=" $opt "
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

            atlas .cycle "${!lineage[*]}" lineage
        }

    }

    [[ $1 = .cycle ]] && {

        local list=$2 arrn=$3 last=$4 recursed=$5 i
        local -n arr=$arrn

        for i in $list
        do [[ $recursed =~ " $i " ]] && arr[$last]=${arr[$last]/ $i } || atlas .cycle "${arr[$i]}" $arrn $i " $recursed $i "
        done

    }

    [[ $1 = .render ]] && {

        local xarrn=$2 arrn=$3 attr=$4 depth=$5 i x
        local -n xarr=$xarrn arr=$arrn

        for i in "${xarr[@]}"
        do
            [[ ! $depth && ${arr[@]} =~ " $i " ]] || {
                [[ $cmds =~ q ]] || {
                    [[ $depth ]] || echo "$attr│"
                    (( x )) || local xx=$([[ $depth ]] && echo ${#xarr[@]} || grep -cvxFf <(printf "%s$n" ${arr[@]}) <(printf "%s$n" "${xarr[@]}"))
                    (( ++x == xx )) && local pfx="╰─ " indent="   " || local pfx="├─ " indent="│  "
                }

                echo "$attr$depth$pfx$i$reset"
                read -t 0.00$delay_decimal

                children=( ${arr[$i]} )
                atlas .render children $arrn "$attr" "$depth$indent$dim"
            }
        done

        [[ $depth ]] || echo

    }

    [[ $1 = .await ]] && {

        local stage=$2 prompt=$3

        (( stage )) && {
            echo -n "$show"
            stty echo </dev/tty
        :;} 2>/dev/null || {
            stty -echo
            echo -n "$hide"
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

        [[ $mode = c ]] && echo "$red⚠︎ not sure what you mean, run 'atlas ?' for syntax$reset"

        [[ $mode = s ]] && {
            echo "$bold▼ atlas syntax$reset$n"
            echo "  ╭── modifiers ──────────────╮"
            echo "  │ q  ·  quiet output        │"
            echo "  │ y  ·  auto confirm        │"
            echo "  │ i  ·  intelligent mode    │"
            echo "  ╰───────────────────────────╯$n"
            echo "  ╭── operations ─────────────╮"
            echo "  │ r  ·  view root           │"
            echo "  │ f  ·  view flatpaks       │"
            echo "  │ o  ·  view orphans        │"
            echo "  │ s  ·  save system state   │"
            echo "  │ u  ·  upgrade system      │"
            echo "  │ d  ·  view difference     │"
            echo "  │ c  ·  system cleanup      │"
            echo "  │ X  ·  erase atlas         │"
            echo "  ╰───────────────────────────╯"
        }

        echo
        kill -2 $$

    }

    [[ $1 = .suicide ]] && {

        rm -rf "$save_path"

        grep -q ' //  ▲  \\\\ ' "$BASH_SOURCE" && sed -i '\L << A T \L A S >> L, \| //  ▲  \\\\ | d' "$BASH_SOURCE"
        grep -q "atlas()" "$BASH_SOURCE" && echo "$red⚠︎ feeling a little clingy, delete the source code yourself$reset" || echo "$dim…bye$reset"

        atlas .signal 0
        unset -f atlas

        echo
        kill -2 $$

    }

#  ╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯

}

# ═════════════════════════════════════════════════════════════════════════ //  ▲  \\ ═════════════════════════════════════════════════════════════════════════ #
