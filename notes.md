# Notes

(_esp w/r/t setup_)

- brew needs to come early in the process
- we knew having those `curl` install commands in `bash_init` was a bad call...
- should `install.py` also do dependency installation?? maybe not
  - ... but there should be some kind of scripted installation
- some of those install scripts have options for brew-less install -- get rid of those?
- how do we handle fonts?
- powerline

    ```sh
    sudo apt install python3 python3-pip python3-venv
    sudo ln -s /usr/bin/python3 /usr/bin/python
    python -m venv venv
    ./venv/bin/pip install uv
    ./venv/bin/uv tool install uv
    uv tool install --python 3.12 powerline-status
    # may also want this
    pushd /home/linuxbrew/.linuxbrew/bin && ln -s python3 python && popd
    ```
