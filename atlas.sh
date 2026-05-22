# ┄┄───═════════════════════════════════════════════════════════════════ << A T L A S >> ═════════════════════════════════════════════════════════════════───┄┄ #

atlas() {

#  ╭── configuration ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮

    {

        local save_directory="/tmp/atlas"
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
            atlas .echo :0 "you're not even using arch silly"
            atlas .suicide
        }

        cmds=${cmds//-}

        [[ $cmds = \? ]] && {
            atlas .echo :1 "atlas syntax"
            echo " ╭── operations ─────────────╮"
            echo " │ a  ·  view apps           │"
            echo " │ c  ·  cleanup             │"
            echo " │ d  ·  view difference     │"
            echo " │ g  ·  generate system     │"
            echo " │ i  ·  view app ids        │"
            echo " │ o  ·  view orphans        │"
            echo " │ r  ·  view root           │"
            echo " │ s  ·  save system         │"
            echo " │ u  ·  upgrade             │"
            echo " │ x  ·  erase atlas         │"
            echo " ╰───────────────────────────╯$n"
            echo " ╭── modifiers ──────────────╮"
            echo " │ I  ·  implicit            │"
            echo " │ Q  ·  quick               │"
            echo " ╰───────────────────────────╯$n"
            kill -2 $$
        }

        [[ ${cmds//[acdgiorsuxIQ]} ]] && {
            atlas .echo :0 "not sure what you mean, see 'atlas ?' for syntax"
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
        :;} || atlas .echo :3 "apps: nil"

    }

    [[ $1 = .c ]] && {

        local cache

        [[ $orphans ]] && {
            atlas .echo ?1 "remove orphans (${#orphans[@]})?"

            [[ ${REPLY,} = y ]] && {
                $auth pacman -Rns ${orphans[@]}
                echo
            }

            atlas .await 0
        :;} || atlas .echo :3 "no orphans to remove"

        mapfile -t cache < <(pacman-conf CacheDir)
        local csize=$(du -bc "${cache[@]}" 2>/dev/null | tail -1 | cut -f1)

        [[ $cmds =~ I ]] && (( cache_limit<<30 > csize )) || {
            atlas .echo ?1 "clear cache ($(numfmt --to=iec "$csize"))?"

            [[ ${REPLY,} = y ]] && {
                yes | $auth pacman -Sc &>/dev/null
                local csized=$(( csize - $(du -bc "${cache[@]}" 2>/dev/null | tail -1 | cut -f1) ))
                (( csized )) && {
                    atlas .echo :1 "cleared: $(numfmt --to=iec "$csized")"
                :;} || atlas .echo :3 "nothing to clear"
            }

            atlas .await 0
        }

    }

    [[ $1 = .d ]] && {

        local i
        local -A delta

        [[ -r $save_directory ]] && {
            for i in root apps orphans
            do
                local -n xarr=$i

                delta[${i}0]=$(grep -vxFf <(printf "%s$n" ${xarr[@]}) "$save_directory/$i")
                delta[${i}1]=$(grep -vxFf "$save_directory/$i" <(printf "%s$n" ${xarr[@]}))

                [[ ${delta[${i}0]}${delta[${i}1]} ]] && {
                    atlas .echo :1 "$i difference"

                    [[ ${delta[${i}0]} ]] && printf " $dim⊖ %s$reset$n" ${delta[${i}0]}

                    [[ ${delta[${i}1]} ]] && {
                        [[ $i = orphans ]] && echo -n "$red"
                        printf " ⊕ %s$n" ${delta[${i}1]}
                        echo -n "$reset"
                    }

                    echo
                }
            done 2>/dev/null

            [[ ${delta[@]} =~ [^\ ] ]] || atlas .echo :3 "difference: nil"
        :;} || [[ $cmds =~ s ]] || atlas .echo :0 "you forgot to save…"

    }

    [[ $1 = .g ]] && {

        [[ -r $save_directory ]] && {
            atlas .echo :0 "this carries some risk"
            atlas .echo ?0 "set up aur and flathub if you need, proceed?"

            [[ ${REPLY,} = y ]] && {
                [[ -s $save_directory/root ]] && {
                    $(type -P yay || type -P paru || echo "$auth pacman") -S --needed $(< "$save_directory/root")
                    $auth pacman -D --asdeps $(pacman -Qqe)
                    $auth pacman -D --asexplicit $(< "$save_directory/root")
                    $auth pacman -Rns $(pacman -Qqttd)
                    echo
                }

                [[ -s $save_directory/apps ]] && {
                    flatpak install $(< "$save_directory/apps")
                    local fdelta=$(grep -vxFf "$save_directory/apps" <(flatpak list --app --columns=app))
                    [[ $fdelta ]] && flatpak remove $fdelta
                    flatpak remove --unused
                    echo
                }
            }

            atlas .await 0
        :;} || atlas .echo :0 "couldn't find your save directory"

    }

    [[ $1 = .i ]] && {

        [[ $apps ]] && {
            echo "${bold}app ids (${#apps[@]})$reset"
            atlas .render apps null
        :;} || atlas .echo :3 "app ids: nil"

    }

    [[ $1 = .o ]] && {

        [[ $orphans ]] && {
            echo "$red${bold}orphans (${#orphans[@]})$reset"
            atlas .render orphans null "$red"
        :;} || atlas .echo :3 "orphans: nil"

    }

    [[ $1 = .r ]] && {

        echo "${bold}root (${#root[@]})$reset"
        atlas .render root lineage

    }

    [[ $1 = .s ]] && {

        mkdir -p "$save_directory"

        [[ -w $save_directory ]] && {
            printf "%s$n" ${root[@]} > "$save_directory/root"
            printf "%s$n" ${apps[@]} > "$save_directory/apps"
            printf "%s$n" ${orphans[@]} > "$save_directory/orphans"

            atlas .echo :3 "saved"
        :;} || atlas .echo :0 "…? use a proper save path"

    }

    [[ $1 = .u ]] && {

        [[ $cmds =~ I && $(tac "$log" | grep -m1 upgraded) > [$(date -d -${upgrade_interval}days +%F)U ]] || {
            atlas .echo ?1 "scan for updates?"

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

    [[ $1 = .x ]] && {

        atlas .echo ?0 "are you sure?"

        [[ ${REPLY,} = y ]] && atlas .suicide || atlas .echo :3 "…i'm flattered"

        atlas .await 0

    }

#  ├── core ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    [[ $1 = .await ]] && {

        local stage=$2

        (( stage )) && {
            stty echo </dev/tty
            echo -n "$show"
        :;} 2>/dev/null || {
            stty -echo
            echo -n "$hide"
        } 2>/dev/null

    }

    [[ $1 = .cycle ]] && {

        local list=$2 arrn=$3 last=$4 recursed=$5 i
        local -n arr=$arrn

        for i in $list
        do [[ $recursed =~ " $i " ]] && arr[$last]=${arr[$last]/ $i } || atlas .cycle "${arr[$i]}" $arrn $i " $recursed $i "
        done

    }

    [[ $1 = .echo ]] && {

        local scmds=$2 say=$3

        [[ $scmds = :0 ]] && {
            echo "$red⚠︎ $say$reset$n"
            atlas .emit e
        }

        [[ $scmds = :1 ]] && {
            echo "$bold「 $say 」$reset$n"
            atlas .emit i
        }

        [[ $scmds = :2 ]] && {
            echo -n "$origin$dim$say…$reset$clear"
            [[ $cmds =~ Q ]] || read -t 0.3
        }

        [[ $scmds = :3 && ! $cmds =~ I ]] && {
            echo "$dim∴ $say$reset$n"
            atlas .emit a
        }

        [[ $scmds = \?0 ]] && {
            echo -n "$red⚠︎ $say {y/${bold}n$reset$red}$reset "
            atlas .await 1
            atlas .emit w
            read -s -n 1
            echo -n "$r$clear"
        }

        [[ $scmds = \?1 ]] && {
            echo -n "✧ $say {y/${bold}n$reset} "
            atlas .await 1
            REPLY=y
            [[ $cmds =~ I ]] && {
                atlas .emit q
                read -s -n 1
            }
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
            atlas .echo :2 "extracting lineage"
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
                for f in ◟ ◜ ◝ ◞ ○ ◉ ● ◉ ○
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
                atlas .echo :2 "scanning orphans"
                orphans=( $(pacman -Qqtd) )
            }

            [[ $scmds =~ [rsd] ]] && {
                atlas .echo :2 "scanning root"
                root=( $(grep -vxFf <(printf "%s$n" ${orphans[@]}) <(pacman -Qqtt)) )
            }

            [[ $scmds =~ [isd] ]] && {
                atlas .echo :2 "scanning app ids"
                apps=( $(flatpak list --app --columns=app) )
            }

            [[ $scmds =~ a ]] && {
                atlas .echo :2 "scanning apps"
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
                atlas .echo :0 "atlas terminated"
                kill -2 $$
            ' 2 15
            atlas .await 0
        :;} || {
            trap - 2 15
            atlas .await 1
        }

    }

    [[ $1 = .suicide ]] && {

        rm -rf "$save_directory"

        grep -q ' //  ▲  \\\\ ' "$BASH_SOURCE" && sed -i '\L << A T \L A S >> L, \| //  ▲  \\\\ | d' "$BASH_SOURCE"
        grep -q "atlas()" "$BASH_SOURCE" && {
            atlas .echo :0 "delete the source code yourself"
        :;} || atlas .echo :3 "…bye"

        atlas .signal 0
        unset -f atlas
        kill -2 $$

    }

#  ╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯

}

# ┄┄───════════════════════════════════════════════════════════════════════ //  ▲  \\ ════════════════════════════════════════════════════════════════════───┄┄ #

