#!/bin/bash
#-- Arch Linux --
echo -e "\e[1;31mUpdating Flatpak\e[0m \n"
flatpak update # Update Flatpak Packages
echo -e "\e[1;38;5;214mUpdating Arch Linux Package Manager\e[0m \n"
sudo pacman -Syu # Update Pacman Package Manager
echo -e "\e[1;33mUpdating the AUR\e[0m \n"
yay -Syu # Update AUR

#-- Python --
echo -e "\e[1;32mUpdating Python Packages\e[0m \n"
pip install --upgrade pip 
# Update Conda
echo -e "\e[1;34mUpdating Anaconda\e[0m \n"
conda config --add channels default 
conda update --all -y 

#-- JavaScript --
echo -e "\e[1;35mUpdating JavaScript Packages\e[0m \n"
npm update #Update JavaScript Packages

