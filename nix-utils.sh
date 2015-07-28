#!/usr/bin/env bash

Color_Off='\e[0m'
Red='\e[0;31m'
Yellow='\e[0;33m'
Green='\e[0;32m'

#
# Print on stderr, in red
#
stderr() {
    echo -e "${Red}[$(basename $0)]: ${*}${Color_Off}" >&2
}

#
# Print debugging output on stderr, in green
#
dbg() {
    [[ $DEBUG -eq 1 ]] && \
        echo -e "${Green}[DEBUG][$(basename $0)]: ${*}${Color_Off}" >&2
}

#
# Print on stdout, if verbosity is enabled, prefix in green
#
stdout() {
    [[ $VERBOSE -eq 1 ]] && echo -e "${Green}[$(basename $0)]:${Color_Off} $*"
}

#
# Get the command name from a script path
#
scriptname_to_command() {
        echo "$1" | sed 's,^\.\/nix-script-,,' | sed 's,\.sh$,,' | \
            sed -r "s,$(dirname ${BASH_SOURCE[0]})/nix-script-,,"
}

#
# Generate a help synopsis text
#
help_synopsis() {
    SCRIPT=$(scriptname_to_command $1); shift
    echo "usage: nix-script $SCRIPT $*"
}

#
# generate a help text footnote
#
help_end() {
    echo -e "\tAdding '-v' before the '$1' command turns on verbosity"
    echo -e ""
    echo -e "\tReleased under terms of GPLv2"
    echo -e "\t(c) 2015 Matthias Beyer"
    echo ""
}

#
# Explain the next command
#
explain() {
    stdout "$*"
    $*
}

#
# Helper for greping the current generation
#
grep_generation() {
    $* | grep current | sed -r 's,\s*([0-9]*)(.*),\1,'
}

#
# get the current system generation
#
current_system_generation() {
    grep_generation "sudo nix-env -p /nix/var/nix/profiles/system --list-generations"
}

#
# get the current user generation
#
current_user_generation() {
    grep_generation "nix-env --list-generations"
}

#
# Ask the user whether to continue or not
#
continue_question() {
	local answer
	echo -ne "${Yellow}$1 [yN]?:${Color_Off} " >&2
	read answer
		echo ""
	[[ "${answer}" =~ ^[Yy]$ ]] || return 1
}

#
# Ask whether a command should be executed or not.
#
ask_execute() {
    q="$1"; shift
	local answer
	echo -ne "${Yellow}$q${Color_Off} [Yn]? "
	read answer; echo
	[[ ! "${answer}" =~ ^[Nn]$ ]] && eval $*
}

#
# Check whether the passed path is a git reposity (simple test)
#
is_git_repo() {
    [[ -d "$1" ]] && [[ -d "$1/.git" ]]
}

#
# Helper for executing git commands in another git directory
#
__git() {
    DIR=$1; shift
    explain git --git-dir="$DIR/.git" --work-tree="$DIR" $*
}

# Gets the current branch name or the hash of the current rev if there is no
# branch
__git_current_branch() {
    branch_name=$(git symbolic-ref -q HEAD)
    branch_name=${branch_name##refs/heads/}
    ([[ -z "$branch_name" ]] && git rev-parse HEAD) || echo $branch_name
}
