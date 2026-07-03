# ┄┄───═════════════════════════════════════════════════════════════════════════════════ << A T L A S >> ═════════════════════════════════════════════════════════════════════════════════───┄┄ #

atlas() {

#  ╭── cortex ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮

    [[ $code = samsara ]] || {

        local cmds=$1 code=samsara auth=$(type -P sudo || type -P doas) save=$HOME/atlas/${2:-0}
        local bold=$'\e[1m' dim=$'\e[2m' red=$'\e[31m' reset=$'\e[m' hide=$'\e[?25l' show=$'\e[?25h' clear=$'\e[K' origin=$'\e[3G' n=$'\n' r=$'\r'
        local root appnames apps orphans scanned
        local -A async lineage modified null

        echo

        [[ $cmds ]] || cmds+=ra

        [[ ${cmds//[raidsgluc]} ]] && {
            [[ $cmds = \? ]] && {
                atlas .echo a0 "atlas syntax"
                echo " ╭───────────────────────────╮"
                echo " │ r  ·  view root           │"
                echo " │ a  ·  view apps           │"
                echo " │ i  ·  view app ids        │"
                echo " │ d  ·  view difference     │"
                echo " │ s  ·  save system         │"
                echo " │ g  ·  generate system     │"
                echo " │ l  ·  link generation     │"
                echo " │ u  ·  upgrade             │"
                echo " │ c  ·  cleanup             │"
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
        :;} || atlas .echo i1 "apps: none"

    }

    [[ $1 = :i ]] && {

        [[ $apps ]] && {
            echo "${bold}app ids (${#apps[@]})$reset"
            atlas .render apps null
        :;} || atlas .echo i1 "app ids: none"

    }

    [[ $1 = :d ]] && {

        [[ -d $save ]] && {
            local i
            local -A delta

            for i in root apps
            do
                local -n xarr=$i

                delta[${i}0]=$(grep -vxFf <(printf "%s$n" ${xarr[@]}) "$save/$i")
                delta[${i}1]=$(grep -vxFf "$save/$i" <(printf "%s$n" ${xarr[@]}))

                [[ ${delta[${i}0]}${delta[${i}1]} ]] && {
                    atlas .echo a0 "$i difference"
                    [[ ${delta[${i}0]} ]] && printf " $dim⊖ %s$reset$n" ${delta[${i}0]}
                    [[ ${delta[${i}1]} ]] && printf " ⊕ %s$n" ${delta[${i}1]}
                    echo
                :;} || [[ ! -f $save/$i ]] || atlas .echo i1 "$i difference: none"
            done 2>/dev/null
        :;} || atlas .echo i0 "you forgot to save silly"

    }

    [[ $1 = :s ]] && {

        mkdir -p "$save/supersede"
        printf "%s$n" ${root[@]} > "$save/root"
        printf "%s$n" ${apps[@]} > "$save/apps"

        local overwrites=( "$save/supersede"/*/ )

        [[ -d $overwrites ]] && {
            atlas .echo q1 "sync ${#overwrites[@]} $((( ${#overwrites[@]} - 1 )) && echo "overwrites" || echo "overwrite")? {${bold}y$reset/n}"
            [[ ${REPLY,} = n ]] || atlas .overwrite 0
        }

        atlas .echo i1 "saved"

    }

    [[ $1 = :g ]] && {

        [[ -d $save ]] && {
            atlas .echo q0 "set up aur and flatpak if you need, proceed? $red{y/${bold}n$reset$red}$reset"

            [[ ${REPLY,} = y ]] && {
                atlas .tty 1

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

                atlas .tty 0

                local overwrites=( "$save/supersede"/*/ )

                [[ -d $overwrites ]] && {
                    atlas .echo q1 "apply ${#overwrites[@]} $((( ${#overwrites[@]} - 1 )) && echo "overwrites" || echo "overwrite")? {${bold}y$reset/n}"
                    [[ ${REPLY,} = n ]] || atlas .overwrite 1
                }

                atlas .echo a0 "all done, make sure there weren't any errors"
            }
        :;} || atlas .echo i0 "you forgot to save..."

    }

    [[ $1 = :l ]] && {

        atlas .echo q1 "enter the generation path you want to link:"

        [[ $REPLY ]] && {
            mkdir -p "$save"
            cp -a "$REPLY/." "$save"
        }

    }

    [[ $1 = :u ]] && {

        atlas .tty 1

        $(type -P yay || type -P paru || echo "$auth pacman") -Syu
        echo

        [[ $(type -P flatpak) ]] && {
            flatpak update
            echo
        }

        atlas .tty 0

        local version=$(curl -fsS https://raw.githubusercontent.com/60-6/atlas/refs/heads/0/version)
        [[ $version && ! $code = $version ]] && atlas .echo a0 "a new version of atlas is available if you care, github.com/60-6/atlas"

    }

    [[ $1 = :c ]] && {

        [[ $orphans ]] && {
            echo "$red${bold}orphans (${#orphans[@]})$reset"
            atlas .render orphans null "$red"
            atlas .echo q1 "proceed with removal? {${bold}y$reset/n}"

            [[ ${REPLY,} = n ]] && {
                atlas .echo q1 "mark explicit instead? {${bold}y$reset/n}"

                [[ ${REPLY,} = n ]] || {
                    atlas .tty 1
                    $auth pacman -D --asexplicit ${orphans[@]}
                    atlas .tty 0
                    echo
                }
            :;} || {
                atlas .tty 1
                $auth pacman -Rns ${orphans[@]}
                atlas .tty 0
                echo
            }
        :;} || atlas .echo i1 "no orphans to remove"

        local cache
        mapfile -t cache < <(pacman-conf CacheDir)
        local csize=$(du -bc "${cache[@]}" 2>/dev/null | tail -1 | cut -f1)

        (( csize )) && {
            atlas .echo q1 "clear cache ($(numfmt --to=iec "$csize"))? {${bold}y$reset/n}"

            [[ ${REPLY,} = n ]] || {
                atlas .tty 1
                yes | $auth pacman -Scc &>/dev/null
                atlas .tty 0
                local csized=$(( csize - $(du -bc "${cache[@]}" 2>/dev/null | tail -1 | cut -f1) ))
                atlas .echo a0 "cleared: $(numfmt --to=iec "$csized")"
            }
        :;} || atlas .echo i1 "cache is empty"

        [[ $(type -P flatpak) ]] && {
            atlas .echo i1 "scanning unused runtimes..."
            flatpak remove --unused
            echo
        }

    }

#  ├── core ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    [[ $1 = .tty ]] && {

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
            read -t 0.3
        }

        [[ $op = i0 ]] && {
            echo "$red⚠︎ $say$reset$n"
            atlas .emit e
        }

        [[ $op = i1 ]] && {
            echo "$dim$say$reset$n"
            atlas .emit i
        }

        [[ $op = q0 ]] && {
            echo -n "$red⚠︎ $say$reset "
            atlas .emit w
            atlas .tty 1
            read
            atlas .tty 0
            echo
        }

        [[ $op = q1 ]] && {
            echo -n "✧ $say "
            atlas .emit q
            atlas .tty 1
            read
            atlas .tty 0
            echo
        }

    }

    [[ $1 = .emit ]] && {

        local op=$2
        local -A ids=( [a]=window-attention [e]=dialog-error [i]=dialog-information [q]=window-question [w]=dialog-warning )

        kill -0 ${async[emit]} 2>/dev/null || {
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

        local stage=$2 i target

        atlas .tty 1

        for i in "${overwrites[@]%/}"
        do
            target=${i##*/}
            target=${target//:/\/}
            target=${target/#@/$HOME}

            $auth find "$i" | while IFS= read -r oentry
            do
                tentry=${oentry/"$i"/$target}

                [[ $tentry = *+/* ]] || {
                    [[ $($auth stat -c %F "$oentry") = directory ]] && tentry=${tentry%+}
                    (( stage )) && src=$oentry dst=$tentry || src=$tentry dst=$oentry

                    $auth stat "$src" &>/dev/null && {
                        [[ $($auth stat -c %F "$src") = directory && ! $oentry = *+ ]] && {
                            [[ $($auth stat -c %F "$dst" 2>/dev/null) = directory ]] || $auth rm -f "$dst"
                            mkdir -p "$dst" 2>/dev/null || $auth mkdir -p "$dst"
                            $auth chmod --reference="$src" "$dst"
                            $auth chown --reference="$src" "$dst"
                        :;} || {
                            [[ ! ${dst%/*} ]] || mkdir -p "${dst%/*}" 2>/dev/null || $auth mkdir -p "${dst%/*}"
                            $auth rm -rf "$dst"
                            $auth cp -a "$src" "$dst"
                        }
                    :;} || atlas .echo i1 "couldn't read $src"
                }
            done
        done

        atlas .tty 0

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
                [[ $depth ]] || echo "$attr│"
                (( x )) || local xx=$([[ $depth ]] && echo ${#xarr[@]} || grep -cvxFf <(printf "%s$n" ${arr[@]}) <(printf "%s$n" "${xarr[@]}"))
                (( ++x == xx )) && local pfx="╰─ " indent="   " || local pfx="├─ " indent="│  "
                read -t 0.006
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
            scanned=${scanned//[reo]}
            modified[l0]=${modified[l1]}
        }

        [[ ${modified[f0]} = ${modified[f1]} ]] || {
            scanned=${scanned//[ai]}
            modified[f0]=${modified[f1]}
        }

        ops=${ops/r/re}
        ops=${ops/[ds]/ri}
        ops=${ops/c/o}
        ops=${ops//[$scanned]}
        scanned+=$ops

        atlas .pulse 1

        {
            [[ $ops =~ r ]] && {
                atlas .echo a1 "scanning root..."
                root=( $(pacman -Qqtte) )
            }

            [[ $ops =~ e ]] && {
                atlas .echo a1 "extracting lineage..."
                atlas .extract
            }

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
                orphans=( $(pacman -Qqttd) )
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
            atlas .tty 0
        :;} || {
            trap - 2 15
            atlas .tty 1
        }

    }

#  ╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯

}

# ┄┄───════════════════════════════════════════════════════════════════════════════════════ //  ▲  \\ ════════════════════════════════════════════════════════════════════════════════════───┄┄ #
