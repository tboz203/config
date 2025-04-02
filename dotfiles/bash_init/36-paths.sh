# ensure PATH is populated

[[ ! ${_BASH_INIT_PATHS_SET-} ]] || return 0
export _BASH_INIT_PATHS_SET=1

return 0

# pathmungex --replace PATH \
#     ~/.local/bin \
#     ~/go/bin \
#     /usr/local/go/bin \
#     /usr/local/bin \
#     /usr/bin

# pathmungex PATH "${JAVA_HOME-/nowhere}/bin"

# okay, first i need to work out what the hell I want. i want the path to look
# more-or-less like what I have below. the significant change is that I want
# windows crud lower in the lineup, but there are also a few things I want
# pulled out. however, i don't want to make these changes directly to my path;
# i'd prefer to have something (i think `cleanpath` right now) that modifies my
# existing path, so that when things are added upstream those changes are still
# reflected here

/c/Users/tbozeman/AppData/Local/scoop/shims
/c/Users/tbozeman/AppData/Local/bin
/c/Users/tbozeman/AppData/Local/scoop/apps/corretto17-jdk/current/bin
/c/Users/tbozeman/AppData/Local/Programs/Python/Python312/Scripts
/c/Users/tbozeman/AppData/Local/Programs/Python/Python312
/c/Users/tbozeman/AppData/Local/Programs/Python/Launcher
/c/Users/tbozeman/AppData/Local/Programs/Neovim/bin
/c/Users/tbozeman/AppData/Local/Programs/nodejs
/c/Users/tbozeman/AppData/Local/go/bin
/c/Users/tbozeman/AppData/Local/Programs/go/bin
/c/Users/tbozeman/AppData/Local/Programs/protobuf/bin
/c/msys64/clang64/bin
/mingw64/bin
/usr/bin
/c/msys64/usr/bin
/c/Users/tbozeman/AppData/Local/Microsoft/WindowsApps
/c/WINDOWS/system32
/c/WINDOWS
/c/WINDOWS/System32/Wbem
/c/WINDOWS/System32/WindowsPowerShell/v1.0
/c/WINDOWS/System32/OpenSSH
/c/Program Files/Microsoft VS Code/bin
/c/Program Files/PuTTY

/mingw64/bin
/usr/bin
/c/Program Files/Amazon Corretto/jdk21.0.4_7/bin
/c/WINDOWS/system32
/c/WINDOWS
/c/WINDOWS/System32/Wbem
/c/WINDOWS/System32/WindowsPowerShell/v1.0
/c/WINDOWS/System32/OpenSSH
/c/Program Files (x86)/Common Files/Pulse Secure/VC142.CRT/X64
/c/Program Files (x86)/Common Files/Pulse Secure/VC142.CRT/X86
/c/Program Files/Microsoft VS Code/bin
/c/Program Files/PuTTY
/c/msys64/clang64/bin
/c/Users/tbozeman/AppData/Local/scoop/shims
/c/Users/tbozeman/AppData/Local/bin
/c/Users/tbozeman/AppData/Local/scoop/apps/corretto17-jdk/current/bin
/cmd
/c/Users/tbozeman/AppData/Local/Programs/Python/Python312/Scripts
/c/Users/tbozeman/AppData/Local/Programs/Python/Python312
/c/Users/tbozeman/AppData/Local/Programs/Python/Launcher
/c/Users/tbozeman/AppData/Local/Programs/Neovim/bin
/c/Users/tbozeman/AppData/Local/Programs/nodejs
/c/Users/tbozeman/AppData/Local/go/bin
/c/Users/tbozeman/AppData/Local/Programs/go/bin
/c/Users/tbozeman/AppData/Local/Programs/protobuf/bin
/c/Users/tbozeman/AppData/Local/Microsoft/WindowsApps
