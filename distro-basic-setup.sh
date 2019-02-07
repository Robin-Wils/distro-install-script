#!/bin/bash

# This script assumes that your computer is connected to the internet during the
# execution of it. This was made for devuan/debian netinstall.
# I am not responsible for broken systems or lost files,

# RUN THIS AT YOUR OWN RISK.
# THIS SCRIPT HAS NOT BEEN TESTED YET.


# CONFIG
# ______

# Packages to install,
# the script uses guix to install these.

# Different users can have different packages in guix.
# This script installs all the packages for the non-root user.
readonly GUIX_PACKAGES="libreoffice testdisk keepassxc acpi mplayer icecat git 
wicd maim xrandr"

# Default packages of the netinstaller which you don't want.
# Apt will remove those packages.
readonly PACKAGES_TO_REMOVE="bluez bluetooth vim-common vim-tiny vi"

# The email address which you use for git
# You don't have to use a grep but it is useful,
# just in case that I change my email.
readonly GIT_EMAIL=$(wget -qO- https://gitlab.com/RobinWils \
                         | grep -o '[[:alnum:]+\.\_\-]*@[[:alnum:]+\.\_\-]*' \
                         | tail -1)

# The username of your non-root user
readonly USERNAME="rmw"

# The prop wifi debian package
# Leave this empty if you don't need a prop WiFi driver.
readonly PROP_WIFI="firmware-iwlwifi"

# The Debian repo for the prop WiFi drivers
readonly DEBIAN_REPO="deb http://http.us.debian.org/debian/ 
testing non-free contrib main"

# Custom host file (which blocks ads) 
readonly HOSTS=\
         "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"

# X and Emacs might crash or give errors
# if you remove one of these packages.
readonly ESSENTIAL_GUIX_PACKAGES="font-hack font-misc-misc xinit 
xf86-input-evdev emacs xf86-input-keyboard xf86-input-mouse xf86-input-synaptics 
xf86-video-nouveau sct"


# SCRIPT
# ______

if [ "$EUID" -ne 0 ]
then echo "You need to be root to execute this script."
     exit 1
fi

# Prop WiFi driver
if ![ -z "$PROP_WIFI" ]
then
    mv /etc/apt/sources.list /etc/apt/sources.list.old
    touch /etc/apt/sources.list
    echo $DEBIAN_REPO >> /etc/apt/sources.list
    apt update
    apt -y --no-install-recommends install $PROP_WIFI
    mv /etc/apt/sources.list.old /etc/apt/sources.list
    apt update
fi

# Guix package manager
gpg --keyserver pool.sks-keyservers.net \
    --recv-keys 3CE464558A84FDC69DB40CFB090B11993D9AEBB5
bash <(\
       curl -s \
            https://git.savannah.gnu.org/cgit/guix.git/plain/etc/guix-install.sh\
    )

# MAKE SCRIPT FOR GUIX
export GUIX_LOCPATH="$HOME/.guix-profile/lib/locale"
export INFOPATH="$HOME/.guix-profile/share/info${INFOPATH:+:}$INFOPATH"
export PATH="$HOME/.guix-profile/bin:$HOME/.guix-profile/sbin${PATH:+:}$PATH"

# Start guix daemon
/gnu/store/*-guix-*/bin/guix-daemon --build-users-group=guixbuild &
# Setup guix
guix package -i glibc-utf8-locales
export GUIX_LOCPATH="$HOME/.guix-profile/lib/locale"
guix refresh
guix pull
guix package -u

# Remove packages
apt -y purge $PACKAGES_TO_REMOVE

# Install packages
su $USER
guix package -i $ESSENTIAL_GUIX_PACKAGES $GUIX_PACKAGES
exit

# Configure git
git config --global user.name $GIT_EMAIL
git config --global user.email $GIT_EMAIL
git config --global core.editor emacs

# Configure emacs
wget -O ~/.emacs https://gitlab.com/RobinWils/dotfiles/raw/master/.emacs
cp -rf ~/.emacs /home/$USERNAME/.emacs

# Create init script for startx
wget -O ~/.xinitrc https://gitlab.com/RobinWils/dotfiles/raw/master/.xinitrc
cp -rf ~/.xinitrc /home/$USERNAME/.xinitrc

# RICE FIREFOX
# The problem with this part is that the location does not exists until
# someone ran firefox. So this part is not configured yet.
# wget -O ~/.mozilla/firefox/*.default/chrome/userChrome.css \
    # https://gitlab.com/RobinWils/dotfiles/raw/master/userChrome.css

# Replace the default host file
wget -O /etc/hosts $HOSTS

# Give our user ownership on their files
chown -R $USERNAME /home/$USERNAME

# Set the important vars for guix
# I currently run a bash script with this after my system boots.
# Your init system can do this but I didn't take the time to write that yet.

# The first line is commented since we started the daemon already.
# It is not commented in that other script that I mentioned.

# /gnu/store/*-guix-*/bin/guix-daemon --build-users-group=guixbuild &
export GUIX_LOCPATH="$HOME/.guix-profile/lib/locale"
export INFOPATH="$HOME/.guix-profile/share/info${INFOPATH:+:}$INFOPATH"
export PATH="$HOME/.guix-profile/bin:$HOME/.guix-profile/sbin${PATH:+:}$PATH"
exit 0