# Setup Notes

0. wsl config

    ```ini
    [general]
    instanceIdleTimeout = -1

    [wsl2]
    vmIdleTimeout = -1
    ```

1. what all "package managers" do I have?
    - apt
    - brew
    - ... npm?

2. what other things need to be periodically updated?
    - nvim / lazyvim / mason
    - uv tool
    - rustup

3. keep using cobbled together scripts, or look into CM/IAC tools?
    - e.g. puppet?

4. a cron job that runs at boot?

5. will I ever actually fix bash completion?
    - see `/home/linuxbrew/.linuxbrew/etc/bash_completion.d`

6. for windows: scoop (& maybe also custom powershell script? we'll see)
