# ┄┄───═════════════════════════════════════════════════════════════════════════════════ << A T L A S >> ═════════════════════════════════════════════════════════════════════════════════───┄┄ #

atlas() {

#  ╭── cortex ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮

    [[ $code = samsara ]] || {

        local cmds=${1:-ra} save=$(realpath -m "$HOME/atlas/${2:-0}") auth=$(type -P sudo || type -P doas) code=samsara
        local bold=$'\e[1m' dim=$'\e[2m' red=$'\e[31m' reset=$'\e[m' hide=$'\e[?25l' show=$'\e[?25h' clear=$'\e[K' n=$'\n' r=$'\r'
        local root appnames apps orphans scanned REPLY
        local -A async lineage modified null

        echo

        [[ ${cmds//[raisgdeuc]} ]] && {
            [[ $cmds = \? ]] && {
                atlas .echo i1 "atlas syntax"
                echo " ╭───────────────────────────╮"
                echo " │ r  ·  view root           │"
                echo " │ a  ·  view apps           │"
                echo " │ i  ·  view app ids        │"
                echo " │ s  ·  save system         │"
                echo " │ g  ·  generate system     │"
                echo " │ d  ·  view difference     │"
                echo " │ e  ·  export generation   │"
                echo " │ u  ·  upgrade             │"
                echo " │ c  ·  cleanup             │"
                echo " ╰───────────────────────────╯$n"
            :;} || atlas .echo i0 "not sure what you mean, see 'atlas ?' for syntax"
        :;} || {
            atlas .signal 1
            atlas .scan $cmds
            local i

            for i in $(fold -w1 <<< $cmds)
            do
                atlas .scan $i
                atlas :$i
            done

            atlas .signal 0
        }

        echo

    }

#  ├── operations ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    [[ $1 = :r ]] && {

        atlas .render "root" root lineage

    }

    [[ $1 = :a ]] && {

        atlas .render "apps" appnames null

    }

    [[ $1 = :i ]] && {

        atlas .render "app ids" apps null

    }

    [[ $1 = :s ]] && {

        mkdir -p "$save/supersede"
        printf "%s$n" ${root[@]} > "$save/root"
        printf "%s$n" ${apps[@]} > "$save/apps"
        local overwrites=( "$save/supersede/"* )

        stat "$overwrites" &>/dev/null && {
            atlas .echo q1 "sync overwrites?"
            [[ ${REPLY,} = n ]] || atlas .overwrite 0
            atlas .tty 0
        }

        atlas .echo i2 "saved"

    }

    [[ $1 = :g ]] && {

        [[ -d $save ]] && {
            atlas .echo q0 "set up aur and flatpak if you need, proceed?"

            [[ ${REPLY,} = y ]] && {
                [[ -f "$save/root" ]] && $(type -P yay || type -P paru || echo "$auth pacman") -S --needed $(< "$save/root") && {
                    $auth pacman -D --asdeps $(pacman -Qqe)
                    $auth pacman -D --asexplicit $(< "$save/root")
                    local rdelta=$(pacman -Qqttd)
                    [[ $rdelta ]] && $auth pacman -Rns $rdelta
                    echo
                }

                [[ -f "$save/apps" && $(type -P flatpak) ]] && {
                    [[ $(< "$save/apps") ]] && flatpak install $(< "$save/apps")
                    local adelta=$(grep -vxFf "$save/apps" <(flatpak list --app --columns=app))
                    [[ $adelta ]] && flatpak remove $adelta
                    flatpak remove --unused
                    echo
                }

                local overwrites=( "$save/supersede/"* )

                stat "$overwrites" &>/dev/null && {
                    atlas .echo q1 "apply overwrites?"
                    [[ ${REPLY,} = n ]] || atlas .overwrite 1
                }

                atlas .echo i1 "all done, make sure there weren't any errors"
            }

            atlas .tty 0
        :;} || atlas .echo i0 "you forgot to save..."

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
                    atlas .echo i1 "$i difference"
                    [[ ${delta[${i}0]} ]] && printf " $dim⊖ %s$reset$n" ${delta[${i}0]}
                    [[ ${delta[${i}1]} ]] && printf " ⊕ %s$n" ${delta[${i}1]}
                    echo
                :;} || [[ ! -f $save/$i ]] || atlas .echo i2 "$i difference: none"
            done 2>/dev/null
        :;} || atlas .echo i0 "you forgot to save silly"

    }

    [[ $1 = :e ]] && {

        atlas .echo q2 "which generation path do you want to export?"

        [[ $REPLY ]] && {
            local src=$(realpath -m "$REPLY")

            $auth stat "$src" &>/dev/null && {
                atlas .echo q2 "where do you want to export it?"

                [[ $REPLY ]] && {
                    local dst=$(realpath -m "$REPLY")

                    [[ ! $src/ = "${dst%/}/"* && ! $dst = "${src%/}/"* ]] && {
                        [[ ! ${dst%/*} ]] || mkdir -p "${dst%/*}" 2>/dev/null || $auth mkdir -p "${dst%/*}"
                        $auth cp -a "$src" "$dst" && atlas .echo i2 "exported successfully"
                    :;} || atlas .echo i0 "invalid path, recursion detected"
                }
            :;} || atlas .echo i0 "invalid path"
        }

        atlas .tty 0

    }

    [[ $1 = :u ]] && {

        atlas .tty 1
        $(type -P yay || type -P paru || echo "$auth pacman") -Syu
        [[ $(type -P flatpak) ]] && flatpak update
        echo
        atlas .tty 0
        local version=$(curl -fsS https://raw.githubusercontent.com/60-6/atlas/refs/heads/0/version)
        [[ $version && ! $code = $version ]] && atlas .echo i1 "a new version of atlas is available if you care, github.com/60-6/atlas"

    }

    [[ $1 = :c ]] && {

        [[ $orphans ]] && {
            atlas .render "orphans" orphans null "$red"
            atlas .echo q1 "proceed with removal?"

            [[ ${REPLY,} = n ]] && {
                atlas .echo q1 "mark explicit instead?"

                [[ ${REPLY,} = n ]] || {
                    $auth pacman -D --asexplicit ${orphans[@]}
                    echo
                }
            :;} || {
                $auth pacman -Rns ${orphans[@]}
                echo
            }
        :;} || atlas .echo i2 "no orphans to remove"

        local cache
        mapfile -t cache < <(pacman-conf CacheDir)
        local csize=$(du -bc "${cache[@]}" 2>/dev/null | tail -1 | cut -f1)

        (( csize )) && {
            atlas .echo q1 "clear cache ($(numfmt --to=iec "$csize"))?"

            [[ ${REPLY,} = n ]] || {
                yes | $auth pacman -Scc &>/dev/null
                local csized=$(( csize - $(du -bc "${cache[@]}" 2>/dev/null | tail -1 | cut -f1) ))
                atlas .echo i2 "cleared: $(numfmt --to=iec "$csized")"
            }
        :;} || atlas .echo i2 "cache is empty"

        [[ $(type -P flatpak) ]] && {
            flatpak remove --unused
            echo
        }

        atlas .tty 0

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

        [[ $op = i0 ]] && {
            echo "$red⚠︎ $say$reset$n"
            atlas .emit e
        }

        [[ $op = i1 ]] && {
            echo "$bold「 $say 」$reset$n"
            atlas .emit i
        }

        [[ $op = i2 ]] && {
            echo "$dim$say$reset$n"
            atlas .emit i
        }

        [[ $op = q0 ]] && {
            echo -n "$red⚠︎ $say {y/${bold}n$reset$red}$reset "
            atlas .emit w
            atlas .tty 1
            read -sn 1
            echo -n "$r$clear"
        }

        [[ $op = q1 ]] && {
            echo -n "✧ $say {${bold}y$reset/n} "
            atlas .emit i
            atlas .tty 1
            read -sn 1
            echo -n "$r$clear"
        }

        [[ $op = q2 ]] && {
            echo -n "$say "
            atlas .emit i
            atlas .tty 1
            read
            echo
        }

    }

    [[ $1 = .emit ]] && {

        local op=$2
        local -A ids=( [e]=dialog-error [i]=dialog-information [w]=dialog-warning )

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

        for i in "${overwrites[@]}"
        do
            target=${i##*/}
            target=${target//:/\/}
            target=$(realpath -m "${target/#@/$HOME}")

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
                            [[ ! $oentry = "${tentry%/}/"* ]] && {
                                [[ ! ${dst%/*} ]] || mkdir -p "${dst%/*}" 2>/dev/null || $auth mkdir -p "${dst%/*}"
                                $auth rm -rf "$dst"
                                $auth cp -a "$src" "$dst"
                            :;} || atlas .echo i0 "recursion detected: $oentry"
                        }
                    :;} || atlas .echo i2 "couldn't read $src"
                }
            done
        done

    }

    [[ $1 = .pulse ]] && {

        local stage=$2

        (( stage )) && {
            while :
            do
                for i in ◟ ◜ ◝ ◞ ○ ◉ ● ◉ ○
                do
                    echo -n "$r$bold$i atlas: scanning...$reset"
                    sleep .06
                done
            done &async[pulse]=$!
        :;} 2>/dev/null || {
            kill ${async[pulse]}
            wait "${async[pulse]}"
            echo -n "$r$clear"
        } 2>/dev/null

    }

    [[ $1 = .render ]] && {

        local say=$2 xarrn=$3 arrn=$4 attr=$5 depth=$6 i x
        local -n xarr=$xarrn arr=$arrn
        [[ $say ]] && echo "$attr$bold$say (${#xarr[@]})$reset"

        for i in "${xarr[@]}"
        do
            [[ ! $depth && ${arr[@]} =~ " $i " ]] || {
                [[ $depth ]] || echo "$attr│"
                (( x )) || local xx=$([[ $depth ]] && echo ${#xarr[@]} || grep -cvxFf <(printf "%s$n" ${arr[@]}) <(printf "%s$n" "${xarr[@]}"))
                (( ++x == xx )) && local pfx="╰─ " indent="   " || local pfx="├─ " indent="│  "
                read -t .006
                echo "$attr$depth$pfx$i$reset"
                local children=( ${arr[$i]} )
                atlas .render "" children $arrn "$attr" "$depth$indent$dim"
            }
        done

        [[ $depth ]] || echo

    }

    [[ $1 = .scan ]] && {

        local ops=$2
        modified[l1]=$(stat -c %Y "$(pacman-conf LogFile)")
        modified[f1]=$(stat -c %Y /var/lib/flatpak 2>/dev/null)

        [[ ${modified[l0]} = ${modified[l1]} ]] || {
            scanned=${scanned//[rlo]}
            modified[l0]=${modified[l1]}
        }

        [[ ${modified[f0]} = ${modified[f1]} ]] || {
            scanned=${scanned//[ai]}
            modified[f0]=${modified[f1]}
        }

        ops=${ops/r/rl}
        ops=${ops/c/o}
        ops=${ops/[ds]/ri}
        ops=${ops//[$scanned]}
        scanned+=$ops

        [[ ${ops//[!rloai]} ]] && {
            atlas .pulse 1
            [[ $ops =~ r ]] && root=( $(pacman -Qqtte) )
            [[ $ops =~ l ]] && atlas .extract
            [[ $ops =~ o ]] && orphans=( $(pacman -Qqttd) )
            [[ $ops =~ a ]] && mapfile -t appnames < <(flatpak list --app --columns=name)
            [[ $ops =~ i ]] && apps=( $(flatpak list --app --columns=app) )
            read -t .6
            atlas .pulse 0
        } 2>/dev/null
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
