# ┄┄───═════════════════════════════════════════════════════════════════ << A T L A S >> ═════════════════════════════════════════════════════════════════───┄┄ #

atlas() {

#  ╭── configuration ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮

    {

        local save_path="/tmp/atlas"
        local default_commands=iraosudc
        local upgrade_interval=6
        local cache_limit=6
        local fake_delay=6

    }

#  ├── execution ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    (( executing - 66 )) && {

        local cmds=$1 executing=66
        local mods="qyi" ops="raosudcX" auth=$(type -P sudo || type -P doas)
        local bold=$'\e[1m' dim=$'\e[2m' red=$'\e[31m' reset=$'\e[m' hide=$'\e[?25l' show=$'\e[?25h' clear=$'\e[K' n=$'\n' r=$'\r'

        local log scanned orphans root appnames apps
        local -A modified async lineage null

        echo
        atlas :resolve
        atlas :dispatch
        echo

    }

#  ├── cortex ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    [[ $1 = :resolve ]] && {

        pacman -Q base &>/dev/null || {
            atlas .echo a "you're not even using arch silly"
            atlas .suicide
        }

        [[ $cmds =~ \? ]] && atlas .error s
        cmds=${cmds//-}
        [[ ${cmds//[$mods$ops]} ]] && atlas .error c
        [[ ${cmds//[$mods]} ]] || cmds+=$default_commands

        log=$(pacman-conf LogFile)

    }

    [[ $1 = :dispatch ]] && {

        local i

        atlas .signal 1

        atlas .scan ${cmds//[$mods]}
        for i in $(fold -w1 <<< ${cmds//[$mods]})
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

    [[ $1 = .a ]] && {

        [[ $appnames ]] && {
            echo "${bold}apps (${#appnames[@]})$reset"
            atlas .render appnames null
        :;} || [[ $cmds =~ i ]] || atlas .echo a "apps: nil"

    }

    [[ $1 = .o ]] && {

        [[ $orphans ]] && {
            echo "$red${bold}orphans (${#orphans[@]})$reset"
            atlas .render orphans null "$red"
        :;} || [[ $cmds =~ i ]] || atlas .echo a "orphans: nil"

    }

    [[ $1 = .s ]] && {

        [[ -w $save_path ]] && {
            printf "%s$n" ${root[@]} > "$save_path/root"
            printf "%s$n" ${apps[@]} > "$save_path/apps"
            printf "%s$n" ${orphans[@]} > "$save_path/orphans"

            [[ $cmds =~ i ]] || atlas .echo a "saved"
        :;} || atlas .echo e "huh…? use a proper save path"

    }

    [[ $1 = .u ]] && {

        [[ $cmds =~ i && $(tac "$log" | grep -m1 upgraded) > [$(date -d -${upgrade_interval}days +%F)U ]] || {
            atlas .echo q "scan for updates?"

            [[ ${REPLY,} = y ]] && {
                $(type -P yay || type -P paru || echo "$auth pacman") -Syu
                echo

                [[ $(type -P flatpak) ]] && {
                    flatpak update && flatpak remove --unused
                    echo
                }
            }

            atlas .veil 0
        }

    }

    [[ $1 = .d ]] && {

        local i
        local -A delta

        [[ -r $save_path ]] && {
            for i in root apps orphans
            do
                local -n xarr=$i

                delta[${i}0]=$(grep -vxFf <(printf "%s$n" ${xarr[@]}) "$save_path/$i")
                delta[${i}1]=$(grep -vxFf "$save_path/$i" <(printf "%s$n" ${xarr[@]}))

                [[ ${delta[${i}0]}${delta[${i}1]} ]] && {
                    atlas .echo i "$i difference"

                    [[ ${delta[${i}0]} ]] && printf " $dim◎ %s$reset$n" ${delta[${i}0]}

                    [[ ${delta[${i}1]} ]] && {
                        [[ $i = orphans ]] && echo -n "$red"
                        printf " ◉ %s$n" ${delta[${i}1]}
                        echo -n "$reset"
                    }

                    echo
                }
            done 2>/dev/null

            [[ ${delta[@]} =~ [^\ ] ]] || [[ $cmds =~ i ]] || atlas .echo a "difference: nil"
        :;} || [[ $cmds =~ s ]] || atlas .echo e "you forgot to save…"

    }

    [[ $1 = .c ]] && {

        local cache

        [[ $orphans ]] && {
            atlas .echo q "remove orphans (${#orphans[@]})?"

            [[ ${REPLY,} = y ]] && {
                $auth pacman -Rns ${orphans[@]}
                echo
            }

            atlas .veil 0
        :;} || [[ $cmds =~ i ]] || atlas .echo a "no orphans to remove"

        mapfile -t cache < <(pacman-conf CacheDir)
        local csize=$(du -shc "${cache[@]}" 2>/dev/null | tail -1 | cut -f1)

        [[ $csize != 0 ]] && {
            [[ $cmds =~ i ]] && (( cache_limit<<30 > $(numfmt --from=iec "$csize") )) || {
                atlas .echo q "clear cache ($csize)?"

                [[ ${REPLY,} = y ]] && {
                    yes | $auth pacman -Scc &>/dev/null
                    atlas .echo a "updated cache size: $(du -shc "${cache[@]}" 2>/dev/null | tail -1 | cut -f1)"
                }

                atlas .veil 0
            }
        :;} || [[ $cmds =~ i ]] || atlas .echo a "cache is empty"

    }

    [[ $1 = .X ]] && {

        atlas .echo w "are you sure?"

        [[ ${REPLY,} = y ]] && atlas .suicide || atlas .echo a "…i'm flattered"

        atlas .veil 0

    }

#  ├── core ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    [[ $1 = .suicide ]] && {

        rm -rf "$save_path"

        grep -q ' //  ▲  \\\\ ' "$BASH_SOURCE" && sed -i '\L << A T \L A S >> L, \| //  ▲  \\\\ | d' "$BASH_SOURCE"
        grep -q "atlas()" "$BASH_SOURCE" && {
            atlas .echo e "feeling a little clingy, delete the source code yourself"
        :;} || atlas .echo a "…bye"

        atlas .signal 0
        unset -f atlas

        kill -2 $$

    }

    [[ $1 = .error ]] && {

        local mode=$2

        [[ $mode = c ]] && atlas .echo e "not sure what you mean, see 'atlas ?' for syntax"

        [[ $mode = s ]] && {
            atlas .echo i "atlas syntax"
            echo " ╭── modifiers ──────────────╮"
            echo " │ q  ·  quiet output        │"
            echo " │ y  ·  auto confirm        │"
            echo " │ i  ·  intelligent mode    │"
            echo " ╰───────────────────────────╯$n"
            echo " ╭── operations ─────────────╮"
            echo " │ r  ·  view root           │"
            echo " │ a  ·  view apps           │"
            echo " │ o  ·  view orphans        │"
            echo " │ s  ·  save system state   │"
            echo " │ u  ·  upgrade system      │"
            echo " │ d  ·  view difference     │"
            echo " │ c  ·  system cleanup      │"
            echo " │ X  ·  erase atlas         │"
            echo " ╰───────────────────────────╯$n"
        }

        kill -2 $$

    }

    [[ $1 = .signal ]] && {

        local stage=$2

        (( stage )) && {
            atlas .veil 0
            trap '
                atlas .pulse 0
                atlas .signal 0
                atlas .echo e "atlas terminated"
                kill -2 $$
            ' 2 15
        :;} || {
            atlas .veil 1
            trap - 2 15
        }

    }

    [[ $1 = .veil ]] && {

        local stage=$2

        (( stage )) && {
            stty echo </dev/tty 2>/dev/null
            echo -n "$show"
        :;} || {
            stty -echo 2>/dev/null
            echo -n "$hide"
        }

    }

    [[ $1 = .scan ]] && {

        local scmds=$2

        [[ $scmds =~ r && ! $cmds =~ q ]] && scmds+=l
        [[ $scmds =~ s ]] && mkdir -p "$save_path" 2>/dev/null
        [[ $scmds =~ s && -w $save_path || $scmds =~ d && -r $save_path ]] && scmds+=rio
        scmds=${scmds/c/o}

        modified[l1]=$(stat -c %Y "$log")
        modified[f1]=$(stat -c %Y /var/lib/flatpak 2>/dev/null)

        [[ ${modified[l0]} = ${modified[l1]} ]] || {
            scanned=${scanned//[rlo]}
            modified[l0]=${modified[l1]}
        }

        [[ ${modified[f0]} = ${modified[f1]} ]] || {
            scanned=${scanned//[ai]}
            modified[f0]=${modified[f1]}
        }

        scmds=${scmds//[$scanned]}
        scanned+=$scmds

        atlas .pulse 1

        {
            [[ $scmds =~ [ro] ]] && {
                echo -n "${dim}scanning orphans…$reset"
                orphans=( $(pacman -Qqtd) )
                atlas .chrono 13
            }

            [[ $scmds =~ r ]] && {
                echo -n "${dim}scanning root…$reset$clear"
                root=( $(grep -vxFf <(printf "%s$n" ${orphans[@]}) <(pacman -Qqtt)) )
                atlas .chrono 13
            }

            [[ $scmds =~ a ]] && {
                echo -n "${dim}scanning apps…$reset$clear"
                mapfile -t appnames < <(flatpak list --app --columns=name)
                atlas .chrono 13
            }

            [[ $scmds =~ i ]] && {
                echo -n "${dim}scanning app ids…$reset$clear"
                apps=( $(flatpak list --app --columns=app) )
                atlas .chrono 13
            }

            atlas .extract $scmds
        } 2>/dev/null

        atlas .pulse 0

    }

    [[ $1 = .pulse ]] && {

        local stage=$2

        (( stage )) && {
            echo -n "  "
            while :
            do
                for f in ◟ ◜ ◝ ◞ ○ ◎ ◉ ● ◉ ◎ ○
                do
                    echo -n "$r$bold$f$reset "
                    atlas .chrono 115
                done
            done &async[pulse]=$!
        :;} 2>/dev/null || {
            echo -n "$r$clear"
            kill ${async[pulse]}
            wait "${async[pulse]}"
        } 2>/dev/null

    }

    [[ $1 = .chrono ]] && {

        local denominator=$2

        [[ $cmds =~ q ]] || read -t $(awk "BEGIN { print $fake_delay/$denominator }")

    }

    [[ $1 = .extract ]] && {

        local scmds=$2 pkg opt

        [[ $scmds =~ l ]] && {
            echo -n "${dim}extracting lineage…$reset$clear"
            lineage=()
            atlas .chrono 13

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
                atlas .chrono 666

                local children=( ${arr[$i]} )
                atlas .render children $arrn "$attr" "$depth$indent$dim"
            }
        done

        [[ $depth ]] || echo

    }

    [[ $1 = .echo ]] && {

        local scmds=$2 msg=$3

        atlas .emit $scmds

        [[ $scmds = a ]] && echo "$dim∴ $msg$reset$n"
        [[ $scmds = i ]] && echo "$bold∵ $msg$reset$n"
        [[ $scmds = e ]] && echo "$red⚠︎ $msg$reset$n"

        REPLY=y

        [[ $scmds =~ [qw] && ! $cmds =~ y ]] && {
            [[ $scmds = q ]] && echo -n "∷ $msg {y/${bold}n$reset}"
            [[ $scmds = w ]] && echo -n "$red⁘ $msg {y/${bold}n$reset$red}$reset"

            atlas .veil 1
            while read -t 0
            do read
            done
            read -s -n 1
            echo -n "$r$clear"
        }

    }

    [[ $1 = .emit ]] && {

        local scmds=$2
        local -A ids=([a]=window-attention [i]=dialog-information [e]=dialog-error [q]=window-question [w]=dialog-warning)

        [[ $cmds =~ q ]] || {
            kill -- -${async[emit]}
            canberra-gtk-play -i ${ids[$scmds]} &async[emit]=$!
            disown ${async[emit]}
        } 2>/dev/null

    }

#  ╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯

}

# ┄┄───════════════════════════════════════════════════════════════════════ //  ▲  \\ ════════════════════════════════════════════════════════════════════───┄┄ #
