# tm-powershell

These are my personal powershell functions that i use to speed up working on different projects. It's currently set up for a coupe of different situations, but could easily be modified to fit your flow and projects.

A few of my favorites that really save time are things like:
`rename` - which takes in the new name for the branch you want to make and handles making a renamed branch in git
`deleteAll` - which will delete a branch both locally and on the remote origin
`pushUpstream` - which will set your origin for a branch to the name of the local branch

Cool side note! Most of the git commands also have tab completion!

And one of the most useful is `serve`!

The `serve` command has several parms allowing you to set a folder for dart serve or a specific port. The best part is that it will work for both dart and npm projects. It will check for a package.json or .pubspec file and choose the correct command to server the project. 

In the case of npm, I know that people tend to have different commands for serving, well it handles that too, just adding a check for a specific command will include it in the serve test. 

Another very nice thing that is does for Dart comes in the form of busy port checking. When you serve a project with dart, it has a really fun quirk where it will always try to use the same port and fail to server. My function will check if the port is busy that it wasn't to use and continue to check ports until it finds on that isn't busy and then runs the command.

Hopefully these commands are helpful to you, and if they aren't, thanks for at least checking them out. If you have suggestions regarding improvement or some git operations that you know would be super helpful to me, please reach out!