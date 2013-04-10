# to - v1.3.3
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
    # read arguments
    local option
    local input
    local state
    if [ "$BASH" ]
    then
        # skip 0th and 1st index for zsh compatability
        input[0]="null"
        input[1]="null"
    fi
    for arg in "$@"
    do
        if [ "$state" = "input" ]
        then
            input+=("$arg")
        elif [ "$arg" = "-h" -o "$arg" = "--help" ]
        then
            \echo "Usage: to [OPTION] [BOOKMARK] [DEST]
Set the current working directory to a saved bookmark or subdirectory,
or create such a bookmark.
To view bookmarks, execute with no parameters
Options
  -b	Add a new bookmark (overwrites any current bookmark)
  -r	Remove bookmark
  -p	Print bookmark path
  -h	Show help"
            return 0
        elif [ "$arg" = "--" ]
        then
            state="input"
        elif [ "$arg" = "-b" -o "$arg" = "-r" -o "$arg" = "-p" ]
        then
            if [ ! "$option" ]
            then
                option="$arg"
            else
                echo "Ignored option: $arg"
            fi
        else
            input+=("$arg")
        fi
    done
    local first="${input[2]}"
    local second="${input[3]}"

    # create empty bookmarks folder if it does not exist
    if [ ! -d "$TO_BOOKMARK_DIR" ]
    then
        \mkdir -pv -- "$TO_BOOKMARK_DIR"
    fi

    if [ -z "$option" -a -z "$first" ]
    then
        # show bookmarks
        \find "$TO_BOOKMARK_DIR" -mindepth 1 -type l -printf "%f -> %l\n"
        return 0
    elif [ "$option" = "-p" ]
    then
        # print path of bookmarks
        local good="good"
        local response
        for ((i=2; i < ${#input[@]}; i++))
        do
            if [ "${input[$i]}" ]
            then
                response+=" $(\readlink -f -- "$TO_BOOKMARK_DIR/${input[$i]}")"
                if [ $? != 0 ]
                then
                    good="bad"
                fi
            fi
        done
        echo $response
        if [ "$good" != "good" ]
        then
            return 1
        else
            return 0
        fi
    elif [ "$option" = "-b" ]
    then
        # add bookmark
        if [ -z "$first" ]
        then
            local name="$(\basename -- "$PWD")"
        elif [ "$(\basename -- "$first")" != "$first" ]
        then
            echo "Invalid bookmark name: $first"
            return 1
        else
            local name="$first"
        fi
        if [ "$name" = '/' -o "$name" = '.' -o "$name" = '..' ]
        then
            # special cases
            echo "Invalid bookmark name: $name"
            return 1
        fi
        if [ "$second" ]
        then
            if [ -d "$second" ]
            then
                local target="$(\readlink -e -- "$second")"
            else
                \echo "$second does not refer to a directory"
                return 1
            fi
        else
            local target="$PWD"
        fi
        # create link (symbolic force no-dereference Target)
        \ln -sfnT "$target" -- "$TO_BOOKMARK_DIR/$name"
        return 0
    elif [ "$option" = "-r" ]
    then
        for ((i=2; i < ${#input[@]}; i++))
        do
            if [ "${input[$i]}" ]
            then
                if [ "${input[$i]}" = "$(_to_path_head "${input[$i]}")" -a -h "$TO_BOOKMARK_DIR/${input[$i]}" ]
                then
                    # remove bookmark
                    \rm -- "$TO_BOOKMARK_DIR/${input[$i]}"
                else
                    \echo "No bookmark: ${input[$i]}"
                fi
            fi
        done
        return 0
    fi

    # go to bookmark
    if [ -d "$TO_BOOKMARK_DIR/$first" ]
    then
        \cd -P -- "$TO_BOOKMARK_DIR/$first"
    else
        \echo "Invalid link: $first"
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
        local subdirs="$(_to_subdirs "$1")"
        if [ "$2" = "-p" ]
        then
            local subfiles="$(_to_subfiles "$1")"
        else
            local subfiles=""
        fi
        if [ "$subdirs" -o "$subfiles" ]
        then
            # add subdirectories
            compreply="$subdirs"$'\n'"$compreply"
            # add subfiles
            compreply="$subfiles"$'\n'"$compreply"
        else
            # get bookmarks (with slash)
            compreply="$(_to_bookmarks "/")"$'\n'"$compreply"
        fi
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

