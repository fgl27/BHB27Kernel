#!/bin/bash
# Simple sh to automatic generate a file with source and device specif git commit changes to use in a github wiki pages or file.md
# like this:
# https://github.com/bhb27/scripts/blob/master/etc/changelogs/Changelog_BHB27KERNEL.md
# file.md can work with more data or have more lines then a page wiki

# input variables set the below the rest must be automatic
kernel_tree="$HOME/android/apq8084/";
kernel_name="BHB27KERNEL"
# input variables end

export Changelog=$kernel_tree/build/Changelog.md

if [ -f $Changelog ];
then
	rm -f $Changelog
fi

touch $Changelog

# Print something
echo -e "Generating changelog $kernel_name...\n"
#amount of days
echo -e "How many days to log?"
read -r -t 15 days_to_log
echo -e "Amount of days to log: $days_to_log"

echo "### [This Changelog was generated automatically Click here to see how](https://github.com/bhb27/BHB27Kernel/tree/N_c/build/changelog.sh)"    >> $Changelog;
echo >> $Changelog;

echo "$kernel_name source Changelog:"    >> $Changelog;
echo '============================================================' >> $Changelog;
echo >> $Changelog;

cd $source_tree

git_log_tree() {
	cd $1
	git log --oneline --after=$2 --until=$3 | sed 's/^//' | while read string; do
		temp_one=${string:8}
                temp_two="${temp_one// /%20}"
		temp_two="${temp_two//(/%28}"
		temp_two="${temp_two//#/%23}"
		temp_two="${temp_two//)/%29}"
		temp_two="${temp_two//@/%40}"
		temp_two="${temp_two//:/%3A}"
		temp_two="${temp_two//\'/%27}"
		temp_two="${temp_two//\`/%60}"
		echo "* [$string](https://github.com/bhb27/BHB27Kernel/search?q=${temp_two}&type=Commits)" >> $Changelog;
        done
	cd -  > /dev/null
	echo >> $Changelog;
}

contains() {
    string="$1"
    substring="$2"
    if test "${string#*$substring}" != "$string"
    then
        return 0    # $substring is in $string
    else
        return 1    # $substring is not in $string
    fi
}


for i in $(seq $days_to_log);
do	
export After_Date=`date --date="$i days ago" +%m-%d-%Y`
k=$(expr $i - 1)
	export Until_Date=`date --date="$k days ago" +%m-%d-%Y`

	echo "Generating Day number:$i $Until_Date..."
	kernel=$(cd $kernel_tree && git log --oneline --after=$After_Date --until=$Until_Date);

	if [ -n "${kernel##+([:space:])}" ]; then
		# Line with after --- until was too long for a small ListView
		echo "$Until_Date" >> $Changelog;
		echo '====================' >> $Changelog;
		echo >> $Changelog;
	fi

	if [ -n "${kernel##+([:space:])}" ]; then
                git_log_tree $kernel_tree $After_Date $Until_Date
	fi

	if [ -n "${kernel##+([:space:])}" ]; then
		echo "***" >> $Changelog;
		echo >> $Changelog;
	fi

done

sed -i 's/* project /#### /g' $Changelog
echo >> $Changelog;

echo "### [This Changelog was generated automatically Click here to see how](https://github.com/bhb27/BHB27Kernel/tree/N_c/build/changelog.sh)"    >> $Changelog;

echo -e "\nChangelog generated file in $Changelog\n"

exit;
