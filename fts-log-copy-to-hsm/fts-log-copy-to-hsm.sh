#! /bin/sh
script_name=$(basename $0)
script_dir=$(cd $(dirname $0) && pwd)
dir_at_exec=$(cd . && pwd)
LANG=POSIX

start_date=$(date)
echo "Staring on $start_date."

# production setup
fts_hostname_short=$(hostname ---short)
dest_dir_root=/hsm/belle2/grid/fts/$fts_hostname/log
source_dir_root=/var/log/fts3/transfers

# dummy setup
# fts_hostname_short=kek2-fts01
# dest_dir_root=/group/ce/ccx/iwai/hsm/belle2/grid/fts/$fts_hostname_short/log
# source_dir_root=/group/ce/ccx/iwai/var/log/fts3/transfers

date_range_backup=7
day=0

temp_dir=$(mktemp -d)

while test $day -lt $date_range_backup; do
    target_date=$(date --date="$day day ago" "+%Y-%m-%d")
    source_dir=$source_dir_root/$target_date
    temp_output_path=$temp_dir/$target_date.tar
    cmd_tar="tar cf $temp_output_path --directory $source_dir_root ./$target_date"

    if test -d $source_dir; then
        echo $cmd_tar
        eval $cmd_tar

        dest_path=$dest_dir_root/$target_date.tar
        md5sum_source=$(md5sum $temp_output_path | awk '{print $1}')

        if test -f $dest_path; then
            # Second or more times copy: overwrite previous ones.
            md5sum_dest=$(md5sum $dest_path | awk '{print $1}')

            # anytime different checksum through gzip filter
            # pass through bzip2 or xz filter, or through no filter
            mtime_dest=$(stat $dest_path | grep 'Modify:')
            ctime_dest=$(stat $dest_path | grep 'Change:')

            if test "$md5sum_source" = "$md5sum_dest"; then
                # exist and same checksum so do nothing
                echo "The log file $(basename $dest_path) exists. The timetamp information is that \"$mtime_dest\" and \"$ctime_dest\". The newly created log file has the same checksum: $md5sum_source. The log file is not copied and older one is kept in place."
            else
                # exist but different so overwrite
                echo "The log file $(basename $dest_path) exists. The timetamp information is that \"$mtime_dest\" and \"$ctime_dest\". The checksum value for the older log file is $md5sum_dest that is different from the newer one: $md5sum_source. The exisiting log file is overwritten with newly created one."
                cmd_cp="cp $temp_output_path $dest_path"
                echo $cmd_cp
                eval $cmd_cp
            fi
        else
            # First copy: just send a file of $temp_output_path to the directory of $dest_dir_root on the HSM
            echo "The log file $(basename $dest_path) does not exist. This is the first time copying a tarball of $target_date."
            cmd_cp="cp $temp_output_path $dest_path"
            echo $cmd_cp
            eval $cmd_cp
        fi
    fi

    day=$(($day+1))
done


cmd_rm="rm -rf $temp_dir"
echo $cmd_rm
eval $cmd_rm


end_date=$(date)
echo "Ending on $end_date."


exit 0
