# to - v1.0
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

TO_BOOKMARK_FILE=~/.bookmarks
TO_ECHO=\echo
TO_CD=\cd
TO_CAT=\cat
TO_FIND=\find
TO_DIRNAME=\dirname
TO_BASENAME=\basename
TO_SED=\sed


### MAIN ###

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
    elif [ "$1" = "-p" ]
    then
        # print path of bookmark
        "$TO_ECHO" "$(_to_reldir "$2")"
        return 0
    elif [ "$1" = "-b" ]
    then
        # add bookmark
        local name
        if [ "$2" ]
        then
            if [ $("$TO_SED" -En "s/(.*\/.*)/\1/p" <<< "$2") ]
            then
                "$TO_ECHO" "bookmark name may not contain forward slashes" >&2
                return 1
            fi
            name="$2"
        else
            name="$("$TO_BASENAME" "$PWD")"
        fi
        # add bookmark
        _to_rm "$name"
        "$TO_ECHO" "$name|$PWD" >> "$TO_BOOKMARK_FILE"
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


### TAB COMPLETION ###

# tab completion generic
# $1 = current word
# $2 = previous word
# Output valid completions
function _to {
    # create empty bookmarks file if it does not exist
    if [ ! -e "$TO_BOOKMARK_FILE" ]
    then
        "$TO_ECHO" -n > "$TO_BOOKMARK_FILE"
    fi
    # build reply
    local compreply
    if [ "$2" = "-b" ]
    then
        # add current directory
        compreply="$("$TO_BASENAME" "$PWD" )"$'\n'"$compreply"
        # get bookmarks
        compreply="$(_to_bookmarks)"$'\n'"$compreply"
    elif [ "$2" = "-r" ]
    then
        # get bookmarks
        compreply="$(_to_bookmarks)"$'\n'"$compreply"
    else
        local subdirs="$(_to_subdirs "$1" )"
        if [ "$subdirs" ]
        then
            # add subdirectories
            compreply="$subdirs"$'\n'"$compreply"
        else
            # get bookmarks (with slash)
            compreply="$(_to_bookmarks "\/")"$'\n'"$compreply"
        fi
    fi
    # generate reply
    "$TO_SED" -n "/^$(_to_regex "$1").*/p" <<<"$compreply"
}

# tab completion bash
function _to_bash {
    # get components
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    # call generic tab completion function
    COMPREPLY=( $(_to "$cur" "$prev") )
}

# setup tab completion
if [ "$ZSH_VERSION" ]
then
    \autoload -U +X bashcompinit && \bashcompinit
    \complete -o nospace -F _to_bash to
else
    \complete -o filenames -o nospace -F _to_bash to
fi


### HELPER FUNCTIONS ###

# Return list of bookmarks in $TO_BOOKMARK_FILE
# $1 sed safe suffix  WARNING escape any /s
function _to_bookmarks {
    "$TO_SED" -En "s/(.*)\|.*/\1$1/p" "$TO_BOOKMARK_FILE"
}

# get the directory referred to by a bookmark
function _to_dir {
    "$TO_SED" -En "s/^$1\|(.*)/\1/p" "$TO_BOOKMARK_FILE"
}

# get the first part of the path
function _to_path_head {
    "$TO_SED" -En "s/^([^/]*)(\/.*)?$/\1/p" <<<"$1"
}

# get the rest of the path
function _to_path_tail {
    "$TO_SED" -En "s/^[^/]*(\/.*)$/\1/p" <<<"$1"
}

# get the absolute path of an expanded bookmark/path
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
    "$TO_SED" -Ei "/^$1\|.*/ d" "$TO_BOOKMARK_FILE"
}

# clean input for sed search
function _to_regex {
    if [ "$1" = "/" ]
    then
        # special case for root dir
        "$TO_ECHO"
    else
        "$TO_ECHO" "$1" | "$TO_SED" -E 's/[\/&]/\\&/g'
    fi
}

# find the directories that could be subdirectory expansions of
# $1 word
function _to_subdirs {
    local bookmark="$(_to_path_head "$1")"
    local todir="$(_to_dir "$bookmark")"
    local reldir="$(_to_reldir "$1")\*"
    if [ "$todir" ]
    then
        "$TO_FIND" $("$TO_DIRNAME" "$reldir") -mindepth 1 -maxdepth 1 -type d | "$TO_SED" -E "s/^$(_to_regex "$todir")(.*)/$bookmark\1\//"
    fi
}

