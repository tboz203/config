# Change Desktop Environment from GNOME to MATE
- `sudo apt remove amazon-workspaces-theme`
- `sudo apt install mate-desktop-environment-extras`
- edit `/var/lib/AccountsService/users/$USER`
  - replace `Session=` with `Session=mate`
  - (or another value from `/usr/share/xsessions/`)
