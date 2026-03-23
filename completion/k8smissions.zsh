# K8sMissions oh-my-zsh / zsh completion
#
# ── INSTALL (one-time) ────────────────────────────────────────────────────────
# Add ONE of these blocks to your ~/.zshrc (after the `source oh-my-zsh.sh` line):
#
# Option A — alias (recommended, works immediately):
#   alias k8sm="/path/to/k8smissions/play.sh"
#   source /path/to/k8smissions/completion/k8smissions.zsh
#
# Option B — oh-my-zsh custom completions directory:
#   ln -sf /path/to/k8smissions/completion/k8smissions.zsh \
#           ~/.oh-my-zsh/completions/_k8smissions
#   # Then restart your shell or run: exec zsh
# ─────────────────────────────────────────────────────────────────────────────

_k8smissions_cmds=(
    'check:Run the validator — confirm your fix works'
    'check-dry:Dry-run validator (shows result, no XP awarded)'
    'watch:Auto-run validator every 5s until it passes'
    'hint:Reveal the next progressive hint (up to 3)'
    'guide:Show the full walkthrough / solution.yaml'
    'debrief:Re-read the lesson for this level'
    'reset:Rebuild the broken scenario from scratch'
    'status:Show XP progress across all worlds'
    'skip:Advance to next level (no XP awarded)'
    'quit:Save progress and exit'
    'reset-progress:Wipe all XP and restart from World 1 Level 1'
    'safety:Show kubectl safety guard rules'
    'help:Show command reference'
    'kubectl:Pass a kubectl command through safety guards'
)

_k8smissions() {
    local curcontext="$curcontext" state state_descr line
    typeset -A opt_args

    _arguments -C \
        '(- *)--reset[Reset all progress and start over]' \
        '1: :->cmd' \
        '*:: :->args'

    case $state in
        cmd)
            _describe -t commands 'k8smissions command' _k8smissions_cmds
            ;;
        args)
            case $line[1] in
                kubectl)
                    if (( $+functions[_kubectl] )); then
                        words=(kubectl "${words[@]:1}")
                        (( CURRENT++ ))
                        _kubectl
                    else
                        _message 'kubectl arguments (install kubectl for full completion)'
                    fi
                    ;;
            esac
            ;;
    esac
}

# Bind to both the alias name and direct script invocations
if (( $+commands[k8sm] )); then
    compdef _k8smissions k8sm
fi
compdef _k8smissions play.sh 2>/dev/null || true
