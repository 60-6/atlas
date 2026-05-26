# atlas

atlas is a tool for arch linux that lets you view, upgrade, clean, and declare your system

it has no dependencies and it's read-only by default

you can use it by pasting it into '~/.bashrc'

see 'atlas ?' for syntax


### extra

atlas has a configuration module you can edit

'atlas s' saves the core of your system

'atlas d' shows you the difference between your current system and the saved one

'atlas g' regenerates your system from atlas's save directory

you can specify different save directories by using a generation marker as a second argument

ex: 'atlas s 6' saves to '<save_directory>/atlas/6'

inside atlas's save directory, you'll find a 'supersede' directory. you can use it to create overwrites

name folders in supersede after their destination path, using '@' instead of '~' and ':' instead of '/'

anything under the overwrite folders will be regenerated when running 'atlas g'

ex '<save_directory>/atlas/supersede/@:.config/kitty/kitty.conf' writes to '~/.config/kitty/kitty.conf'
