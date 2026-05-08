# ────────────────────────────────────────────────────────────────────── << A T L A S >> ────────────────────────────────────────────────────── \\  ▼  // ──────┐

atlas() {

#  ┌── configuration ────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐

    {
        local default_commands=irfosudc
        local update_interval=3
        local cache_limit=5

        local pacman_path="/var/log/pacman.log"
        local flatpak_path="/var/lib/flatpak"
        local save_path="/tmp/atlas"
        local cache_path="/var/cache/pacman/pkg"
    }

#  ├── execution ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    (( executing )) || {
        local executing=1 cmds=$1
        local bold=$'\e[1m' dim=$'\e[2m' red=$'\e[31m' reset=$'\e[m' n=$'\n' r=$'\r' c=$'\e[K' h=$'\e[?25l' s=$'\e[?25h' o=$'\e[7G'

        local children csize flatpaks i ii indent log opt orphans pfx pkg pulse root
        local -A delta modified null rlineage

        echo
        atlas .resolve
        atlas .dispatch
        echo
    }

#  ├── cortex ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

    [[ $1 = .resolve ]] && {
        [[ $(command -v pacman) ]] || {
            echo "you're not even using arch silly$n"
            atlas .suicide
        }

        [[ $cmds =~ \? ]] && atlas .error s
        [[ $cmds =~ [^-qyirfosudcx] ]] && atlas .error c
        [[ ${cmds//[qyi]} ]] || cmds+=$default_commands
    }

    [[ $1 = .dispatch ]] && {
        atlas .signal 1

        atlas .scan $cmds
        for i in $(fold -w1 <<< $cmds)
        do
            atlas .scan $i
            atlas .$i
        done

        atlas .signal 0
    }

#  ├── operations ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

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
            atlas .render orphans null $red
        :;} || {
            [[ $cmds =~ i ]] || echo "${dim}orphans: nil$reset$n"
        }
    }

    [[ $1 = .s ]] && {
        {
            mkdir -p "$save_path"

            printf "%s$n" "${root[@]}">"$save_path/root"
            printf "%s$n" "${flatpaks[@]}">"$save_path/flatpaks"
            printf "%s$n" "${orphans[@]}">"$save_path/orphans"
        } 2>/dev/null

        [[ -w $save_path ]] && {
            [[ $cmds =~ i ]] || echo "${dim}saved$reset$n"
        :;} || echo "${red}invalid save path$reset$n"
    }

    [[ $1 = .u ]] && {
        [[ $cmds =~ i && $(tac $pacman_path 2>/dev/null | grep -m1 "upgraded") > [$(date -d -${update_interval}days +%F) ]] || {
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
                local -n arr=$i

                {
                    delta[${i}0]=$(grep -vxf <(printf "%s$n" "${arr[@]}") "$save_path/$i")
                    delta[${i}1]=$(grep -vxf "$save_path/$i" <(printf "%s$n" "${arr[@]}"))
                } 2>/dev/null

                [[ ${delta[${i}0]}${delta[${i}1]} ]] && {
                    echo "${bold}$i difference ▼$reset"
                    [[ ${delta[${i}0]} ]] && echo "$red${delta[${i}0]}$reset"
                    [[ ${delta[${i}1]} ]] && echo "${delta[${i}1]}"
                    echo
                }
            done

            [[ $cmds =~ i || ${delta[@]} =~ [^\ ] ]] || echo "${dim}delta: nil$reset$n"
        :;} ||{
            echo "${red}no save found$reset$n"
        }
    }

    [[ $1 = .c ]] && {
        [[ $orphans ]] && {
            atlas .await 2 "remove orphans? (y/${bold}n$reset) "

            [[ ${REPLY,,} = y ]] && {
                sudo pacman -Rns ${orphans[@]}
                echo
            }
        :;} || {
            [[ $cmds =~ i ]] || echo "${dim}no orphans to remove$reset$n"
        }

        csize=$(du -sh $cache_path 2>/dev/null | cut -f1)

        {
            [[ $csize ]] && (( $(numfmt --from=iec $csize) > cache_limit<<30 )) || [[ ! $cmds =~ i ]]
        } && {
            [[ $csize ]] || csize="?"

            atlas .await 2 "clear package cache [$csize]? (y/${bold}n$reset) "

            [[ ${REPLY,,} = y ]] && {
                yes | sudo pacman -Scc &>/dev/null
                csize=$(du -sh $cache_path 2>/dev/null | cut -f1)
                [[ $csize ]] && echo "${dim}new cache size: $csize$reset$n"
            }
        }
    }

    [[ $1 = .x ]] && {
        atlas .await 2 "are you sure? (y/${bold}n$reset) "

        [[ ${REPLY,,} = y ]] && atlas .suicide
    }

#  ├── engine ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

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
                echo "$r$red> atlas: terminated ⚠$reset$c"
                kill -2 $$
            ' 2 15
        }
    }

    [[ $1 = .scan ]] && {
        local sops=$2

        [[ $sops =~ r && ! $cmds =~ q ]] && sops+=R
        [[ $sops =~ s ]] && sops+=rfo
        [[ $sops =~ d && -f $save_path/root ]] && sops+=rfo
        [[ $sops =~ c ]] && sops+=o

        {
            modified[p1]=$(stat -c %Y $pacman_path)
            modified[f1]=$(stat -c %Y $flatpak_path)
        } 2>/dev/null

        [[ ${modified[p0]} && ${modified[p0]} = ${modified[p1]} ]] || {
            log=${log//[roR]}
            modified[p0]=${modified[p1]}
        }

        [[ ${modified[f0]} && ${modified[f0]} = ${modified[f1]} ]] || {
            log=${log//f}
            modified[f0]=${modified[f1]}
        }

        sops=${sops//[$log]}
        log+=$sops

        atlas .pulse 1

        {
            [[ $sops =~ [ro] ]] && {
                echo -n "$o${dim}atlas: scanning orphans…$reset"
                orphans=( $(pacman -Qqtd) )
            }

            [[ $sops =~ r ]] && {
                echo -n "$o${dim}atlas: scanning root…$reset$c"
                root=( $(grep -vxf <(printf "%s$n" "${orphans[@]}") <(pacman -Qqtt)) )
            }

            [[ $sops =~ f ]] && {
                echo -n "$o${dim}atlas: scanning flatpaks…$reset$c"
                mapfile -t flatpaks < <(flatpak list --app --columns=name)
            }

            atlas .extract $sops
        } 2>/dev/null

        atlas .pulse 0
    }

    [[ $1 = .pulse ]] && {
        local stage=$2

        (( stage )) || {
            echo -n "$r$c"
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
        local ecmds=$2

        [[ $ecmds =~ R ]] && {
            rlineage=()

            while read pkg opt
            do [[ " ${root[@]} " =~ " $opt " ]] && rlineage[$pkg]+="$opt "
            done < <(LC_ALL=C pacman -Qi ${root[@]} | awk '
                proceed && /^ / {
                    gsub(/^ +|:.*/, "")
                    print pkg, $0
                next}

                proceed = 0

                /^Name/ {
                    pkg = $NF
                next}

                /^Optional Deps/ {
                    gsub(/^Optional Deps *: *|:.*/, "")
                    print pkg, $0
                    proceed = 1
                }
            ')
        }
    }

    [[ $1 = .render ]] && {
        local arrn=$2 assocan=$3 attr=$4 depth=$5

        local -n arr=$arrn assoca=$assocan
        local i=1 ii=${#arr[@]}

        for pkg in "${arr[@]}"
        do
            [[ $cmds =~ q ]] || {
                [[ $depth ]] || {
                    [[ " ${assoca[@]} " =~ " $pkg " ]] && {
                        ((ii--))
                    continue;}

                    echo "$attr│"
                }

                (( i == ii )) && {
                    pfx="└─ "
                    indent="   "
                } || {
                    pfx="├─ "
                    indent="│  "
                }

                ((i++))
            }

            echo "$attr$depth$pfx$pkg$reset"

            children=( ${assoca[$pkg]} )
            atlas .render children "$assocan" "$attr" "$depth$indent$dim"
        done

        [[ $depth ]] || echo
    }

    [[ $1 = .await ]] && {
        local stage=$2 prompt=$3

        (( stage )) || {
            stty -echo
            echo -n $h
        }

        (( stage )) && {
            echo -n $s
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

        [[ $mode = c ]] && echo "invalid command, see 'atlas ?' for syntax"

        [[ $mode = s ]] && {
            echo  $bold  " ▼ atlas syntax"
            echo  $reset
            echo         "  ┌── modifiers ──────────────┐"
            echo         "  │ q  ·  quiet output        │"
            echo         "  │ y  ·  auto confirm        │"
            echo         "  │ i  ·  intelligent mode    │"
            echo         "  └───────────────────────────┘"
            echo
            echo         "  ┌── operations ─────────────┐"
            echo         "  │ r  ·  view root           │"
            echo         "  │ f  ·  view flatpaks       │"
            echo         "  │ o  ·  view orphans        │"
            echo         "  │ s  ·  save system state   │"
            echo         "  │ u  ·  upgrade system      │"
            echo         "  │ d  ·  view difference     │"
            echo         "  │ c  ·  system cleanup      │"
            echo         "  │ x  ·  erase atlas         │"
            echo         "  └───────────────────────────┘"
        }

        echo

        kill -2 $$
    }

    [[ $1 = .suicide ]] && {
        {
            rm -r $save_path
            grep -q ' //  ▲  \\\\ ' "$BASH_SOURCE" && sed -i '\| \\\\  ▼  // |, \| //  ▲  \\\\ | d' "$BASH_SOURCE"
        } 2>/dev/null

        grep -q 'atlas()' "$BASH_SOURCE" && echo "${red}remove atlas from $BASH_SOURCE$reset" || echo "${dim}bye$reset"
        echo

        atlas .signal 0
        unset -f atlas
        kill -2 $$
    }

#  └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

}

# ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── //  ▲  \\ ──────┘
