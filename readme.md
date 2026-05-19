# atlas



## atlas is a tool for arch linux and its derivatives.

dependencies: none

installation: none, just paste into your .bashrc

atlas is read-only unless it asks for your explicit permission, so you can mess with it safely.

see 'atlas ?' for syntax.


## what is it for

viewing, upgrading, and cleaning your system.

the real trick is the save file, 'atlas s' writes the heart of your system to disk, 'atlas g' regenerates from it.

you can edit the save, copy it between machines, whatever, then rebuild from it whenever you want.

basically, arch turned into nixos without the bullshit of nixos.


## extra

the default save path is '/tmp/atlas' because atlas doesn't create random files you never asked for.

point it at something like '/home/「user」/atlas' in the configuration module if you want it to persist.

consider removing 's' from default commands so saves stay manual.
