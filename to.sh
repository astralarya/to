# to - v1.4
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
                \echo "Ignored option: $arg"
            fi
        else
            input+=("$arg")
        fi
    done

    # create empty bookmarks folder if it does not exist
    if [ ! -d "$TO_BOOKMARK_DIR" ]
    then
        \mkdir -pv -- "$TO_BOOKMARK_DIR"
    fi

    if [ -z "$option" -a "${#input[@]}" = 0 ]
    then
        # show bookmarks
        \find "$TO_BOOKMARK_DIR" -mindepth 1 -type l -printf "%f -> %l\n"
        return 0
    elif [ "$option" = "-p" ]
    then
        # print path of bookmarks
        local good="good"
        local response
        for i in "${input[@]}"
        do
            if [ "$i" ]
            then
                response+=" $(\readlink -f -- "$TO_BOOKMARK_DIR/$i")"
                if [ $? != 0 ]
                then
                    good="bad"
                fi
            fi
        done
        \echo $response
        if [ "$good" != "good" ]
        then
            return 1
        else
            return 0
        fi
    elif [ "$option" = "-b" ]
    then
        if [ "$ZSH_VERSION" ]
        then
            local bound=2
        else
            local bound=1
        fi
        # get target
        if [ "${#input[@]}" -gt "$bound" ]
        then
            local target="${input[-1]}"
            local end=${#input[@]}-1
            if [ -d "$target" ]
            then
                local target="$(\readlink -e -- "$target")"
            else
                \echo "$target does not refer to a directory"
                return 1
            fi
        else
            local target="$PWD"
            local end=${#input[@]}
        fi
        # add bookmarks
        local good="good"
        if [ "${#input[@]}" -lt "$bound" ]
        then
            local name="$(\basename -- "$PWD")"
            # create link (symbolic force no-dereference Target)
            \ln -sfnT "$target" -- "$TO_BOOKMARK_DIR/$name"
        else
            for i in "${input[@]:0:$end}"
            do
                if [ "$i" ]
                then
                    if [ "$(\basename -- "$i")" != "$i" ]
                    then
                        \echo "Invalid bookmark name: $i"
                        good="bad"
                        continue
                    else
                        local name="$i"
                    fi
                    if [ "$name" = '/' -o "$name" = '.' -o "$name" = '..' ]
                    then
                        # special cases
                        \echo "Invalid bookmark name: $name"
                        good="bad"
                        continue
                    fi
                    # create link (symbolic force no-dereference Target)
                    \ln -sfnT "$target" -- "$TO_BOOKMARK_DIR/$name"
                fi
            done
        fi
        if [ "$good" = "good" ]
        then
            return 0
        else
            return 1
        fi
    elif [ "$option" = "-r" ]
    then
        for i in "${input[@]}"
        do
            if [ "$i" ]
            then
                if [ "$i" = "$(_to_path_head "$i")" -a -h "$TO_BOOKMARK_DIR/$i" ]
                then
                    # remove bookmark
                    \rm -- "$TO_BOOKMARK_DIR/$i"
                else
                    \echo "No bookmark: $i"
                fi
            fi
        done
        return 0
    fi

    # go to bookmark
    for i in "${input[@]}"
    do
        if [ -d "$TO_BOOKMARK_DIR/$i" ]
        then
            \cd -P -- "$TO_BOOKMARK_DIR/$i"
        else
            \echo "Invalid link: $i"
            return 1
        fi
        return 0
    done
}


### TAB COMPLETION ###

# tab completion generic
# $1 = position of current word (1 is first argument)
# $2-n = words
# Output valid completions
_to() {
    # read arguments
    local word
    local cword
    local option
    local state
    local input
    local inputpos=0
    local iter=-1
    for arg in "$@"
    do
        if [ -z "$cword" ]
        then
            # get first argument
            cword=$arg
        elif [ "$iter" = 0 ]
        then
            # discard self argument 'to'
            input=0
        elif [ "$state" = "input" ]
        then
            input="$(\expr $input + 1)"
        elif [ "$arg" = "-h" -o "$arg" = "--help" ]
        then
            return 0
        elif [ "$arg" = "--" ]
        then
            state="input"
        elif [ "$arg" = "-b" -o "$arg" = "-r" -o "$arg" = "-p" ]
        then
            if [ ! "$option" ]
            then
                option="$arg"
            fi
        else
            input="$(\expr $input + 1)"
        fi
        if [ "$iter" = "$cword" ]
        then
            word=$arg
            inputpos=$input
        fi
        iter="$(\expr $iter + 1)"
    done
    if [ -z "$word" ]
    then
        inputpos="$(\expr $inputpos + 1)"
    fi

    # create empty bookmarks file if it does not exist
    if [ ! -e "$TO_BOOKMARK_DIR" ]
    then
        \mkdir -pv -- "$TO_BOOKMARK_DIR"
    fi

    # build reply
    local compreply
    if [ "$option" = "-b" ]
    then
        if [ "$inputpos" = 1 ]
        then
            # add current directory
            compreply+=("$(\basename -- "$PWD" )")
            # get bookmarks
            compreply+=( $(_to_bookmarks "$IFS") )
        elif [ "$inputpos" = 2 ]
        then
            # normal file completion
            word="${word/#-/./-}"
            compreply+=( $(\find "$(\dirname -- "${word}0")" -mindepth 1 -maxdepth 1 -type d -printf "%p$IFS" 2> /dev/null) )
        fi
    elif [ "$option" = "-r" ]
    then
        # get bookmarks
        compreply+=( $(_to_bookmarks "$IFS") )
    else
        local subdirs=( $(_to_subdirs "$word") )
        if [ "$option" = "-p" ]
        then
            local subfiles=( $(_to_subfiles "$word") )
        else
            local subfiles
        fi
        local tosub
        if [ "${#subdirs[@]}" != 0 ]
        then
            # add subdirectories
            compreply+=( ${subdirs[@]} )
            tosub="yes"
        fi
        if [ "${#subfiles[@]}" != 0 ]
        then
            # add subfiles
            compreply+=( ${subfiles[@]} )
            tosub="yes"
        fi
        if [ -z "$tosub" ]
        then
            # get bookmarks (with slash)
            compreply+=( $(_to_bookmarks "/$IFS") )
        fi
    fi

    local filter
    # generate reply 
    for completion in "${compreply[@]}"
    do
        if [ -z "${completion/#$word*/}" ]
        then
            filter+=("$completion")
        fi
    done
    \echo "${filter[@]}"
}

# tab completion bash
_to_bash() {
    # call generic tab completion function
    COMPREPLY=( $(_to "$COMP_CWORD" ${COMP_WORDS[@]}) )
}

# tab completion zsh
_to_zsh() {
    # call generic tab completion function
    COMPREPLY=( $(_to "$COMP_CWORD" ${COMP_WORDS[@]}) )
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
    \find "$TO_BOOKMARK_DIR" -mindepth 1 -maxdepth 1 -type l -printf "%f$1"
}

# get the first part of the path
_to_path_head() {
    \sed -n '1h; 1!H; ${ g; s@^\(\(\\.\|[^/]\)*\)\(/.*\)\?$@\1@p }' <<< "$1"
}

# find the directories that could be subdirectory expansions of
# $1 word
_to_subdirs() {
    local files=( $(\find "$(\dirname -- "$(\readlink -f -- "$TO_BOOKMARK_DIR/${1}0" || \echo /dev/null )")" -mindepth 1 -maxdepth 1 -type d -printf "%p/$IFS" 2> /dev/null) )
    local pattern="$(\readlink -f -- "$TO_BOOKMARK_DIR/$(_to_path_head "$1")")"
    local replace="$(_to_path_head "$1")"
    \echo "${files[@]/#$pattern/$replace}"
}

# find the files that could be subdirectory expansions of
# $1 word
_to_subfiles() {
    local files=( $(\find "$(\dirname -- "$(\readlink -f -- "$TO_BOOKMARK_DIR/${1}0" || \echo /dev/null )")" -mindepth 1 -maxdepth 1 -type f -printf "%p$IFS" 2> /dev/null) )
    local pattern="$(\readlink -f -- "$TO_BOOKMARK_DIR/$(_to_path_head "$1")")"
    local replace="$(_to_path_head "$1")"
    \echo "${files[@]/#$pattern/$replace}"
}

