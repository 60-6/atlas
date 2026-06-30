# atlas

atlas is a tool for arch linux that lets you view, declare, and maintain your system

it has no dependencies and it's read-only by default

you can use atlas by pasting 'atlas.sh' into '~/.bashrc' or sourcing it

see 'atlas ?' for syntax

## extra information

'atlas d' shows you the package differences between your current system and the saved state

'atlas s' creates an 'atlas' folder in your home directory, it saves your system packages and your custom overwrites

'atlas g' generates your system from atlas's save directory, it syncs your system packages according to the saved state and applies your overwrites

you can specify different save directories by passing a second argument

ex:

* 'atlas d x' diffs against '~/atlas/x'
* 'atlas s x' saves to '~/atlas/x'
* 'atlas g x' generates from '~/atlas/x'

inside atlas's save directory, you'll find a 'supersede' directory where you can create 'overwrites'

name each overwrite directory in supersede after its destination directory, use '@' instead of '~' and ':' instead of '/'

add '+' to the end of the overwrite name to fully sync and replace the directory instead of merging

ex:

* '<save_directory>/supersede/@:.config/kitty/kitty.conf' maps to '~/.config/kitty/kitty.conf'
* '<save_directory>/supersede/@:.config+' maps to your entire '~/.config' directory

'atlas s' can sync overwrite entries from your system, use it after creating an overwrite to handle permissions automatically


---

if you have any questions, i'm happy to answer them
