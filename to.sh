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
TO_ECHO=echo
TO_CAT=cat
TO_PWD=pwd
TO_BASENAME=basename
TO_SED=sed

function to {
if [ "$1" ]
then
 if [ "$1" = "-b" ]
 then
  if [ "$2" ]
  then
   if expr "$2" : ".*/.*"
   then
    echo "bookmark name may not contain forward slashes" >&2
    return 1
   fi
   # add bookmark
   _to_rm "$2"
   "$TO_ECHO" "$2|`$TO_PWD`" >> "$TO_BOOKMARK_FILE"
  fi
 elif [ "$1" = "-r" ]
 then
  # remove bookmark
  _to_rm "$2"
 elif [ -e "$TO_BOOKMARK_FILE" ]
 then
  # go to bookmark if found
  local bookmark="$(_to_path_head "$1")"
  local extra="$(_to_path_tail "$1")"
  local todir="$(_to_dir "$bookmark")"
  if [ "$todir" ]
  then
   cd $(_to_reldir $1)
  else
   "$TO_ECHO" "No shortcut:" "$bookmark"
  fi
 else
   "$TO_ECHO" "No shortcut:" "$bookmark"
 fi
elif [ -e "$TO_BOOKMARK_FILE" ]
then
 # show bookmarks
 "$TO_CAT" "$TO_BOOKMARK_FILE"
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
local todir="$(_to_dir $(_to_path_head "$1") )"
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
if [ -e "$TO_BOOKMARK_FILE" ]
then
  "$TO_SED" -ri "/^$1\|.*/ d" "$TO_BOOKMARK_FILE"
fi
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

# tab completion bash
function _to {
local cur="${COMP_WORDS[COMP_CWORD]}"
local prev="${COMP_WORDS[COMP_CWORD-1]}"
local bookmark="$(_to_path_head "$cur")"
local todir="$( _to_dir "$bookmark")"
if [ "$prev" = "-b" -o "$prev" = "-r" ]
then
 if [ "$prev" = "-b" ]
 then
  # add current directory
  COMPREPLY="$("$TO_BASENAME" "$($TO_PWD)" )"
 fi
 if [ -e "$TO_BOOKMARK_FILE" ]
 then
  # get bookmarks
  COMPREPLY="$("$TO_SED" -rn "s/(.*)\|.*/\1/p" "$TO_BOOKMARK_FILE") $COMPREPLY"

 fi
elif [ -e "$TO_BOOKMARK_FILE" ]
then
 # get bookmarks (with slash)
 COMPREPLY=$("$TO_SED" -rn "s/(.*)\|.*/\1\//p" "$TO_BOOKMARK_FILE")
 if [ "$todir" ]
 then
  # add subdirectories
  local subdir="$(compgen -S "/" -d "$(_to_reldir $cur)" | $TO_SED -r "s/^$(_to_regex "$todir")/$bookmark/")"
  COMPREPLY="$subdir $COMPREPLY"
 fi
fi
# generate reply
COMPREPLY=( $(compgen -W "$COMPREPLY" -- "$cur") )
}

# tab completion zsh
function _to_zsh {
if [ -e "$TO_BOOKMARK_FILE" ]
then
 reply=(`"$TO_SED" -rn "s/(.*)\|.*/\1/p" "$TO_BOOKMARK_FILE"`)
fi
}

if [ "$ZSH_VERSION" ]; then
 compctl -K _to_zsh to
else
 complete -o nospace -F _to to
fi
