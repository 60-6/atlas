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

you can create a folder named 'overwrite' in atlas's save directory

inside 'overwrite', name the targets after their destination path, using '@' instead of '~' and ':' instead of '/'

anything under the specified path will be optionally overwritten when running 'atlas g'

you can pass a second argument as a generation marker, for example 'atlas s 6'
