# atlas

atlas is a tool for arch linux that lets you view, declare, and maintain your system

it has no dependencies and it's read-only by default

you can use atlas by pasting 'atlas.sh' into '~/.bashrc' or sourcing it

see 'atlas ?' for syntax

---

### save/gen

'atlas d' shows you the package differences between your current system and the saved one

'atlas s' creates an "atlas" folder in your home directory, it saves your system packages and your custom overwrites

'atlas g' generates your system from atlas's save directory

you can specify different save directories by using a generation marker as a second argument

ex:
```
'atlas s x' saves to '~/atlas/x'
'atlas g x' generates from '~/atlas/x'
```

### supersede

inside atlas's save directory, you'll find a 'supersede' directory where you can create 'overwrites'

name each overwrite directory in supersede after its destination directory, use '@' instead of '~' and ':' instead of '/'

add '+' to the end of the overwrite name to fully sync and replace the destination instead of merging

'atlas s' can sync overwrite entries from your system, use it after creating an overwrite to handle permissions automatically

anything under the overwrite directories will be regenerated when running 'atlas g'

ex:
```
'~/atlas/supersede/@:.config/kitty/kitty.conf' maps to '~/.config/kitty/kitty.conf'
```

---

if you have any questions, i'm happy to answer them
