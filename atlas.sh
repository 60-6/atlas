# ┄┄───═════════════════════════════════════════════════════════════════════════════════ << A T L A S >> ═════════════════════════════════════════════════════════════════════════════════───┄┄ #

atlas() {

#  ╭── configuration ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮

    {

        local save_directory="/tmp"
        local default_commands=raosudcI
        local upgrade_interval=6
        local cache_limit=6

    }

#  ├── cortex ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    [[ $code = samsara ]] || {

        local _1=$1 code=samsara auth=$(type -P sudo || type -P doas) save=$save_directory/atlas/$2
        local bold=$'\e[1m' dim=$'\e[2m' red=$'\e[31m' reset=$'\e[m' hide=$'\e[?25l' show=$'\e[?25h' clear=$'\e[K' origin=$'\e[3G' n=$'\n' r=$'\r'
        local appnames apps log orphans root scanned
        local -A async lineage modified null

        echo
        atlas :resolve
        atlas :dispatch
        echo

    }

    [[ $1 = :resolve ]] && {

        [[ $(type -P pacman) ]] || {
            atlas .echo i0 "you're not even using arch silly"
            atlas .suicide
        }

        [[ ${_1//[IQ]} ]] || _1+=$default_commands

        [[ $_1 = \? ]] && {
            atlas .echo a0 "atlas syntax"
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

        [[ ${_1//[acdgiorsuxIQ]} ]] && {
            atlas .echo i0 "not sure what you mean, see 'atlas ?' for syntax"
            kill -2 $$
        }

        log=$(pacman-conf LogFile)

    }

    [[ $1 = :dispatch ]] && {

        atlas .signal 1
        atlas .scan $_1

        local i

        for i in $(fold -w1 <<< $_1)
        do
            atlas .scan $i
            atlas .$i
        done

        atlas .signal 0

    }

#  ├── operations ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    [[ $1 = .a ]] && {

        [[ $appnames ]] && {
            echo "${bold}apps (${#appnames[@]})$reset"
            atlas .render appnames null
        :;} || atlas .echo i1 "apps: nil"

    }

    [[ $1 = .c ]] && {

        [[ $orphans ]] && {
            atlas .echo q1 "remove orphans?"

            [[ ${REPLY,} = y ]] && {
                atlas .await 1
                $auth pacman -Rns ${orphans[@]}
                atlas .await 0
                echo
            }
        :;} || atlas .echo i1 "no orphans to remove"

        local cache
        mapfile -t cache < <(pacman-conf CacheDir)
        local csize=$(du -bc "${cache[@]}" 2>/dev/null | tail -1 | cut -f1)

        [[ $_1 =~ I ]] && (( cache_limit<<30 > csize )) || {
            atlas .echo q1 "clear cache ($(numfmt --to=iec "$csize"))?"

            [[ ${REPLY,} = y ]] && {
                atlas .await 1
                yes | $auth pacman -Sc &>/dev/null
                atlas .await 0

                local csized=$(( csize - $(du -bc "${cache[@]}" 2>/dev/null | tail -1 | cut -f1) ))

                (( csized )) && {
                    atlas .echo a0 "cleared: $(numfmt --to=iec "$csized")"
                :;} || atlas .echo i1 "nothing to clear"
            }
        }

    }

    [[ $1 = .d ]] && {

        [[ -r $save ]] && {
            local i
            local -A delta

            for i in root apps orphans
            do
                local -n xarr=$i

                delta[${i}0]=$(grep -vxFf <(printf "%s$n" ${xarr[@]}) "$save/$i")
                delta[${i}1]=$(grep -vxFf "$save/$i" <(printf "%s$n" ${xarr[@]}))

                [[ ${delta[${i}0]}${delta[${i}1]} ]] && {
                    atlas .echo a0 "$i difference"

                    [[ ${delta[${i}0]} ]] && printf " $dim⊖ %s$reset$n" ${delta[${i}0]}

                    [[ ${delta[${i}1]} ]] && {
                        [[ $i = orphans ]] && echo -n "$red"
                        printf " ⊕ %s$n" ${delta[${i}1]}
                        echo -n "$reset"
                    }

                    echo
                :;} || [[ ! -r $save/$i ]] || atlas .echo i1 "$i difference: nil"
            done 2>/dev/null
        :;} || atlas .echo i0 "can't diff against nothing"

    }

    [[ $1 = .g ]] && {

        [[ -r $save ]] && {
            atlas .echo i1 "i hope you understand that this is risky..."
            atlas .echo q0 "set up aur and flatpak if you need, proceed?"

            [[ ${REPLY,} = y ]] && {
                atlas .await 1

                [[ -s $save/root ]] && $(type -P yay || type -P paru || echo "$auth pacman") -S --needed $(< "$save/root") && {
                    $auth pacman -D --asdeps $(pacman -Qqe)
                    $auth pacman -D --asexplicit $(< "$save/root")
                    local rdelta=$(pacman -Qqttd)
                    [[ $rdelta ]] && $auth pacman -Rns $rdelta
                    echo
                }

                [[ -s $save/apps ]] && flatpak install $(< "$save/apps") && {
                    local adelta=$(grep -vxFf "$save/apps" <(flatpak list --app --columns=app))
                    [[ $adelta ]] && flatpak remove $adelta
                    flatpak remove --unused
                    echo
                }

                atlas .await 0

                local overwrites=( "$save/supersede"/*/ ) dst i

                [[ -d $overwrites ]] && {
                    atlas .echo q0 "overwrite ${#overwrites[@]} $((( ${#overwrites[@]} - 1 )) && echo "destinations" || echo "destination")?"

                    [[ ${REPLY,} = y ]] && {
                        atlas .await 1

                        for i in "${overwrites[@]%/}"
                        do
                            dst=${i##*/}
                            dst=${dst//:/\/}
                            dst=${dst/#@/$HOME}
                            
                            $auth mkdir -p "$dst"
                            
                            find "$i" -mindepth 1 -maxdepth 1 | while IFS= read -r oentry
                            do $auth cp -a --remove-destination "$oentry" "$dst"
                            done
                        done

                        atlas .await 0
                    }
                }

                atlas .echo a0 "all done, make sure there weren't any errors"
            }
        :;} || atlas .echo i0 "you forgot to save..."

    }

    [[ $1 = .i ]] && {

        [[ $apps ]] && {
            echo "${bold}app ids (${#apps[@]})$reset"
            atlas .render apps null
        :;} || atlas .echo i1 "app ids: nil"

    }

    [[ $1 = .o ]] && {

        [[ $orphans ]] && {
            echo "$red${bold}orphans (${#orphans[@]})$reset"
            atlas .render orphans null "$red"
        :;} || atlas .echo i1 "orphans: nil"

    }

    [[ $1 = .r ]] && {

        echo "${bold}root (${#root[@]})$reset"
        atlas .render root lineage

    }

    [[ $1 = .s ]] && {

        mkdir -p "$save/supersede"

        [[ -w $save ]] && {
            printf "%s$n" ${root[@]} > "$save/root"
            printf "%s$n" ${apps[@]} > "$save/apps"
            printf "%s$n" ${orphans[@]} > "$save/orphans"

            local overwrites=( "$save/supersede"/*/ ) dst i

            [[ -d $overwrites ]] && {
                atlas .await 1

                for i in "${overwrites[@]%/}"
                do
                    dst=${i##*/}
                    dst=${dst//:/\/}
                    dst=${dst/#@/$HOME}
                    
                    find "$i" -not -type d | while IFS= read -r oentry
                    do
                        dentry=$dst/${oentry#$i/}
                        $([[ -r $dentry ]] || echo "$auth") cp -a --remove-destination "$dentry" "$oentry" 2>/dev/null || atlas .echo i1 "couldn't save $dentry"
                    done
                done

                atlas .await 0
            }

            atlas .echo i1 "saved"
        :;} || atlas .echo i0 "...? use a proper save path"

    }

    [[ $1 = .u ]] && {

        [[ $_1 =~ I && $(tac "$log" | grep -m1 upgraded) > [$(date -d -${upgrade_interval}days +%F)U ]] || {
            atlas .echo q1 "scan for updates?"

            [[ ${REPLY,} = y ]] && {
                atlas .await 1

                $(type -P yay || type -P paru || echo "$auth pacman") -Syu
                echo

                [[ $(type -P flatpak) ]] && {
                    flatpak update && flatpak remove --unused
                    echo
                }

                atlas .await 0

                local version=$(curl -fsS https://raw.githubusercontent.com/60-6/atlas/refs/heads/0/version)
                [[ $version && ! $code = $version ]] && atlas .echo a0 "a new version of atlas is available if you care, github.com/60-6/atlas"
            }
        }

    }

    [[ $1 = .x ]] && {

        atlas .echo q0 "are you sure?"
        [[ ${REPLY,} = y ]] && atlas .suicide || atlas .echo i1 "...i'm flattered"

    }

#  ├── core ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    [[ $1 = .await ]] && {

        local stage=$2

        (( stage )) && {
            stty echo </dev/tty
            echo -n "$show"
        :;} || {
            stty -echo
            echo -n "$hide"
        }

    }

    [[ $1 = .cycle ]] && {

        local list=$2 arrn=$3 last=$4 recursed=$5 i
        local -n arr=$arrn

        for i in $list
        do [[ $recursed =~ " $i " ]] && arr[$last]=${arr[$last]/ $i } || atlas .cycle "${arr[$i]}" $arrn $i " $recursed $i "
        done

    }

    [[ $1 = .echo ]] && {

        local cmds=$2 say=$3

        [[ $cmds = a0 ]] && {
            echo "$bold「 $say 」$reset$n"
            atlas .emit a
        }

        [[ $cmds = a1 ]] && {
            echo -n "$origin$dim$say$reset$clear"
            [[ $_1 =~ Q ]] || read -t 0.3
        }

        [[ $cmds = i0 ]] && {
            echo "$red⚠︎ $say$reset$n"
            atlas .emit e
        }

        [[ $cmds = i1 && ! $_1 =~ I ]] && {
            echo "$dim∴ $say$reset$n"
            atlas .emit i
        }

        [[ $cmds = q0 ]] && {
            echo -n "$red⚠︎ $say {y/${bold}n$reset$red}$reset "
            atlas .emit w
            atlas .await 1
            read -s -n 1
            atlas .await 0
            echo -n "$r$clear"
        }

        [[ $cmds = q1 ]] && {
            [[ $_1 =~ I ]] && {
                echo -n "✧ $say {y/${bold}n$reset} "
                atlas .emit q
                atlas .await 1
                read -s -n 1
                atlas .await 0
                echo -n "$r$clear"
            :;} || REPLY=y
        }

    }

    [[ $1 = .emit ]] && {

        local cmds=$2
        local -A ids=( [a]=window-attention [e]=dialog-error [i]=dialog-information [q]=window-question [w]=dialog-warning )

        [[ $_1 =~ Q ]] || kill -0 ${async[emit]} 2>/dev/null || {
            canberra-gtk-play -i ${ids[$cmds]} &async[emit]=$!
            disown ${async[emit]}
        } &>/dev/null

    }

    [[ $1 = .extract ]] && {

        local cmds=$2 pkg opt

        [[ $cmds =~ l && ! $_1 =~ Q ]] && {
            atlas .echo a1 "extracting lineage..."
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
                for i in ◟ ◜ ◝ ◞ ○ ◉ ● ◉ ○
                do
                    echo -n "$r$bold$i$reset"
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
                [[ $_1 =~ Q ]] || {
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

        local cmds=$2

        modified[l1]=$(stat -c %Y "$log")
        modified[f1]=$(stat -c %Y /var/lib/flatpak 2>/dev/null)

        [[ ${modified[l0]} = ${modified[l1]} ]] || {
            scanned=${scanned//[lor]}
            modified[l0]=${modified[l1]}
        }

        [[ ${modified[f0]} = ${modified[f1]} ]] || {
            scanned=${scanned//[ai]}
            modified[f0]=${modified[f1]}
        }

        cmds=${cmds/c/o}
        cmds=${cmds/r/lor}
        cmds=${cmds/[ds]/ior}
        cmds=${cmds//[$scanned]}
        scanned+=$cmds

        atlas .pulse 1

        {
            [[ $cmds =~ a ]] && {
                atlas .echo a1 "scanning apps..."
                mapfile -t appnames < <(flatpak list --app --columns=name)
            }

            [[ $cmds =~ i ]] && {
                atlas .echo a1 "scanning app ids..."
                apps=( $(flatpak list --app --columns=app) )
            }

            [[ $cmds =~ o ]] && {
                atlas .echo a1 "scanning orphans..."
                orphans=( $(pacman -Qqtd) )
            }

            [[ $cmds =~ r ]] && {
                atlas .echo a1 "scanning root..."
                root=( $(grep -vxFf <(printf "%s$n" ${orphans[@]}) <(pacman -Qqtt)) )
            }

            atlas .extract $cmds
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
            atlas .await 0
        :;} || {
            trap - 2 15
            atlas .await 1
        }

    }

    [[ $1 = .suicide ]] && {

        rm -rf "$save_directory/atlas"
        grep -q ' //  ▲  \\\\ ' "$BASH_SOURCE" && sed -i '\L << A T \L A S >> L, \| //  ▲  \\\\ | d' "$BASH_SOURCE"

        grep -q "atlas()" "$BASH_SOURCE" && {
            atlas .echo i0 "delete the source code yourself"
        :;} || atlas .echo i1 "...bye"

        atlas .signal 0
        unset -f atlas
        kill -2 $$

    }

#  ╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯

}

# ┄┄───════════════════════════════════════════════════════════════════════════════════════ //  ▲  \\ ════════════════════════════════════════════════════════════════════════════════════───┄┄ #
