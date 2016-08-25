set -e
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" || true
rsync -CvzrlptD files/home/ ~/
