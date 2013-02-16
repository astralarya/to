# to
# Mara Kim
# Bookmark locations in bash


TO_BOOKMARK_FILE=~/.bookmarks
TO_ECHO=echo
TO_CAT=cat
TO_PWD=pwd
TO_GREP=grep
TO_SED=sed

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
  local TODIR=$($TO_GREP \>$1 $TO_BOOKMARK_FILE -A 1 -x | $TO_GREP -v \>$1)
  if [ "$TODIR" ]
  then
   cd $TODIR
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
 local TODIR=$($TO_GREP \>$1 $TO_BOOKMARK_FILE -A 1 -x | $TO_GREP -v \>$1)
 if [ "$TODIR" ]
 then
  $TO_SED /^\>$1\$/,+1d $TO_BOOKMARK_FILE > $TO_BOOKMARK_FILE~
  mv $TO_BOOKMARK_FILE~ $TO_BOOKMARK_FILE
 fi
fi
}

# tab completion
_to() {
local cur=${COMP_WORDS[COMP_CWORD]}
if [ -a $TO_BOOKMARK_FILE ]
then
 COMPREPLY=( $(compgen -W "$($TO_GREP \> $TO_BOOKMARK_FILE | cut -c 2-)" -- $cur) )
fi
}
complete -F _to to
