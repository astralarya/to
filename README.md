to
==

to - A simple script for bookmarking file system locations in bash & zsh with tab completion

Installation
============

source to.sh in your .bashrc or .zshrc


Usage
=====

to [OPTION] [BOOKMARK]

Options
* -b	Add a new bookmark for current directory (overwrites any current bookmark)
* -d	Delete bookmark

$ to
>print all bookmarks

$ to foo
>go to the foo bookmark (if exists)

$ to -b foo
>set the foo bookmark to the current directory

$ to -d foo
>delete the foo bookmark


You can also manually edit the $TO_BOOKMARKS file (defined in to.sh, default ~/.bookmarks)
The syntax is:
>bookmarkname|/path/to/bookmark


Dependencies
============

bash or zsh
echo
cat
pwd
sed

License
=======

Copyright (C) 2013  Mara Kim, Max Thrun

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
