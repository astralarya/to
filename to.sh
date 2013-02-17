# to
# Bookmark locations in bash
#
# Copyright (C) 2013 Mara Kim
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software 
# Foundation, either version 3 of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with 
# this program. If not, see http://www.gnu.org/licenses/.


TO_BOOKMARK_FILE=~/.bookmarks
TO_ECHO=`which echo`
TO_CAT=`which cat`
TO_PWD=`which pwd`
TO_SED=`which sed`

to() {
if [ "$1" ]
then
 if [ "$1" = "-b" ]
 then
  if [ "$2" ]
  then
   # add bookmark
   _to_rm "$2"
   $TO_ECHO \>"$2" >> $TO_BOOKMARK_FILE
   $TO_PWD >> $TO_BOOKMARK_FILE
  fi
 elif [ "$1" = "-r" ]
 then
  # remove bookmark
  _to_rm "$2"
 elif [ -a $TO_BOOKMARK_FILE ]
 then
  # go to bookmark if found
  local TODIR=$($TO_SED -n /^\>$1\$/\{n\;p\;\} $TO_BOOKMARK_FILE)
  if [ "$TODIR" ]
  then
   cd "$TODIR"
  else
   $TO_ECHO "No shortcut:" "$1"
  fi
 else
   $TO_ECHO "No shortcut:" "$1"
 fi
elif [ -a $TO_BOOKMARK_FILE ]
then
 # show bookmarks
 $TO_CAT $TO_BOOKMARK_FILE
fi
}

# remove bookmark
_to_rm() {
if [ -a $TO_BOOKMARK_FILE ]
then
 local TODIR=$($TO_SED -n /^\>$1\$/\{n\;p\;\} $TO_BOOKMARK_FILE)
 if [ "$TODIR" ]
 then
  $TO_SED -i /^\>$1\$/,+1d $TO_BOOKMARK_FILE
 fi
fi
}

# tab completion
_to() {
local cur=${COMP_WORDS[COMP_CWORD]}
if [ -a $TO_BOOKMARK_FILE ]
then
 COMPREPLY=( $(compgen -W "$($TO_SED -n 's/>\(.*\)/\1/p' $TO_BOOKMARK_FILE)" -- $cur) )
fi
}
complete -F _to to
