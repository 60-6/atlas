# atlas

atlas is a tool for arch linux that lets you view, declare, and maintain your system

it has no dependencies and it's read-only by default

you can use atlas by pasting the code in 'atlas.sh' into '~/.bashrc' or sourcing it

see 'atlas ?' for syntax

## extra information

you can use atlas to declaratively manage your system using 'generations', these generations live in '~/atlas'

the default generation is '~/atlas/0', but you can specify different paths by passing a second argument

ex:

* 'atlas {operations} 1' save directory maps to '~/atlas/1'

these generations consist of 2 files that contain your system packages and a 'supersede' directory

inside the supersede directory, you can create 'overwrites', which can save and generate any files or directories you specify

name each overwrite directory in supersede after its target directory, use '@' instead of '~' and ':' instead of '/'

adding '+' to the end of a directory name fully syncs and replaces the entire directory and its contents

ex:

* '{generation}/supersede/@:.config/kitty/kitty.conf' maps to '~/.config/kitty/kitty.conf'
* '{generation}/supersede/@:.config+' maps to your entire '~/.config' directory

'atlas s' creates a generation where it saves your system packages and syncs overwrite entries from your system, use it after creating an overwrite to handle permissions automatically

'atlas g' generates your system from a generation, it syncs your system packages according to the saved state and applies your overwrites

'atlas d' shows you the package differences between your current system and a generation

'atlas e' exports a generation from anywhere on your system

---

if you have any questions, i'm happy to answer them
