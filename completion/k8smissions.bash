#!/usr/bin/env bash
# K8sMissions bash completion
# Install: source /path/to/k8smissions/completion/k8smissions.bash
#   or add to ~/.bashrc:  source ~/path/to/k8smissions/completion/k8smissions.bash

_k8smissions_commands=(
    check
    check-dry
    watch
    hint
    guide
    debrief
    reset
    status
    skip
    quit
    exit
    reset-progress
    safety
    help
    kubectl
)

_k8smissions_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Complete play.sh arguments
    if [[ "${COMP_WORDS[0]}" == *play.sh* ]]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "--reset" -- "$cur"))
            return
        fi
        return
    fi

    # Complete in-game commands (when used as a script wrapper)
    COMPREPLY=($(compgen -W "${_k8smissions_commands[*]}" -- "$cur"))
}

complete -F _k8smissions_completions play.sh
complete -F _k8smissions_completions ./play.sh
