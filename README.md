# About this version 
I used the following tutorial to make an iso for pc-engines apu2:

"Howto install Debian Jessie (8.2) via the serial console using boot media (USB stick)"
http://pcengines.info/forums/?page=post&id=51C5DE97-2D0E-40E9-BFF7-7F7FE30E18F

Instead of taking the debian CD i take yunohost-jessie-0127171259-amd64-stable.iso

Next, i made `yunohost-mkserialiso.sh` to have all the procedure in a script.

# Procedure / What does the script ?

## Prerequisite
You need to : `sudo apt install syslinux isolinux xorriso`

(Optionnally : `sudo apt install minicom socat`)

## A place to work
Have some directory to work (for example `mkdir yunohost-serial;cd yunohost-serial;`).
In fact, if you get the GIT repository, then you already have a place to work. 

## Get a Yunohost iso
Go an iso at https://build.yunohost.org/ and or directly get
https://build.yunohost.org/yunohost-jessie-0127171259-amd64-stable.iso (URL for 2017, november 7th), if the board have 64bit processor .

## Launch the script to make a new iso
To build a new iso file with updated SYSLINUX informations to boot in serial console, do :
`sh yunohost-mkserialiso.sh  yunohost-jessie-0127171259-amd64-stable.iso`
If it didn't fails, you got :
`yunohost-jessie-0127171259-amd64-stable-serialboot-115200.iso`

## Use dd to write the iso 
You can optionnally use `dd` command prepared in the script like that :  
`sh yunohost-mkserialiso.sh dd yunohost-jessie-0127171259-amd64-stable-serialboot-115200.iso /dev/sdX`
where `/dev/sdX` is your USB key device.


# Prepare the installation

Put with the way you can, the iso in your machine. (Virtual ISO / USB port)

## With VirtualBox
In the VirtualBox machine configuration (section 'Serial Ports'),you shall define a 'Host Pipe' nammed '/tmp/yunohost'.

To listen you can use `socat` command prepared in the script like that :  
`sh yunohost-mkserialiso.sh socat /tmp/yunohost`

Note that the listening of port shall start after the virtual machine has started. (Because it doesn't exist before.)

## Real board
For boot sequence, use Putty or Minicom to listen the serial port.
Notice that 'usbserial' module shall be loaded in 'lsmod' in order to have this device.

You have to choose where to install the new system.

You can use `minicom` command prepared in the script like that :  
`sh yunohost-mkserialiso.sh minicom /dev/ttyUSB0`

Note that the listening of port shall begin before the boot sequence.

# Installation
Boot your machine...

