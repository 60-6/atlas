# ┄┄───═════════════════════════════════════════════════════════════════════════════════ << A T L A S >> ═════════════════════════════════════════════════════════════════════════════════───┄┄ #

atlas() {

#  ╭── configuration ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮

    {

        local save_directory="/tmp"
        local default_commands=raosudcI
        local update_interval=6
        local cache_limit=6

    }

#  ╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯

#  ╭── cortex ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮

    [[ $code = samsara ]] || {

        local cmds=$1 code=samsara auth=$(type -P sudo || type -P doas) save=$save_directory/atlas/$2
        local bold=$'\e[1m' dim=$'\e[2m' red=$'\e[31m' reset=$'\e[m' hide=$'\e[?25l' show=$'\e[?25h' clear=$'\e[K' origin=$'\e[3G' n=$'\n' r=$'\r'
        local root appnames apps orphans scanned
        local -A async lineage modified null

        echo

        [[ $(type -P pacman) ]] || {
            atlas .echo i0 "you're not even using arch silly"
            atlas .suicide
        }

        [[ ${cmds//[IQ]} ]] || cmds+=$default_commands

        [[ ${cmds//[raioucsdgxIQ]} ]] && {
            [[ $cmds = \? ]] && {
                atlas .echo a0 "atlas syntax"
                echo " ╭── operations ─────────────╮"
                echo " │ r  ·  view root           │"
                echo " │ a  ·  view apps           │"
                echo " │ i  ·  view app ids        │"
                echo " │ o  ·  view orphans        │"
                echo " │ u  ·  upgrade             │"
                echo " │ c  ·  cleanup             │"
                echo " │ s  ·  save system         │"
                echo " │ d  ·  view difference     │"
                echo " │ g  ·  generate system     │"
                echo " │ x  ·  erase atlas         │"
                echo " ╰───────────────────────────╯$n"
                echo " ╭── modifiers ──────────────╮"
                echo " │ I  ·  intelligent         │"
                echo " │ Q  ·  quick               │"
                echo " ╰───────────────────────────╯$n"
            :;} || {
                atlas .echo i0 "not sure what you mean, see 'atlas ?' for syntax"
            }

            echo
            return
        }

        atlas .signal 1

        atlas .scan $cmds

        local i

        for i in $(fold -w1 <<< $cmds)
        do
            atlas .scan $i
            atlas :$i
        done

        atlas .signal 0

        echo

    }

#  ├── operations ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    [[ $1 = :r ]] && {

        echo "${bold}root (${#root[@]})$reset"
        atlas .render root lineage

    }

    [[ $1 = :a ]] && {

        [[ $appnames ]] && {
            echo "${bold}apps (${#appnames[@]})$reset"
            atlas .render appnames null
        :;} || atlas .echo i1 "apps: nil"

    }

    [[ $1 = :i ]] && {

        [[ $apps ]] && {
            echo "${bold}app ids (${#apps[@]})$reset"
            atlas .render apps null
        :;} || atlas .echo i1 "app ids: nil"

    }

    [[ $1 = :o ]] && {

        [[ $orphans ]] && {
            echo "$red${bold}orphans (${#orphans[@]})$reset"
            atlas .render orphans null "$red"
        :;} || atlas .echo i1 "orphans: nil"

    }

    [[ $1 = :u ]] && {

        [[ $cmds =~ I && $(tac "$(pacman-conf LogFile)" | grep -m1 upgraded) > [$(date -d -${update_interval}days +%F)U ]] || {
            atlas .echo q1 "scan for updates?"

            [[ ${REPLY,} = n ]] || {
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

    [[ $1 = :c ]] && {

        [[ $orphans ]] && {
            atlas .echo q1 "remove orphans?"

            [[ ${REPLY,} = n ]] || {
                atlas .await 1
                $auth pacman -Rns ${orphans[@]}
                atlas .await 0
                echo
            }
        :;} || atlas .echo i1 "no orphans to remove"

        local cache
        mapfile -t cache < <(pacman-conf CacheDir)
        local csize=$(du -bc "${cache[@]}" 2>/dev/null | tail -1 | cut -f1)

        [[ $cmds =~ I ]] && (( cache_limit<<30 > csize )) || {
            (( csize )) && {
                atlas .echo q1 "clear cache ($(numfmt --to=iec "$csize"))?"

                [[ ${REPLY,} = n ]] || {
                    atlas .await 1
                    yes | $auth pacman -Scc &>/dev/null
                    atlas .await 0
                    local csized=$(( csize - $(du -bc "${cache[@]}" 2>/dev/null | tail -1 | cut -f1) ))
                    atlas .echo a0 "cleared: $(numfmt --to=iec "$csized")"
                }
            :;} || atlas .echo i1 "cache is empty"
        }

    }

    [[ $1 = :s ]] && {

        mkdir -p "$save/supersede"

        [[ -w $save ]] && {
            printf "%s$n" ${root[@]} > "$save/root"
            printf "%s$n" ${apps[@]} > "$save/apps"
            printf "%s$n" ${orphans[@]} > "$save/orphans"

            local overwrites=( "$save/supersede"/*/ )

            [[ ! -d $overwrites || $cmds =~ I && $(date -r "$save/supersede" +%F) > $(date -d -${update_interval}days +%F) ]] || {
                atlas .echo q1 "sync overwrites?"
                [[ ${REPLY,} = n ]] || atlas .overwrite 0
            }

            atlas .echo i1 "saved"
        :;} || atlas .echo i0 "...? use a proper save path"

    }

    [[ $1 = :d ]] && {

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

    [[ $1 = :g ]] && {

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

                local overwrites=( "$save/supersede"/*/ )

                [[ -d $overwrites ]] && {
                    atlas .echo q1 "overwrite ${#overwrites[@]} $((( ${#overwrites[@]} - 1 )) && echo "destinations" || echo "destination")?"
                    [[ ${REPLY,} = n ]] || atlas .overwrite 1
                }

                atlas .echo a0 "all done, make sure there weren't any errors"
            }
        :;} || atlas .echo i0 "you forgot to save..."

    }

    [[ $1 = :x ]] && {

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

        local op=$2 say=$3

        [[ $op = a0 ]] && {
            echo "$bold「 $say 」$reset$n"
            atlas .emit a
        }

        [[ $op = a1 ]] && {
            echo -n "$origin$dim$say$reset$clear"
            [[ $cmds =~ Q ]] || read -t 0.3
        }

        [[ $op = i0 ]] && {
            echo "$red⚠︎ $say$reset$n"
            atlas .emit e
        }

        [[ $op = i1 && ! $cmds =~ I ]] && {
            echo "$dim∴ $say$reset$n"
            atlas .emit i
        }

        [[ $op = q0 ]] && {
            echo -n "$red⚠︎ $say {y/${bold}n$reset$red}$reset "
            atlas .emit w
            atlas .await 1
            read -s -n 1
            atlas .await 0
            echo -n "$r$clear"
        }

        [[ $op = q1 ]] && {
            echo -n "✧ $say {${bold}y$reset/n} "
            atlas .emit q
            atlas .await 1
            read -s -n 1
            atlas .await 0
            echo -n "$r$clear"
        }

    }

    [[ $1 = .emit ]] && {

        local op=$2
        local -A ids=( [a]=window-attention [e]=dialog-error [i]=dialog-information [q]=window-question [w]=dialog-warning )

        [[ $cmds =~ Q ]] || kill -0 ${async[emit]} 2>/dev/null || {
            canberra-gtk-play -i ${ids[$op]} &async[emit]=$!
            disown ${async[emit]}
        } &>/dev/null

    }

    [[ $1 = .extract ]] && {

        local pkg opt

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

    [[ $1 = .overwrite ]] && {

        local stage=$2 i dst

        atlas .await 1

        for i in "${overwrites[@]%/}"
        do
            dst=${i##*/}
            dst=${dst//:/\/}
            dst=${dst/#@/$HOME}

            [[ $dst = *+ ]] && {
                dst=${dst%+}

                (( stage )) && local from=$i to=$dst || local from=$dst to=$i

                $auth test -d "$from" && {
                    $auth rm -rf "$to"
                    mkdir -p "$to" 2>/dev/null || $auth mkdir -p "$to"
                    $auth cp -a "$from/." "$to"
                :;} || atlas .echo i1 "couldn't read $from"
            :;} || {
                (( ! stage )) || mkdir -p "$dst" 2>/dev/null || $auth mkdir -p "$dst"

                $auth find "$i" | while IFS= read -r oentry
                do
                    dentry=${oentry/$i/$dst}

                    (( stage )) && fentry=$oentry tentry=$dentry || fentry=$dentry tentry=$oentry

                    $auth stat "$fentry" &>/dev/null && {
                        $auth test -d "$tentry" && {
                            $auth chmod --reference="$fentry" "$tentry"
                            $auth chown --reference="$fentry" "$tentry"
                        :;} || {
                            $auth rm -rf "$tentry"
                            $auth cp -a "$fentry" "$tentry"
                        }
                    :;} || atlas .echo i1 "couldn't read $fentry"
                done
            }
        done

        atlas .await 0

        (( stage )) || touch "$save/supersede"

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

        local ops=$2

        modified[l1]=$(stat -c %Y "$(pacman-conf LogFile)")
        modified[f1]=$(stat -c %Y /var/lib/flatpak 2>/dev/null)

        [[ ${modified[l0]} = ${modified[l1]} ]] || {
            scanned=${scanned//[orl]}
            modified[l0]=${modified[l1]}
        }

        [[ ${modified[f0]} = ${modified[f1]} ]] || {
            scanned=${scanned//[ai]}
            modified[f0]=${modified[f1]}
        }

        ops=${ops/c/o}
        ops=${ops/r/orl}
        ops=${ops/[ds]/ior}
        ops=${ops//[$scanned]}
        scanned+=$ops

        atlas .pulse 1

        {
            [[ $ops =~ a ]] && {
                atlas .echo a1 "scanning apps..."
                mapfile -t appnames < <(flatpak list --app --columns=name)
            }

            [[ $ops =~ i ]] && {
                atlas .echo a1 "scanning app ids..."
                apps=( $(flatpak list --app --columns=app) )
            }

            [[ $ops =~ o ]] && {
                atlas .echo a1 "scanning orphans..."
                orphans=( $(pacman -Qqtd) )
            }

            [[ $ops =~ r ]] && {
                atlas .echo a1 "scanning root..."
                root=( $(grep -vxFf <(printf "%s$n" ${orphans[@]}) <(pacman -Qqtt)) )
            }

            [[ $ops =~ l && ! $cmds =~ Q ]] && {
                atlas .echo a1 "extracting lineage..."
                atlas .extract
            }
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
