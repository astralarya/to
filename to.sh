# to
# Bookmark locations in bash
#
# Copyright (C) 2013 Mara Kim
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see http://www.gnu.org/licenses/.


TO_BOOKMARK_FILE=~/.bookmarks
TO_ECHO=\echo
TO_CD=\cd
TO_CAT=\cat
TO_PWD=\pwd
TO_BASENAME=\basename
TO_SED=\sed
TO_COMPGEN=\compgen
TO_COMPLETE=\complete 

function to {
    # create empty bookmarks file if it does not exist
    if [ ! -e "$TO_BOOKMARK_FILE" ]
    then
        "$TO_ECHO" -n > "$TO_BOOKMARK_FILE"
    fi

    if [ -z "$1" ]
    then
        # show bookmarks
        "$TO_CAT" "$TO_BOOKMARK_FILE"
        return 0
    elif [ "$1" = "-b" ]
    then
        # add bookmark
        local mypath="$("$TO_PWD")"
        local name
        if [ "$2" ]
        then
            if [ $("$TO_SED" -rn "s/(.*\/.*)/\1/p" <<< "$2") ]
            then
                "$TO_ECHO" "bookmark name may not contain forward slashes" >&2
                return 1
            fi
            name="$2"
        else
            name="$("$TO_BASENAME" "$mypath")"
        fi
        # add bookmark
        _to_rm "$name"
        "$TO_ECHO" "$name|$mypath" >> "$TO_BOOKMARK_FILE"
        return 0
    elif [ "$1" = "-r" ]
    then
        # remove bookmark
        _to_rm "$2"
        return 0
    fi

    # go to bookmark
    local bookmark="$(_to_path_head "$1")"
    local extra="$(_to_path_tail "$1")"
    local todir="$(_to_dir "$bookmark")"
    if [ "$todir" ]
    then
        "$TO_CD" "$(_to_reldir "$1")"
    else
        "$TO_ECHO" "No shortcut: $bookmark"
    fi
}

# get the directory referred to by a bookmark
function _to_dir {
    "$TO_SED" -rn "s/^$1\|(.*)/\1/p" "$TO_BOOKMARK_FILE"
}

# get the first part of the path
function _to_path_head {
    "$TO_SED" -rn "s/^([^/]*)(\/.*)?$/\1/p" <<<"$1"
}

# get the rest of the path
function _to_path_tail {
    "$TO_SED" -rn "s/^[^/]*(\/.*)$/\1/p" <<<"$1"
}

# get the expanded path of a bookmark/path
function _to_reldir {
    local todir="$(_to_dir "$(_to_path_head "$1")" )"
    if [ "$todir" = "/" ]
    then
        # special case for root dir
        "$TO_ECHO" "$(_to_path_tail "$1")"
    else
        "$TO_ECHO" "$todir$(_to_path_tail "$1")"
    fi
}

# remove bookmark
function _to_rm {
    "$TO_SED" -ri "/^$1\|.*/ d" "$TO_BOOKMARK_FILE"
}

# clean input for sed search
function _to_regex {
    if [ "$1" = "/" ]
    then
        # special case for root dir
        "$TO_ECHO"
    else
        "$TO_ECHO" $1 | "$TO_SED" -e 's/[\/&]/\\&/g'
    fi
}

# tab completion generic
# $1 = COMP_WORDS (words in buffer)
# $2 = COMP_CWORDS (index to current word)
function _to {
    # create empty bookmarks file if it does not exist
    if [ ! -e "$TO_BOOKMARK_FILE" ]
    then
        "$TO_ECHO" -n > "$TO_BOOKMARK_FILE"
    fi
    # get parameters
    declare -a comp_words=("${!1}")
    local comp_cword=$2
    # get components
    local cur="${comp_words[comp_cword]}"
    local prev="${comp_words[comp_cword-1]}"
    local bookmark="$(_to_path_head "$cur")"
    local todir="$( _to_dir "$bookmark")"
    # build reply
    local compreply
    if [ "$prev" = "-b" -o "$prev" = "-r" ]
    then
        if [ "$prev" = "-b" ]
        then
            # add current directory
            compreply="$("$TO_BASENAME" "$($TO_PWD)" ) $compreply"
        fi
        if [ -e "$TO_BOOKMARK_FILE" ]
        then
            # get bookmarks
            compreply="$("$TO_SED" -rn "s/(.*)\|.*/\1/p" "$TO_BOOKMARK_FILE") $compreply"
        fi
    else
        if [ "$todir" ]
        then
            # add subdirectories
            compreply="$("$TO_COMPGEN" -S "/" -d "$(_to_reldir $cur)" | $TO_SED -r "s/^$(_to_regex "$todir")/$bookmark/") $compreply"
        else
            # get bookmarks (with slash)
            compreply="$("$TO_SED" -rn "s/(.*)\|.*/\1\//p" "$TO_BOOKMARK_FILE") $compreply"
        fi
    fi
    # generate reply
    "$TO_COMPGEN" -W "$compreply" -- "$cur"
}

# tab completion bash
function _to_bash {
    COMPREPLY=( $(_to COMP_WORDS[@] $COMP_CWORD) )
}
# tab completion zsh TODO remove?
function _to_zsh {
    \compadd - "$(_to words[@] $CURRENT)"
}

# setup tab completion
if [ "$ZSH_VERSION" ]; then
    autoload -U +X bashcompinit && bashcompinit
    "$TO_COMPLETE" -o filenames -o nospace -F _to_bash to
else
    "$TO_COMPLETE" -o filenames -o nospace -F _to_bash to
fi
