# My config files

My personal linux config files, along w/ two scripts (wireup and unwire) to
install and uninstall them. Still in a newish phase.

## `aliases`

My shell aliases. It's specifically named `.bash_aliases`, but should probably
be universal. Standard `ls` stuff, some things for misspellings, and a few
common commands.

## `bashrc`

A standard (source?) bashrc that I've taken and modified to my liking. Note the
history env variables and PS1 framework

## `bin/`

My personal exacutables folder. A number of scripts i've written to do things
around the house, along with some wrappers for games and such.

## `gitconfig`

Just my local gitconfig file. As you can see, I like vim.

## `git-prompt`

A bash script that git distributes to add some git info to your PS1

## `inputrc`

My `inputrc` file. Vi-mode, plus clear-screen and tab-completion. Simple stuff.

## `logout`

(source?)'s standard `bash_logout` file.

## `profile`

(source?)'s standard profile, with an executables folder and a place to put
python modules.

## `pymodules`

As of yet, a single python module that I use in a couple of scripts.

## `README.md`

This file.

## `toprc`

`top`'s generated rc file with my settings.

## `unwire`

A script to remove
- the symlinks to these files
- whatever files are there before installing

## `vimrc`

My vimrc file. Started out as the sample one, added in my `set`tings and some
`map`pings. Most prominently, mapped jk to `<esc>` in insert mode and : to open
the command window.

## `wireup`

A script to install these config files.

