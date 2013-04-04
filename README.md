# to

**to** - A simple script for bookmarking directory locations in POSIX-like systems with tab completion


## Installation

Shells currently supported are bash and zsh.  Other shells may be compatible, but they have not been tested.

Source to.sh in your shell's initialization file.

This script supports several operating systems.  For more details see https://github.com/resultsreturned/to/wiki


## Usage

to [OPTION] [BOOKMARK]

Options
* -b	Add a new bookmark for current directory (overwrites any current bookmark)
* -r	Remove bookmark
* -p	Print bookmark path
* -h	Show help

### Examples

print all bookmarks
> to

go to the foo bookmark (if exists)
> to foo

go to the directory bar in the directory foo points to (if exists)
> to foo/bar

set the foo bookmark to the current directory
> to -b foo

create a bookmark with the name of the current directory pointing to it
> to -b

remove the foo bookmark
> to -r foo

print the path of the foo bookmark
> to -p foo

open up bar.cpp at the foo bookmark in vim
> vim $(to -p foo/bar.cpp)

You can also manually edit the $TO_BOOKMARK_DIR folder (defined in `to.sh`, default `~/.bookmarks`)
which contains symbolic links that represent your bookmarks.


## Dependencies

* bash or zsh

The following functionality should either be provided or built in:
* cd
* mv
* echo
* cat
* find
* dirname
* basename
* sed

## License

to - v1.3.1

Copyright (C) 2013  Mara Kim, Philipp Adolf, Max Thrun

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
