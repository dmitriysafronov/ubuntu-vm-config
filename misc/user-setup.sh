#!/bin/bash

# Step: software - misc
apt install -y --no-install-recommends bash-completion tmux mc unzip htop most command-not-found configure-debian psmisc language-pack-ru man-db

# Step: tmux on login
echo -e "if [[ -n \"\$(which tmux)\" ]]; then
\tif [[ -z \"\$TMUX\" ]]; then
\t\ttmux has-session -t login || exec tmux new-session -s login && exec tmux attach-session -d -t login
\tfi
fi" > /etc/profile.d/tmux.sh
