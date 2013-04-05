# to - v1.3.2
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


### SETTINGS ###

TO_BOOKMARK_DIR=~/.bookmarks

### MAIN ###

to() {
    # create empty bookmarks folder if it does not exist
    if [ ! -d "$TO_BOOKMARK_DIR" ]
    then
        \mkdir -pv -- "$TO_BOOKMARK_DIR"
    fi

    if [ -z "$1" ]
    then
        # show bookmarks
        \find "$TO_BOOKMARK_DIR" -mindepth 1 -type l -printf "%f -> %l\n"
        return 0
    elif [ "$1" = "-h" ]
    then
        _to_help
        return 0
    elif [ "$1" = "-p" ]
    then
        # print path of bookmark
        \readlink -f -- "$TO_BOOKMARK_DIR/$2" || return 1
        return 0
    elif [ "$1" = "-b" ]
    then
        # add bookmark
        if [ -z "$2" ]
        then
            local name="$(\basename -- "$PWD")"
        elif [ "$(\basename -- "$2")" != "$2" ]
        then
            echo "Invalid bookmark name: $2"
            return 1
        else
            local name="$2"
        fi
        if [ "$name" = '/' -o "$name" = '.' -o "$name" = '..' ]
        then
            # special cases
            echo "Invalid bookmark name: $name"
            return 1
        fi
        if [ "$3" ]
        then
            if [ -d "$3" ]
            then
                local target="$(\readlink -e -- "$3")"
            else
                \echo "$3 does not refer to a directory"
                return 1
            fi
        else
            local target="$PWD"
        fi
        # create link (symbolic force no-dereference)
        \ln -sfn -T "$target" -- "$TO_BOOKMARK_DIR/$name"
        return 0
    elif [ "$1" = "-r" ]
    then
        if [ "$2" = "$(_to_path_head "$2")" -a -h "$TO_BOOKMARK_DIR/$2" ]
        then
            # remove bookmark
            \rm -- "$TO_BOOKMARK_DIR/$2"
        else
            \echo "No bookmark: $2"
        fi
        return 0
    fi

    # go to bookmark
    if [ -d "$TO_BOOKMARK_DIR/$1" ]
    then
        \cd -P -- "$TO_BOOKMARK_DIR/$1"
    else
        \echo "Invalid link: $1"
        return 1
    fi
    return 0
}


### TAB COMPLETION ###

# tab completion generic
# $1 = ultimate word (current)
# $2 = penultimate word
# $3 = antepenultimate word
# Output valid completions
_to() {
    # create empty bookmarks file if it does not exist
    if [ ! -e "$TO_BOOKMARK_DIR" ]
    then
        \mkdir -pv -- "$TO_BOOKMARK_DIR"
    fi
    # build reply
    local compreply
    local matcher="$1"
    if [ "$3" = "-b" ]
    then
        # normal file completion
        compreply="$(\find "$(\dirname -- "${1/#-/./-}0")" -mindepth 1 -maxdepth 1 -type d 2> /dev/null)"
        matcher="${1/#-/./-}"
    elif [ "$2" = "-b" ]
    then
        # add current directory
        compreply="$(\basename -- "$PWD" )"$'\n'"$compreply"
        # get bookmarks
        compreply="$(_to_bookmarks)"$'\n'"$compreply"
    elif [ "$2" = "-r" ]
    then
        # get bookmarks
        compreply="$(_to_bookmarks)"$'\n'"$compreply"
    else
        # add subdirs
        compreply="$(_to_subdirs "$1")"$'\n'"$compreply"
        if [ "$2" = "-p" ]
        then
            # add subfiles
            compreply="$(_to_subfiles "$1")"$'\n'"$compreply"
        fi
        # get bookmarks (with slash)
        compreply="$(_to_bookmarks "/")"$'\n'"$compreply"
    fi
    # generate reply 
    \sed -n "/^$(_to_regex "$matcher").*/p" <<< "$compreply"
}

# tab completion bash
_to_bash() {
    # get components
    local len="${#COMP_WORDS[@]}"
    local one="${COMP_WORDS[COMP_CWORD]}"
    local two="${COMP_WORDS[COMP_CWORD-1]}"
    if [ $len -gt 2 ]
    then
       local three="${COMP_WORDS[COMP_CWORD-2]}"
    else
       local three=""
    fi
    # call generic tab completion function
    local IFS='
'
    COMPREPLY=( $(_to "$one" "$two" "$three") )
}

# tab completion zsh
_to_zsh() {
    # get components
    local len="${#COMP_WORDS[@]}"
    local one="${COMP_WORDS[COMP_CWORD]}"
    local two="${COMP_WORDS[COMP_CWORD-1]}"
    if [ $len -gt 2 ]
    then
       local three="${COMP_WORDS[COMP_CWORD-2]}"
    else
       local three=""
    fi
    # call generic tab completion function
    local IFS='
'
    COMPREPLY=( $(_to "$one" "$two" "$three") )
}

# setup tab completion
if [ "$ZSH_VERSION" ]
then
    \autoload -U +X bashcompinit && \bashcompinit
    \complete -o nospace -F _to_zsh to
else
    \complete -o filenames -o nospace -F _to_bash to
fi


### HELPER FUNCTIONS ###

_to_help() {
    \echo "Usage: to [OPTION] [BOOKMARK] [DEST]
Set the current working directory to a saved bookmark or subdirectory,
or create such a bookmark.
To view bookmarks, execute with no parameters
Options
  -b	Add a new bookmark (overwrites any current bookmark)
  -r	Remove bookmark
  -p	Print bookmark path
  -h	Show help"
}

# Return list of bookmarks in $TO_BOOKMARK_FILE
# $1 suffix
_to_bookmarks() {
    \find "$TO_BOOKMARK_DIR" -mindepth 1 -maxdepth 1 -type l -printf "%f$1\n"
}

# get the first part of the path
_to_path_head() {
    \sed -n 's@^\(\(\\.\|[^/]\)*\)\(/.*\)\?$@\1@p' <<<"$1"
}

# clean input for sed search
_to_regex() {
    \sed 's/[\/&]/\\&/g' <<< "$1"
}

# find the directories that could be subdirectory expansions of
# $1 word
_to_subdirs() {
    \find "$(\dirname -- "$(\readlink -f -- "$TO_BOOKMARK_DIR/${1}0" || echo /dev/null )")" -mindepth 1 -maxdepth 1 -type d -printf "%p/\n" 2> /dev/null | \sed "s/^$(_to_regex "$(\readlink -f -- "$TO_BOOKMARK_DIR/$(_to_path_head "$1")")")/$(_to_regex "$(_to_path_head "$1")")/"
}

# find the files that could be subdirectory expansions of
# $1 word
_to_subfiles() {
    \find "$(\dirname -- "$(\readlink -f -- "$TO_BOOKMARK_DIR/${1}0" || echo /dev/null )")" -mindepth 1 -maxdepth 1 -type f 2> /dev/null | \sed "s/^$(_to_regex "$(\readlink -f -- "$TO_BOOKMARK_DIR/$(_to_path_head "$1")")")/$(_to_regex "$(_to_path_head "$1")")/"
}

