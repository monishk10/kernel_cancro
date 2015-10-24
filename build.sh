#!/bin/bash
 
# Colorize and add text parameters
red=$(tput setaf 1) 		# red
grn=$(tput setaf 2)             #  green
cya=$(tput setaf 6) 		# cyan
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) # red
bldgrn=${txtbld}$(tput setaf 2) #  green
bldblu=${txtbld}$(tput setaf 4) #  blue
bldcya=${txtbld}$(tput setaf 6) # cyan
txtrst=$(tput sgr0)             # Reset

# CURRENT DIRECTORY WHERE YOU HAVE YOUR KERNEL SOURCE 
KERNEL_DIR=~/kernel/sync/kernel_cancro
# OUTPUT FOLDER WHERE YOU HAVE YOU ANYKERNEL TEMPLET N DTBTOOLCM
KERNEL_OUT=~/kernel/sync/kernel_cancro/zip/kernel_zip
# TOOLCHAIN PATH FOR STRIPING TOOLCHAINS
STRIP=/home/monish/arm-eabi-5.2/bin/arm-eabi-strip
 
#Clean the build
echo -n "${bldcya} Do you wanna clean the build (y/n)? ${txtrst}"
read answer
if echo "$answer" | grep -iq "^y" ;then
    echo -e "${bldgrn} Cleaning the old build ${txtrst}"
    make mrproper
    rm -rf $KERNEL_OUT/dtb
    rm -rf $KERNEL_OUT/zImage
    rm -rf $KERNEL_OUT/../*.zip
    rm -rf $KERNEL_OUT/modules/*
    rm -rf $KERNEL_DIR/arch/arm/boot/*.dtb
fi
     
echo -e "${bldgrn} Setting up Build Environment ${txtrst}"
export KBUILD_BUILD_USER="monish"
export KBUILD_BUILD_HOST="beast"
export ARCH=arm

#ADD THE CORRECT TOOLCHAIN PATH 

export CROSS_COMPILE=/home/monish/arm-eabi-5.2/bin/arm-eabi-
     
     
echo -e "${bldgrn} Building Defconfig ${txtrst}"

# DEFCONFIG NAME YOU WILL BE USING

make cancro_user_defconfig 
     
echo -n "${bldblu}Do you wanna make changes in the defconfig (y/n)? ${txtrst}"
read answer
if echo "$answer" | grep -iq "^y" ;then
        echo -e "${bldgrn} Building Defconfig GUI ${txtrst}"
    make menuconfig
     
    echo -n "${bldblu}Do you wanna save the changes in the defconfig (y/n)? ${txtrst}"
    read answer
	    if echo "$answer" | grep -iq "^y" ;then
	        echo -e "${bldgrn} Building Defconfig GUI ${txtrst}"
	        cp -f .config $KERNEL_DIR/arch/arm/configs/cancro_user_defconfig
    fi
fi
     
# Time of build startup
res1=$(date +%s.%N)
     
echo -e "${bldcya}#####################################################${txtrst}"
echo -e "${bldcya}##############${bldred}STARTING.MOSHI.BUILD${bldcya}###################${txtrst}"
echo -e "${bldcya}#####################################################${txtrst}"
make -j12

if ! [ -a  $KERNEL_DIR/arch/arm/boot/zImage ];
    then
    echo -e "${bldblu} Kernel Compilation failed! Fix the errors! ${txtrst}"
    exit 1
fi
mv $KERNEL_DIR/arch/arm/boot/zImage  $KERNEL_OUT/zImage
     
echo "Copying modules"
find . -name '*.ko' -exec cp {} $KERNEL_OUT/modules/ \;
echo "Stripping modules for size"
$STRIP --strip-unneeded $KERNEL_OUT/modules/*.ko

echo -e "${bldgrn} DTB Build  ${txtrst}"
.$KERNEL/zip/dtbToolCM -2 -o $KERNEL_OUT/dtb -s 2048 -p scripts/dtc/ arch/arm/boot/

if ! [ -a $KERNEL_OUT/dtb ];
    then
    echo -e "${bldblu} DTB Compilation failed! Fix the errors! ${txtrst}"
    exit 1
fi
     
echo -e "${bldgrn} Zipping the Kernel Build  ${txtrst}"
cd $KERNEL_OUT/
zip -r ../MOSHI_Cancro_$(date +%d%m%Y_%H%M) .

OUTZIP=$(find ../*.zip)
cd $KERNEL_DIR

# Get elapsed time
res2=$(date +%s.%N)
echo "${bldgrn}$OUTZIP Compiled Succuessfully in ${txtrst}${bldgrn}$(echo "($res2 - $res1) / 60"|bc ) minutes ($(echo "$res2 - $res1"|bc ) seconds) ${txtrst}"
