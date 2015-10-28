#! /bin/sh
script_name=$(basename $0)
script_dir=$(cd $(dirname $0) && pwd)
dir_at_exec=$(cd . && pwd)
file_size_GB=1

site_config=$script_dir/site_config.sh
if test -f $site_config; then
    . $site_config
else
    echo "$script_name: not found a file \"`basename $site_config`\" in the directory \"$script_dir\". aborting..." >&2
    exit 1
fi

usage_message=$(cat <<USAGE_MESSAGE
Usage: $script_name <target_dir>
USAGE_MESSAGE)

if test $# -ne 1 || ! test -d $1; then
    echo "$usage_message" >&2
    exit 1
else
    target_dir=$(cd $1 && pwd)
fi

for se_src in $se_nimonic; do
    for se_dst in $se_nimonic; do
        if test $se_src = $se_dst; then
            continue
        fi
        result_dir=$target_dir/from_${se_src}_to_${se_dst}
        if ! test -d $result_dir; then
            continue
        fi
        stdout=$result_dir/std.out
        stderr=$result_dir/std.err

        sum_time=0
        cnt=0
        max_time=0
        min_time=$((1000*1000*1000))
        while read ms; do
            if test $ms -gt $max_time; then
                max_time=$ms
            fi
            if test $ms -lt $min_time; then
                min_time=$ms
            fi
            sum_time=$((sum_time+ms))
            cnt=$((cnt+1))
        done <<< "$(grep 'Transfer took' $stderr | awk '{print $3}')"

        sec_fast=$(echo "scale=2; ($file_size_GB*1024)/($min_time/1000)" | bc -l)
        sec_slow=$(echo "scale=2; ($file_size_GB*1024)/($max_time/1000)" | bc -l)
        sec_avg=$(echo "scale=2; ($cnt*($file_size_GB*1024))/($sum_time/1000)" | bc -l)

        echo "$se_src => $se_dst : $sec_avg MB/sec (fast:$sec_fast/slow:$sec_slow)"
    done
done

exit 0
