#!/bin/bash
# Author : luffah
# Date : 7 nov 2017
# 
# Script to enable serial console output on Yunohost installation
#
# Script inspired by
# Howto to get Debian Jessie to install via the serial console using boot media
# http://pcengines.info/forums/?page=post&id=51C5DE97-2D0E-40E9-BFF7-7F7FE30E18FE

# Assuming CDROMM name don't change
YUNOHOSTCDNAME="CDROM"
# The rate to communicate by the serial port to the board
BAUDRATE=115200 # apu2

usage(){
  echo "Usage : "
  echo "  $0 <ISO_FILE>             # Build a new <ISO_FILE> with updated SYSLINUX informations to boot in serial console"
  echo "  $0 dd <ISO_FILE> <DEVICE> # Write iso to the device"
  echo "Advanced usage : "
  echo "  $0 extract_iso <ISO_FILE> # Return the directory name containing datas from <ISO_FILE>"
  echo "  $0 syslinux <DIRNAME>     # Update SYSLINUX informations to boot in serialboot"
  echo "  $0 toiso <DIRNAME> <ISO_FILE> # Make an iso from datas contained in the directory"
  echo "Where : "
  echo "  <ISO_FILE> is a disk image '.iso' file"
  echo "  <DEVICE> is the target device (e.g. /dev/sdc)"
  echo "  <DIRNAME> is the directory used to prepare the new disk image"
  echo "BONUS : "
  echo "  $0 mincom <TTY> # To use console with a concrete serial port (e.g. /dev/ttyUSB0) "
  echo "  $0 socat <TTY> # To use console with a virtual serial port of type 'host pipe' (e.g. /tmp/yunohost)"
}
if [ -z $1 ]; then usage; exit 1;fi

prepare_syslinux(){
  chmod 777 -R  $1/isolinux/
  echo  """
  # D-I config version 2.0
  # search path for the c32 support libraries (libcom32, libutil etc.)
  serial 0 ${BAUDRATE}
  console 0
  path
  include menu.cfg
  #default vesamenu.c32
  #prompt 0
  #timeout 0
""" >  $1/isolinux/isolinux.cfg
  echo """
  label install
  menu label ^Install
  menu default
  kernel /install.amd/vmlinuz 
  append preseed/file=/cdrom/simple-cdd/default.preseed vga=off console=ttyS0,${BAUDRATE}n8 initrd=/install.amd/initrd.gz --- console=ttyS0,${BAUDRATE}n8
""" > $1/isolinux/txt.cfg
  echo """
  label expert
  menu label ^Expert install
  kernel /install.amd/vmlinuz
  append priority=low preseed/file=/cdrom/simple-cdd/default.preseed vga=off console=ttyS0,${BAUDRATE}n8 initrd=/install.amd/initrd.gz --- console=ttyS0,${BAUDRATE}n8
  include rqtxt.cfg
  label auto
  menu label ^Automated install
  kernel /install.amd/vmlinuz
  append auto=true priority=critical preseed/file=/cdrom/simple-cdd/default.preseed vga=off console=ttyS0,${BAUDRATE}n8 initrd=/install.amd/initrd.gz --- console=ttyS0,${BAUDRATE}n8
""" > $1/isolinux/adtxt.cfg 
  chmod 555  $1/isolinux/
  chmod 444  $1/isolinux/*
  return 0
}
log(){
  echo $1 >&2
}
extract_iso(){
  ISONAME="`basename $1 | sed 's/\.iso//'`"
  MNTNAME="/tmp/iso-${ISONAME}"
  DIRNAME="./${ISONAME}-serialboot-${BAUDRATE}"
  log "Mount point is ${MNTNAME}"
  if mount | grep $1
  then
    log "Umount $1 before"
    return 1
  fi
  if mkdir ${MNTNAME}
  then
    mount -o loop $1 ${MNTNAME}
    log "Extract to  ${DIRNAME}"
    shopt -s dotglob ; # '*' should also match (hidden) '.dot' files
    cp -rT ${MNTNAME} ${DIRNAME} ;
    log "Unmount ${MNTNAME}"
    umount ${MNTNAME}
    rmdir ${MNTNAME}
    echo "${DIRNAME}"
    return 0
  else
    return 1
  fi
}
case $1 in
  make)
    if [ -z $2 ]
    then
      echo "You have to precise Yunohost iso in argument"
      exit 1
    fi
    DIRNAME="`extract_iso $2`" &&
      read &&
    bash $0 syslinux ${DIRNAME} && read &&
    bash $0 toiso ${DIRNAME} ${DIRNAME}.iso 
    exit $?
  ;;
  syslinux)
    if [ -n $2 ]
    then
      prepare_syslinux $2
      exit $?
    fi
    exit 1
    ;;
  toiso)
    if [ -n $2 -a -n $3 ]
    then
      xorriso -as mkisofs -r -J -joliet-long -l -cache-inodes  \
        -isohybrid-mbr `locate isohdpfx.bin` -partition_offset 16 \
        -A "${YUNOHOSTCDNAME}" -b isolinux/isolinux.bin -c isolinux/boot.cat   -no-emul-boot -boot-load-size 4 -boot-info-table   -o $3 $2
      echo "ISO is build"
      echo "To write it to a disk , do "
      echo "'$0 dd $3 /dev/sdX' where sdXY is the device to write."
    fi
    exit $?
    ;;
  dd)
    if [ -n $2 -a -n $3 ]
    then
      mount | grep $3 || \
        file -s $3 && \
        dd if=$2 of=$3 bs=1k
    fi
    exit $?
    ;;
  extract-iso)
    extract_iso $2
    ;;
  minicom)
    # for the serial port (e.g. /dev/ttyUSB0)
    if [ -n $2 ]
    then
    minicom -b ${BAUDRATE} -D $2
    exit $?
    fi
    exit 1
    ;;
  socat)
    # for a virtual serial port of type 'host pipe' (e.g. /tmp/yunohost)
    if [ -n $2 ]
    then
    socat unix-connect:$2   stdio,raw,echo=0,escape=0x11,icanon=0 
    exit $?
    fi
    exit 0
    ;;
esac
sudo bash -x $0 make $1 
