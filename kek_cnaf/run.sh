#! /bin/sh
script_name=$(basename $0)
script_dir=$(cd $(dirname $0) && pwd)
dir_at_exec=$(cd . && pwd)

site_config=$script_dir/site_config.sh
if test -f $site_config; then
    . $site_config
else
    echo "$script_name: not found a file \"`basename $site_config`\" in the directory \"$script_dir\". aborting..." >&2
    exit 1
fi

result_dir_root=$dir_at_exec/${script_name}_$(date +%Y-%m-%d_%H%M%S)
_do mkdir -p $result_dir_root

for se_src in $se_nimonic; do
    for se_dst in $se_nimonic; do
        if test $se_src = $se_dst; then
            continue
        fi
        work_dir=$result_dir_root/from_${se_src}_to_${se_dst}
        _do mkdir -p $work_dir
        cd $work_dir
        cmd_transfer="$script_dir/parallel_file_transfer.sh -s $se_src -d $se_dst -n 10 -p 4 -l 2"
        echo $cmd_transfer
        _do voms-proxy-init -voms belle
        # _do $cmd_transfer
        _do voms-proxy-destroy
        cd $dir_at_exec
    done
done

exit 0
