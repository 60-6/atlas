# atlas

atlas is a tool for arch linux that lets you view, upgrade, clean, and declare your system.

it has no dependencies and it's read-only by default.

you can use it by pasting it into '~/.bashrc'.

see 'atlas ?' for syntax.



## extra


### configuration

atlas has a configuration module you can edit.

'save_directory' is volatile by default, change it somewhere else if you want it to last.

'default_commands' run when calling atlas without any arguments.

'upgrade_interval' is how often atlas asks you to upgrade, in days.

'cache_limit' is the package cache size limit before atlas asks you to clear it, in gb.

calling operations directly ignores configuration rules.

### save/gen

'atlas s' saves your system packages and your overwrites.

'atlas d' shows you the package differences between your current system and the saved one.

'atlas g' generates your system from atlas's save directory.

you can specify different save directories by using a generation marker as a second argument.

ex: 'atlas s 6' saves to '<save_directory>/atlas/6'.

### supersede

inside atlas's save directory, you'll find a 'supersede' directory where you can create 'overwrites'.

name each overwrite directory in supersede after its destination directory, use '@' instead of '~' and ':' instead of '/'.

anything under the overwrite directories will be regenerated when running 'atlas g'.

ex: '<save_directory>/atlas/supersede/@:.config/kitty/kitty.conf' overwrites '~/.config/kitty/kitty.conf'.

if you've got questions or anything, discussions are there.
