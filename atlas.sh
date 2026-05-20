# ┄┄───═════════════════════════════════════════════════════════════════ << A T L A S >> ═════════════════════════════════════════════════════════════════───┄┄ #

atlas() {

#  ╭── configuration ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮

    {

        local save_path="/tmp/atlas"
        local default_commands=raosudcI
        local upgrade_interval=6
        local cache_limit=6

    }

#  ├── execution ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    (( executing - 66 )) && {

        local cmds=$1 executing=66 auth=$(type -P sudo || type -P doas)
        local bold=$'\e[1m' dim=$'\e[2m' red=$'\e[31m' reset=$'\e[m' hide=$'\e[?25l' show=$'\e[?25h' clear=$'\e[K' origin=$'\e[3G' n=$'\n' r=$'\r'
        local appnames apps log orphans root scanned
        local -A async lineage modified null

        echo
        atlas :resolve
        atlas :dispatch
        echo

    }

#  ├── cortex ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    [[ $1 = :resolve ]] && {

        [[ $(type -P pacman) ]] || {
            atlas .echo i0 "you're not even using arch silly"
            atlas .suicide
        }

        cmds=${cmds//-}

        [[ $cmds = \? ]] && {
            atlas .echo i1 "atlas syntax"
            echo " ╭── operations ─────────────╮"
            echo " │ a  ·  view apps           │"
            echo " │ c  ·  system cleanup      │"
            echo " │ d  ·  view difference     │"
            echo " │ g  ·  generate system     │"
            echo " │ i  ·  view app ids        │"
            echo " │ o  ·  view orphans        │"
            echo " │ r  ·  view root           │"
            echo " │ s  ·  save system state   │"
            echo " │ u  ·  upgrade system      │"
            echo " │ x  ·  erase atlas         │"
            echo " ╰───────────────────────────╯$n"
            echo " ╭── modifiers ──────────────╮"
            echo " │ I  ·  implicit mode       │"
            echo " │ Q  ·  quiet mode          │"
            echo " ╰───────────────────────────╯$n"
            kill -2 $$
        }

        [[ ${cmds//[acdgiorsuxIQ]} ]] && {
            atlas .echo i0 "not sure what you mean, see 'atlas ?' for syntax"
            kill -2 $$
        }

        [[ ${cmds//[IQ]} ]] || cmds+=$default_commands

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

    [[ $1 = .a ]] && {

        [[ $appnames ]] && {
            echo "${bold}apps (${#appnames[@]})$reset"
            atlas .render appnames null
        :;} || atlas .echo i3 "apps: nil"

    }

    [[ $1 = .c ]] && {

        local cache

        [[ $orphans ]] && {
            atlas .echo q1 "remove orphans (${#orphans[@]})?"

            [[ ${REPLY,} = y ]] && {
                $auth pacman -Rns ${orphans[@]}
                echo
            }

            atlas .veil 0
        :;} || atlas .echo i3 "no orphans to remove"

        mapfile -t cache < <(pacman-conf CacheDir)
        local csize0=$(du -bc "${cache[@]}" 2>/dev/null | tail -1 | cut -f1)

        [[ $csize0 != 0 ]] && {
            [[ $cmds =~ I ]] && (( cache_limit<<30 > csize0 )) || {
                atlas .echo q1 "clear cache ($(numfmt --to=iec "$csize0"))?"

                [[ ${REPLY,} = y ]] && {
                    yes | $auth pacman -Sc &>/dev/null
                    local csize1=$(du -bc "${cache[@]}" 2>/dev/null | tail -1 | cut -f1)
                    atlas .echo i1 "cleared: $(numfmt --to=iec "$(( csize0 - csize1 ))")"
                }

                atlas .veil 0
            }
        :;} || atlas .echo i3 "cache is empty"

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
                    atlas .echo i1 "$i difference"

                    [[ ${delta[${i}0]} ]] && printf " $dim◎ %s$reset$n" ${delta[${i}0]}

                    [[ ${delta[${i}1]} ]] && {
                        [[ $i = orphans ]] && echo -n "$red"
                        printf " ◉ %s$n" ${delta[${i}1]}
                        echo -n "$reset"
                    }

                    echo
                }
            done 2>/dev/null

            [[ ${delta[@]} =~ [^\ ] ]] || atlas .echo i3 "difference: nil"
        :;} || [[ $cmds =~ s ]] || atlas .echo i0 "you forgot to save…"

    }

    [[ $1 = .g ]] && {

        atlas .echo i0 "this might brick your system if you're doing some funny cross distro shit, so i hope you understand the risk"
        atlas .echo i0 "also, make sure to set up aur and flathub if you need it"
        atlas .echo q0 "proceed?"

        [[ ${REPLY,} = y ]] && {
            [[ -r $save_path ]] && {
                [[ -r $save_path/root ]] && {
                    $(type -P yay || type -P paru || echo "$auth pacman") -S --needed $(< "$save_path/root")
                    $auth pacman -D --asdeps $(pacman -Qqe)
                    $auth pacman -D --asexplicit $(< "$save_path/root")
                    $auth pacman -Rns $(pacman -Qqttd)
                    echo
                }

                [[ -r $save_path/apps && $(type -P flatpak) ]] && {
                    flatpak install $(< "$save_path/apps")
                    flatpak remove $(grep -vxFf "$save_path/apps" <(flatpak list --app --columns=app))
                    echo
                }
            :;} || atlas .echo i0 "couldn't find your save file"
        }

        atlas .veil 0

    }

    [[ $1 = .i ]] && {

        [[ $apps ]] && {
            echo "${bold}app ids (${#apps[@]})$reset"
            atlas .render apps null
        :;} || atlas .echo i3 "app ids: nil"

    }

    [[ $1 = .o ]] && {

        [[ $orphans ]] && {
            echo "$red${bold}orphans (${#orphans[@]})$reset"
            atlas .render orphans null "$red"
        :;} || atlas .echo i3 "orphans: nil"

    }

    [[ $1 = .r ]] && {

        echo "${bold}root (${#root[@]})$reset"
        atlas .render root lineage

    }

    [[ $1 = .s ]] && {

        mkdir -p "$save_path"

        [[ -w $save_path ]] && {
            printf "%s$n" ${root[@]} > "$save_path/root"
            printf "%s$n" ${apps[@]} > "$save_path/apps"
            printf "%s$n" ${orphans[@]} > "$save_path/orphans"

            atlas .echo i3 "saved"
        :;} || atlas .echo i0 "huh…? use a proper save path"

    }

    [[ $1 = .u ]] && {

        [[ $cmds =~ I && $(tac "$log" | grep -m1 upgraded) > [$(date -d -${upgrade_interval}days +%F)U ]] || {
            atlas .echo q1 "scan for updates?"

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

    [[ $1 = .x ]] && {

        atlas .echo q0 "are you sure?"

        [[ ${REPLY,} = y ]] && atlas .suicide || atlas .echo i3 "…i'm flattered"

        atlas .veil 0

    }

#  ├── core ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    [[ $1 = .cycle ]] && {

        local list=$2 arrn=$3 last=$4 recursed=$5 i
        local -n arr=$arrn

        for i in $list
        do [[ $recursed =~ " $i " ]] && arr[$last]=${arr[$last]/ $i } || atlas .cycle "${arr[$i]}" $arrn $i " $recursed $i "
        done

    }

    [[ $1 = .echo ]] && {

        local scmds=$2 msg=$3

        [[ $scmds = i0 ]] && {
            echo "$red⚠︎ $msg$reset$n"
            atlas .emit e
        }

        [[ $scmds = i1 ]] && {
            echo "$bold「 $msg 」$reset$n"
            atlas .emit i
        }

        [[ $scmds = i2 ]] && {
            echo -n "$origin$dim$msg…$reset$clear"
            [[ $cmds =~ Q ]] || read -t 0.3
        }

        [[ $scmds = i3 && ! $cmds =~ I ]] && {
            echo "$dim○ $msg$reset$n"
            atlas .emit a
        }

        [[ $scmds = q0 ]] && {
            echo -n "$red⚠︎ $msg {y/${bold}n$reset$red}$reset "
            atlas .emit w
            atlas .veil 1
            read -s -n 1
            echo -n "$r$clear"
        }

        [[ $scmds = q1 ]] && {
            echo -n "◎ $msg {y/${bold}n$reset} "
            atlas .emit q
            atlas .veil 1
            [[ $cmds =~ I ]] && read -s -n 1 || REPLY=y
            echo -n "$r$clear"
        }

    }

    [[ $1 = .emit ]] && {

        local scmds=$2
        local -A ids=( [a]=window-attention [i]=dialog-information [e]=dialog-error [q]=window-question [w]=dialog-warning )

        [[ $cmds =~ Q ]] || {
            kill -- -${async[emit]}
            canberra-gtk-play -i ${ids[$scmds]} &async[emit]=$!
            disown ${async[emit]}
        } &>/dev/null

    }

    [[ $1 = .extract ]] && {

        local scmds=$2 pkg opt

        [[ $scmds =~ r && ! $cmds =~ Q ]] && {
            atlas .echo i2 "extracting lineage"
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

    [[ $1 = .pulse ]] && {

        local stage=$2

        (( stage )) && {
            while :
            do
                for f in ◟ ◜ ◝ ◞ ○ ◎ ◉ ● ◉ ◎ ○
                do
                    echo -n "$r$bold$f$reset"
                    sleep 0.06
                done
            done &async[pulse]=$!
        :;} 2>/dev/null || {
            kill ${async[pulse]}
            wait "${async[pulse]}"
            echo -n "$r$clear"
        } 2>/dev/null

    }

    [[ $1 = .render ]] && {

        local xarrn=$2 arrn=$3 attr=$4 depth=$5 i x
        local -n xarr=$xarrn arr=$arrn

        for i in "${xarr[@]}"
        do
            [[ ! $depth && ${arr[@]} =~ " $i " ]] || {
                [[ $cmds =~ Q ]] || {
                    [[ $depth ]] || echo "$attr│"
                    (( x )) || local xx=$([[ $depth ]] && echo ${#xarr[@]} || grep -cvxFf <(printf "%s$n" ${arr[@]}) <(printf "%s$n" "${xarr[@]}"))
                    (( ++x == xx )) && local pfx="╰─ " indent="   " || local pfx="├─ " indent="│  "
                    read -t 0.006
                }

                echo "$attr$depth$pfx$i$reset"

                local children=( ${arr[$i]} )
                atlas .render children $arrn "$attr" "$depth$indent$dim"
            }
        done

        [[ $depth ]] || echo

    }

    [[ $1 = .scan ]] && {

        local scmds=$2

        modified[l1]=$(stat -c %Y "$log")
        modified[f1]=$(stat -c %Y /var/lib/flatpak 2>/dev/null)

        [[ ${modified[l0]} = ${modified[l1]} ]] || {
            scanned=${scanned//[ro]}
            modified[l0]=${modified[l1]}
        }

        [[ ${modified[f0]} = ${modified[f1]} ]] || {
            scanned=${scanned//[ia]}
            modified[f0]=${modified[f1]}
        }

        scmds=${scmds//[$scanned]}
        scanned+=$scmds

        atlas .pulse 1

        {
            [[ $scmds =~ [ocrsd] ]] && {
                atlas .echo i2 "scanning orphans"
                orphans=( $(pacman -Qqtd) )
            }

            [[ $scmds =~ [rsd] ]] && {
                atlas .echo i2 "scanning root"
                root=( $(grep -vxFf <(printf "%s$n" ${orphans[@]}) <(pacman -Qqtt)) )
            }

            [[ $scmds =~ [isd] ]] && {
                atlas .echo i2 "scanning app ids"
                apps=( $(flatpak list --app --columns=app) )
            }

            [[ $scmds =~ a ]] && {
                atlas .echo i2 "scanning apps"
                mapfile -t appnames < <(flatpak list --app --columns=name)
            }

            atlas .extract $scmds
        } 2>/dev/null

        atlas .pulse 0

    }

    [[ $1 = .signal ]] && {

        local stage=$2

        (( stage )) && {
            trap '
                atlas .signal 0
                atlas .pulse 0
                atlas .echo i0 "atlas terminated"
                kill -2 $$
            ' 2 15
            atlas .veil 0
        :;} || {
            trap - 2 15
            atlas .veil 1
        }

    }

    [[ $1 = .suicide ]] && {

        rm -rf "$save_path"

        grep -q ' //  ▲  \\\\ ' "$BASH_SOURCE" && sed -i '\L << A T \L A S >> L, \| //  ▲  \\\\ | d' "$BASH_SOURCE"
        grep -q "atlas()" "$BASH_SOURCE" && {
            atlas .echo i0 "feeling a little clingy, delete the source code yourself"
        :;} || atlas .echo i3 "…bye"

        atlas .signal 0
        unset -f atlas
        kill -2 $$

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

#  ╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯

}

# ┄┄───════════════════════════════════════════════════════════════════════ //  ▲  \\ ════════════════════════════════════════════════════════════════════───┄┄ #
