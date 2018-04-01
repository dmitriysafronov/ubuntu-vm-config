#!/bin/bash

# Step: software - misc
apt install -y --no-install-recommends bash-completion tmux mc unzip htop most command-not-found configure-debian psmisc man-db ncdu

# Step: tmux on login
echo -e "if [[ $(id -u) -eq 0 || $(id -u) -ge 1000 ]]; then
\tif [[ -n \"$(which tmux)\" ]]; then
\t\tif [[ -z \"$TMUX\" ]]; then
\t\t\ttmux has-session -t login || exec tmux new-session -s login && exec tmux attach-session -d -t login
\t\tfi
\tfi
fi
" > /etc/profile.d/tmux.sh
