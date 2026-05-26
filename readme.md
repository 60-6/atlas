# atlas

atlas is a tool for arch linux that lets you view, upgrade, clean, and declare your system.

it has no dependencies and it's read-only by default.

you can use it by pasting it into '~/.bashrc'.

see 'atlas ?' for syntax.


### extra

atlas has a configuration module you can edit.

'atlas s' saves your system packages and your overwrites, more clarity on that below.

'atlas d' shows you the difference between your current system and the saved one.

'atlas g' regenerates your system from atlas's save directory.

you can specify different save directories by using a generation marker as a second argument.

ex: 'atlas s 6' saves to '<save_directory>/atlas/6'.

inside atlas's save directory, you'll find a 'supersede' directory where you can create 'overwrites'.

name each overwrite directory in supersede after its destination directory, use '@' instead of '~' and ':' instead of '/'.

anything under the overwrite directories will be regenerated when running 'atlas g'.

ex: '<save_directory>/atlas/supersede/@:.config/kitty/kitty.conf' overwrites '~/.config/kitty/kitty.conf'.

you can put anything in supersede, even your entire home directory if you're a psychopath.

if you've got questions or anything, discussions are there.
