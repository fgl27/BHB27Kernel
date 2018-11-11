#!/bin/bash

##############################################################################################
#
# how to build BHB27 kernel, kernel for Moto MAXX apq8084
# the things to edit here are:
#
# $CROSS_COMPILE, path to the toolchain you wanna to use
# $ZIPNAME the name of the final zip file, if you wanna to change
# $CORES the number of cores to do the compiling job... 
#
# Check the /build/build_log.txt for error and warning...
#
# you may wanna to add a alias to the ./bashrc so the kernel can be build with one simple command on the terminal by:
#
# placing a line like this... alias bk='home/your_user/kernel_folder/build/how_to_build_this.sh' ... ex..
# alias bk='$HOME/apq8084/build/how_to_build_this.sh'
# place it to the end of ./bashrc file that is hide under home *after save ./bashrc restart the terminal, and start this .sh by
#	bk
#
# Help:
#
# Is need to install the below OS dependencies
#
#	sudo apt-get update
#	sudo apt-get install ccache lzop liblz4-* lzma* liblzma* p7zip-full
#
# and java sdk
#
#	sudo add-apt-repository ppa:openjdk-r/ppa
#	sudo apt-get update
#	sudo apt-get install openjdk-8-jdk
#
#Toolchaing used:
#
#https://bitbucket.org/matthewdalex/arm-eabi-4.9
#
# Missing gcc libs libfl.so.2 and libmpfr.so.4
#they must be on this folder (https://github.com/bhb27/scripts/tree/master/etc) or bellow links
#https://archives.pclosusers.com/kde4/pclinuxos/apt/pclinuxos/64bit/RPMS.x86_64/
#https://drive.google.com/file/d/0B0LnTbgUOuxYMHJCcl9RTEJXUjA/edit
#
#To install fallow the bellow
#
#	cd folder libfl
#	cp libfl.so.2.0.0 /usr/lib/
#	sudo chmod 755 /usr/lib/libfl.so.2.0.0
#	sudo ln -s /usr/lib/libfl.so.2.0.0 /usr/lib/libfl.so
#	sudo ln -s /usr/lib/libfl.so.2.0.0 /usr/lib/libfl.so.2
#	sudo ln -s /usr/lib/libfl.so.2.0.0 /usr/lib/x86_64-linux-gnu/libfl.so.2
#
#	sudo alien -i  lib64mpfr4-3.1.2-4-omv2014.0.x86_64.rpm 
#	sudo ln -s /usr/lib64/libmpfr.so.4 /usr/lib/libmpfr.so.4
#	sudo ln -s /usr/lib64/libmpfr.so.4 /usr/lib/libmpfr.so
#	sudo ln -s /usr/lib64/libmpfr.so.4 /usr/lib/x86_64-linux-gnu/libmpfr.so.4
#
# Extras:
#
# to compile wifi from a outside folder, tested but need to make some changes if will use it, like cp qcacld-2.0 to temp folder so it get clean before it build...
#
# make -j4 -C temp M=$HOME/qcacld-2.0 O=$HOME/tempp ARCH=arm CROSS_COMPILE=$HOME/m/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- KCFLAGS=-mno-android modules WLAN_ROOT=$HOME/qcacld-2.0 MODNAME=wlan BOARD_PLATFORM=apq8084 CONFIG_QCA_CLD_WLAN=m WLAN_OPEN_SOURCE=1
#
#zipsigner.jar source from magisk shared here https://forum.xda-developers.com/android/software-hacking/dev-complete-shell-script-flashable-zip-t2934449/post56621542
#
##############################################################################################

# CROSS_COMPILE toolchain folder
# latest tools may need this https://forum.xda-developers.com/showpost.php?p=73219523&postcount=42
#export CROSS_COMPILE=$HOME/android/n/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi-
export CROSS_COMPILE=$HOME/android/temp/uber_arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
#export CROSS_COMPILE=$HOME/android/temp/arm-eabi-4.9-ubertc/bin/arm-eabi-
#export CROSS_COMPILE=$HOME/android/temp/arm-eabi-7.x-ubertc/bin/arm-eabi-
#export CROSS_COMPILE=$HOME/android/temp/arm-eabi-8.x-ubertc/bin/arm-eabi-
#export CROSS_COMPILE=$HOME/android/temp/arm-linaro-linux-gnueabi-7.x/bin/arm-linaro-linux-gnueabi-

#kernel zip name
ZIPNAME="BHB27-Kernel-Oreo-V9.20.zip";

#core, the number of cores to do the compiling job... 
CORES=8;

#I don't recommend to change anything bellow here

#timer counter
START=$(date +%s.%N);
START2="$(date)";
echo -e "\nBHB27-Kernel build start $(date)\n";

#kernel folder yours folder
FOLDER="$(dirname ""$(dirname "$0")"")";
cd $FOLDER;

git status | head -1
echo -e "\nAvailable branch to build: \n"
ls .git/logs/refs/remotes/origin/ | grep -v 'HEAD'

echo -e "\nChoose the branch to build:\nempty keep the same"
read input_variable
if [ -z "$input_variable" ]; then
	echo -e "keep the same branch"
else
	echo -e "You choose: $input_variable trying to change the branch\n"
	git checkout $input_variable
fi

#arch and out folder
export ARCH=arm
export KBUILD_OUTPUT=./build/temp

echo -e "\nClean temp build folder?\n empty = Yes\n"
read -r -t 15 clean
echo -e "\nYou choose: $clean"

if [ -z "$clean" ]; then

	# Clean temp directory
	echo -e "\nCleaning temp directory\n";
	rm -rf ./build/temp
	mkdir ./build/temp

	# Making started
	make clean && make mrproper
fi

# Remove module that may be there from N_c branch build
rm -rf ./build/bhbkernel/modules/*

if [ ! -d "./build/temp" ]; then
	mkdir ./build/temp
fi

# the log.txt here are the build logs to check if error stop the kernel build
time make bhb27kernel_defconfig && time make -j$CORES 2>&1 | tee ./build/build_log.txt && ./build/dtbToolCM -2 -o ./build/temp/arch/arm/boot/dt.img -s 4096 -p ./build/temp/scripts/dtc/ ./build/temp/arch/arm/boot/dts/
lz4 -9 ./build/temp/arch/arm/boot/dt.img

# check if kernel build ok
if [ ! -e ./build/temp/arch/arm/boot/zImage ]; then
	echo -e "\nKernel Not build! Check build_log.txt\n"
	grep -B 3 -C 6 -r error: build/build_log.txt
	grep -B 3 -C 6 -r warn build/build_log.txt
	exit 1;
elif [ ! -e ./build/temp/arch/arm/boot/dt.img.lz4 ]; then
	echo -e "\ndtb Not build! Check build_log.txt\n"
	grep -B 3 -C 6 -r error: build/build_log.txt
	grep -B 3 -C 6 -r warn build/build_log.txt
	exit 1;
else
	cp -rf ./build/temp/arch/arm/boot/zImage ./build/bhbkernel/zImage
	cp -rf ./build/temp/arch/arm/boot/dt.img.lz4 ./build/bhbkernel/dtb
	rm -rf ./build/*.zip

	7za a -tzip -r ./build/build.zip ./build/bhbkernel/* '-x!README.md'  '-x!*.gitignore' > /dev/null
	java -jar ./build/zipsigner.jar './build/build.zip' './build/'$ZIPNAME
	rm './build/build.zip'
	echo -e "\nKernel Build OK zip file at... $FOLDER build/bhbkernel/$ZIPNAME \n";
fi;

# final time display *cosmetic...
END2="$(date)";
END=$(date +%s.%N);
echo -e "\nBuild start $START2";
echo -e "Build end   $END2 \n";
echo -e "\nTotal time elapsed: $(echo "($END - $START) / 60"|bc ):$(echo "(($END - $START) - (($END - $START) / 60) * 60)"|bc ) (minutes:seconds). \n";

