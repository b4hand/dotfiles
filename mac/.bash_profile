export EDITOR="emacs -nw --no-desktop"
export VISUAL=emacs

export HISTCONTROL=ignoreboth

export LESSOPEN="|lesspipe.sh %s"

export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:/usr/local/opt/coreutils/libexec/gnubin:$PATH"
export MANPATH="/usr/local/opt/gnu-sed/libexec/gnuman:/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

export PS1="\u@\h:\w\$ "

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

if [ -f `brew --prefix`/etc/bash_completion ]; then
    . `brew --prefix`/etc/bash_completion
fi

if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

for key in $(
    grep IdentityFile ~/.ssh/config |
    egrep -v '^\s*#\s*IdentityFile' |
    sed "s#~#$HOME#" |
    awk '{print $2}'); do ssh-add $key 2> /dev/null; done

export RBENV_ROOT=/usr/local/var/rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

export JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK/Home/

# Customize path to include a bunch of local utilities
export PATH=$HOME/bin:$PATH

# added by travis gem
[ -f /Users/brandon/.travis/travis.sh ] && source /Users/brandon/.travis/travis.sh

alias b='bundle'
alias bi='bundle install'
alias be='bundle exec'
alias pd=pushd
alias po=popd

# iTerm2 shell integration
. $HOME/.iterm2_shell_integration.bash
