to
==

A simple bash script for bookmarking file system locations with tab completion

Installation
============

source to.sh in your .bashrc

Usage
=====
to [OPTION] [BOOKMARK]

Options
-b	Add a new bookmark for current directory (overwrites any current bookmark)
-d	Delete bookmark

$ to
print all bookmarks

$ to foo
go to the foo bookmark (if exists)

$ to -b foo
set the foo bookmark to the current directory

$ to -d foo
delete the foo bookmark


You can also manually edit the $TO_BOOKMARKS file (defined in to.sh, default ~/.bookmarks)
The syntax is:
>bookmarkname
/path/to/bookmark


Dependencies
============

bash
echo
cat
pwd
grep
sed
less
