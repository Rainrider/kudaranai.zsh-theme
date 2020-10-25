#!/usr/bin/env zsh

# kudaranai.zsh-theme

KU_SEPARATOR="%{$fg[white]%}く%{$reset_color%}"

ZSH_THEME_GIT_PROMPT_PREFIX="${KU_SEPARATOR} %{$fg[magenta]%}git:"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"

# status compared to remote
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg_bold[green]%}↑"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg_bold[red]%}↓"
ZSH_THEME_GIT_PROMPT_DIVERGED="%{$fg_bold[red]%}⇅"

# local status
ZSH_THEME_GIT_PROMPT_ADDED="%{$fg_bold[green]%}+"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg_bold[red]%}-"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg_bold[yellow]%}~"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg_bold[magenta]%}~"
ZSH_THEME_GIT_PROMPT_STASHED="%{$fg_bold[blue]%}$"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg_bold[yellow]%}≠"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg_bold[white]%}?"

# Format for git_prompt_long_sha() and git_prompt_short_sha()
ZSH_THEME_GIT_PROMPT_SHA_BEFORE="%{$fg_bold[yellow]%}"
ZSH_THEME_GIT_PROMPT_SHA_AFTER="%{$reset_color%}"

function theme_prompt_status() {
	local exit_code=$?
	local -a symbols

	[[ $exit_code -ne 0 ]] && symbols+="%{$fg_bold[red]%}×"
	[[ $UID -eq 0 ]] && symbols+="%{$fg_bold[yellow]%}⚡"
	[[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{$fg_bold[cyan]%}☼"

	[[ -n "$symbols" ]] && echo "$symbols%{$reset_color%} "
}

function theme_git_status() {
	[[ "$(__git_prompt_git config --get oh-my-zsh.hide-status 2>/dev/null)" = 1 ]] && return

	# Maps a git status prefix to an internal constant
	# This cannot use the prompt constants, as they may be empty
	local -A prefix_constant_map
	prefix_constant_map=(
		'\?\? '     'UNTRACKED'
		'A  '       'ADDED'
		'M  '       'ADDED'
		'MM '       'ADDED'
		' M '       'MODIFIED'
		'AM '       'MODIFIED'
		' T '       'MODIFIED'
		'R  '       'RENAMED'
		' D '       'DELETED'
		'D  '       'DELETED'
		'UU '       'UNMERGED'
		'ahead'     'AHEAD'
		'behind'    'BEHIND'
		'diverged'  'DIVERGED'
		'stashed'   'STASHED'
	)

	# Maps the internal constant to the prompt theme
	local -A constant_prompt_map
	constant_prompt_map=(
		'UNTRACKED' "$ZSH_THEME_GIT_PROMPT_UNTRACKED"
		'ADDED'     "$ZSH_THEME_GIT_PROMPT_ADDED"
		'MODIFIED'  "$ZSH_THEME_GIT_PROMPT_MODIFIED"
		'RENAMED'   "$ZSH_THEME_GIT_PROMPT_RENAMED"
		'DELETED'   "$ZSH_THEME_GIT_PROMPT_DELETED"
		'UNMERGED'  "$ZSH_THEME_GIT_PROMPT_UNMERGED"
		'AHEAD'     "$ZSH_THEME_GIT_PROMPT_AHEAD"
		'BEHIND'    "$ZSH_THEME_GIT_PROMPT_BEHIND"
		'DIVERGED'  "$ZSH_THEME_GIT_PROMPT_DIVERGED"
		'STASHED'   "$ZSH_THEME_GIT_PROMPT_STASHED"
	)

	# The order that the prompt displays should be added to the prompt
	local status_constants
	status_constants=(
		DIVERGED BEHIND AHEAD UNMERGED STASHED
		DELETED RENAMED MODIFIED ADDED UNTRACKED
	)

	local status_text="$(__git_prompt_git status --porcelain -b 2> /dev/null)"

	# Don't continue on a catastrophic failure
	if [[ $? -eq 128 ]]; then
		return 1
	fi

	# A lookup table of each git status encountered
	local -A statuses_seen

	local stashes="$(__git_prompt_git rev-list --walk-reflogs --count refs/stash 2> /dev/null)"
	[[ "$stashes" -gt 0 ]] && statuses_seen[STASHED]="$stashes"

	local status_lines
	status_lines=("${(@f)${status_text}}")

	# If the tracking line exists, get and parse it
	if [[ "$status_lines[1]" =~ "^## [^ ]+ \[(.*)\]" ]]; then
		local branch_statuses
		branch_statuses=("${(@s/,/)match}")
		for branch_status in $branch_statuses; do
			if [[ ! $branch_status =~ "(behind|diverged|ahead) ([0-9]+)?" ]]; then
				continue
			fi
			local last_parsed_status=$prefix_constant_map[$match[1]]
			statuses_seen[$last_parsed_status]=$match[2]
		done
	fi

	for line in $status_lines; do
		# For each status prefix, do a regex comparison
		for status_prefix in ${(k)prefix_constant_map}; do
			local status_constant="${prefix_constant_map[$status_prefix]}"
			local status_regex=$'(^|\n)'"$status_prefix"

			if [[ "$line" =~ $status_regex ]]; then
				statuses_seen[$status_constant]=$(( statuses_seen[$status_constant] + 1 ))
				continue
			fi
		done
	done

	# Display the seen statuses in the order specified
	local -a status_prompt
	for status_constant in $status_constants; do
		if (( ${+statuses_seen[$status_constant]} )); then
			local next_display="$constant_prompt_map[$status_constant]$statuses_seen[$status_constant]"
			status_prompt+="$next_display"
		fi
	done

	echo $status_prompt
}

function theme_prompt_char() {
	echo "%{$fg[red]%}❯%{$fg[yellow]%}❯%{$fg[green]%}❯%{$reset_color%}"
}

function theme_git_info() {
	local ref
	ref=$(__git_prompt_git symbolic-ref HEAD 2> /dev/null) || \
	ref=$(__git_prompt_git rev-parse --short HEAD 2> /dev/null) || return 0

	local symbol
	if [[ -n "$(__git_prompt_git rev-parse --abbrev-ref --symbolic-full-name @{u} 2> /dev/null)" ]]; then
		symbol="\uE0A0 "
	fi

	echo "$ZSH_THEME_GIT_PROMPT_PREFIX${symbol}${ref#refs/heads/}$ZSH_THEME_GIT_PROMPT_SUFFIX"
}

function theme_git_prompt() {
	echo "$(theme_git_info) $(git_prompt_remote) $(theme_git_status)"
}


PROMPT='
$(theme_prompt_status)%{$fg[green]%}%m%{$reset_color%} ${KU_SEPARATOR} %{$fg[red]%}%(5~|%-1~/…/%3~|%4~)%{$reset_color%} $(theme_git_prompt)
$(theme_prompt_char) '

RPROMPT=''
