#!/bin/bash

##############################################################################################
#
# how to build BHB27 kernel, kernel for Moto MAXX apq8084
# the things to edit here are:
#
# $CROSS_COMPILE, path to yours toolchain
# $FOLDER path of the kernel tree on your build machine
# and $ZIPNAME name of the install zip
#
# you may config ./bashrc so the kernel can be build with one command on the terminal by:
#
# placing a line like this... alias bk='home/your_user/kernel_folder/build/how_to_build_this.sh' ... ex..
# alias bk='/home/fella/m/kernel1/motorola/apq8084/build/how_to_build_this.sh'
# place it to the end of ./bashrc file that is hide under home *after save ./bashrc restart the terminal
#
# Is need the below lib and bin on the build machine so "sudo apt-get install" the below if you don't, most ROM need this also, if you use the machine for ROM build you must have it
#
#sudo apt-get update
#sudo apt-get install ccache lzop liblz4-* lzma* liblzma*
# + is need java 
#sudo apt-get install  openjdk-7-jre openjdk-7-jdk
# Check the /build/build_log.txt for error and warning...
#
# Extras...
#
# to compile wifi from a outside folder, tested but need to make some changes if will use it, like cp qcacld-2.0 to temp folder so it get clean before it build...
#
# make -j4 -C temp M=$HOME/qcacld-2.0 O=$HOME/tempp ARCH=arm CROSS_COMPILE=$HOME/m/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- KCFLAGS=-mno-android modules WLAN_ROOT=$HOME/qcacld-2.0 MODNAME=wlan BOARD_PLATFORM=apq8084 CONFIG_QCA_CLD_WLAN=m WLAN_OPEN_SOURCE=1
#
#zipsigner.jar source from magisk info here https://forum.xda-developers.com/android/software-hacking/dev-complete-shell-script-flashable-zip-t2934449/post56621542
#
##############################################################################################
#timer counter
START=$(date +%s.%N);
START2="$(date)";
echo -e "\nBHB27-Kernel build start $(date)\n";

#kernel folder yours folder
FOLDER=$HOME/android/apq8084/;
cd $FOLDER;

# CROSS_COMPILE toolchain folder
# latest tools may need this https://forum.xda-developers.com/showpost.php?p=73219523&postcount=42
#export CROSS_COMPILE=$HOME/android/n/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi-
#export CROSS_COMPILE=$HOME/android/temp/arm-eabi-4.9/bin/arm-eabi-
export CROSS_COMPILE=$HOME/android/temp/arm-eabi-4.9-ubertc/bin/arm-eabi-
#export CROSS_COMPILE=$HOME/android/temp/arm-eabi-7.x-ubertc/bin/arm-eabi-
#export CROSS_COMPILE=$HOME/android/temp/arm-eabi-8.x-ubertc/bin/arm-eabi-
#export CROSS_COMPILE=$HOME/android/temp/arm-linaro-linux-gnueabi-7.x/bin/arm-linaro-linux-gnueabi-
#kernel zip name
ZIPNAME="BHB27-Kernel-V93.zip";

#arch and out folder
export ARCH=arm
export KBUILD_OUTPUT=./build/temp

echo -e "\nIn $rom - Clean build?\n empty = Yes\n"
read -r -t 15 clean
echo -e "\nYou choose: $clean"

if [ -z "$clean" ]; then

	# Clean temp directory
	echo -e "\nCleaning temp directory\n";
	rm -rf ./build/temp
	rm -rf ./build/bhbkernel/modules/*
	mkdir ./build/temp

	# Making started
	make clean && make mrproper

fi

# change -j4 to -j# number of cores to do the job... the log.txt here are the build logs to check if error stop the kernel build
time make bhb27kernel_defconfig && time make -j8 2>&1 | tee ./build/build_log.txt && ./build/dtbToolCM -2 -o ./build/temp/arch/arm/boot/dt.img -s 4096 -p ./build/temp/scripts/dtc/ ./build/temp/arch/arm/boot/dts/
lz4 -9 ./build/temp/arch/arm/boot/dt.img

# check if kernel build ok
if [ ! -e ./build/temp/arch/arm/boot/zImage ]; then
	echo -e "\n${bldred}Kernel Not build! Check build_log.txt${txtrst}\n"
	grep -B 3 -C 6 -r error: build/build_log.txt
	grep -B 3 -C 6 -r warn build/build_log.txt
	exit 1;
else if [ ! -e ./build/temp/arch/arm/boot/dt.img.lz4 ]; then
	echo -e "\n${bldred}dtb Not build! Check build_log.txt${txtrst}\n"
	grep -B 3 -C 6 -r error: build/build_log.txt
	grep -B 3 -C 6 -r warn build/build_log.txt
	exit 1;
else
	# moving modules to zip folder
	cd ./build/temp
	find  -iname '*.ko' -exec cp -rf '{}' ../bhbkernel/modules/ \;
	cd -
	# strip modules 
	${CROSS_COMPILE}strip --strip-unneeded ./build/bhbkernel/modules/*
	mkdir ./build/bhbkernel/modules/qca_cld
	mv ./build/bhbkernel/modules/wlan.ko ./build/bhbkernel/modules/qca_cld/qca_cld_wlan.ko
fi;
fi;

# check if wifi build ok
if [ ! -e ./build/bhbkernel/modules/qca_cld/qca_cld_wlan.ko ]; then
	echo -e "$\n{bldred}Wifi module not build check build_log.txt${txtrst}\n"
	grep -B 3 -C 6 -r error: build/build_log.txt
	grep -B 3 -C 6 -r warn build/build_log.txt
	exit 1;
else
	cp -rf ./drivers/staging/qcacld-2.0/firmware_bin/WCNSS_qcom_cfg.ini ./build/bhbkernel/system/etc/wifi/WCNSS_qcom_cfg.ini
	cp -rf ./drivers/staging/qcacld-2.0/firmware_bin/WCNSS_qcom_wlan_nv.bin ./build/bhbkernel/system/etc/wifi/WCNSS_qcom_wlan_nv.bin
	cp -rf ./drivers/staging/qcacld-2.0/firmware_bin/WCNSS_cfg.dat ./build/bhbkernel/system/etc/firmware/wlan/qca_cld/WCNSS_cfg.dat
	cp -rf ./build/temp/arch/arm/boot/zImage ./build/bhbkernel/zImage
	cp -rf ./build/temp/arch/arm/boot/dt.img.lz4 ./build/bhbkernel/dtb
        rm -rf ./build/*.zip
        7za a -tzip -r ./build/build.zip ./build/bhbkernel/* '-x!README.md'  '-x!*.gitignore' > /dev/null
        java -jar ./build/zipsigner.jar './build/build.zip' './build/'$ZIPNAME
        rm -rf ./build/bhbkernel/system/etc/wifi/WCNSS_qcom_cfg.ini
        rm -rf ./build/bhbkernel/system/etc/wifi/WCNSS_qcom_wlan_nv.bin
        rm -rf ./build/bhbkernel/system/etc/firmware/wlan/qca_cld/WCNSS_cfg.dat
	echo -e "\nKernel Build OK zip file at... $FOLDER build/bhbkernel/$ZIPNAME \n";
fi;

# final time display *cosmetic...
END2="$(date)";
END=$(date +%s.%N);
echo -e "\nBuild start $START2";
echo -e "Build end   $END2 \n";
echo -e "\n${bldgrn}Total time elapsed: ${txtrst}${grn}$(echo "($END - $START) / 60"|bc ):$(echo "(($END - $START) - (($END - $START) / 60) * 60)"|bc ) (minutes:seconds). ${txtrst}\n";

