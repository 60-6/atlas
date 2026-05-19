# atlas



## atlas is a tool for arch linux and its derivatives.

dependencies: none

installation: none, just paste into your .bashrc

atlas is read-only unless it asks for your permission, so you can mess with it safely.

see 'atlas ?' for syntax.


## what is it for

viewing, upgrading, and cleaning your system.

atlas can also be used to declare your system, 'atlas s' writes the heart of your system to a save path, 'atlas g' regenerates from it.

you can edit the save, copy it between machines, whatever, then rebuild from it whenever you want.

basically, arch turned into nixos without the extra nixos bullshit.


## extra

the default save path is '/tmp/atlas' because atlas doesn't create random files you never asked for.

point it at something like '/home/「user」/atlas' in the configuration module if you want it to persist.

consider removing 's' from default commands so saves stay manual.
