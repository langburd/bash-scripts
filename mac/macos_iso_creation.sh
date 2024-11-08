#!/bin/bash

# https://www.itech4mac.net/virtualmachines/convert-macos-sonoma-installer-to-iso-image

# Install macOS Sonoma from the App Store (using https://github.com/mas-cli/mas or manually)
mas install 2139217083 # macOS Sonoma (14.6.1)

# Create a dmg container on the desktop of a size (16 BG) named "Sonoma.dmg"
hdiutil create -o ~/Desktop/Sonoma -size 16000m -volname Sonoma -layout SPUD -fs HFS+J

# Mount the Sonoma.dmg container into your device
hdiutil attach ~/Desktop/Sonoma.dmg -noverify -mountpoint /Volumes/Sonoma

# Create a bootable macOS Sonoma installer into the created dmg container
sudo /Applications/Install\ macOS\ Sonoma.app/Contents/Resources/createinstallmedia --volume /Volumes/Sonoma --nointeraction

# Unmount the Sonoma.dmg container
hdiutil detach /Volumes/Install\ macOS\ Sonoma

# Convert the Sonoma.dmg container into an iso image
hdiutil convert ~/Desktop/Sonoma.dmg -format UDTO -o ~/Desktop/Sonoma
mv ~/Desktop/Sonoma.cdr ~/Desktop/Sonoma.iso
