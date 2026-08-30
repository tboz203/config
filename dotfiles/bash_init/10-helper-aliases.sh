# "helper" aliases
# (aliases that may also be useful in scripting)

# expand aliases even if not interactive
shopt -s expand_aliases

alias rmf='\rm -I --one-file-system -rf'
alias rimraf='rmf'

alias xargs='xargs -r '

alias day='date +%Y-%m-%d'
alias full='date "+%Y.%m.%d-%H.%M.%S"'

alias loud='BASH_ENV=~/.bash_loud '
