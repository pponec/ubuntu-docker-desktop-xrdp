# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# append to the history file, don't overwrite it
shopt -s histappend
shopt -s checkwinsize

# System environment variables:
export TIME_STYLE=long-iso
HISTSIZE=1000
HISTFILESIZE=2000

function date  { date='date +%Y-%m-%dT%H:%M:%S%z' "$@" ;}
function grepf { find . -type f -name "$2" -exec grep -lnH "$1" {} + ;}
function l  { ls -l "$@" ;}
function ll { ls -alF "$@" ;}
function lt { ls -lt "$@" | head -n30; }
function mkd { mkdir $1 && cd $1; }
function q   { exit ;}
function version { cat /etc/os-release ;}