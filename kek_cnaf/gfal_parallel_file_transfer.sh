#! /bin/sh
script_name=$(basename $0)
script_dir=$(cd $(dirname $0) && pwd)
dir_at_exec=$(cd . && pwd)

default_src_site=KEK
default_dst_site=KMI
default_n_tcp=4
default_n_parallel=4
default_n_loop=2
max_n_parallel=10

opt_s=false
opt_d=false
opt_n=false
opt_p=false
opt_l=false

site_config=$script_dir/site_config.sh
if test -f $site_config; then
    . $site_config
else
    echo "$script_name: not found a file \"`basename $site_config`\" in the directory \"$script_dir\". aborting..." >&2
    exit 1
fi

usage_site_candidate=$(echo $se_nimonic | tr ' ' '|')

usage_message=$(cat <<USAGE_MESSAGE
Usage: $script_name [-s <$usage_site_candidate>] [-d <$usage_site_candidate>] [-n <# of tcp streams>] [-p <# of transfer processes>] [-l <# of repeats>]
To transfer a file of 1GB with 2 TCP streams, and with 2 jobs, and then repeat this twice:
$script_name -s KMI -d CNAF -n 2 -p 4 -l 2

This will consequently create a transfer sequence like:
#1
lcg-cp -n 2 srm://KMI/path/to/file.1 srm://CNAF/path/to/file.1 &
lcg-cp -n 2 srm://KMI/path/to/file.2 srm://CNAF/path/to/file.2 &
lcg-cp -n 2 srm://KMI/path/to/file.3 srm://CNAF/path/to/file.3 &
lcg-cp -n 2 srm://KMI/path/to/file.4 srm://CNAF/path/to/file.4 &
#2
lcg-cp -n 2 srm://KMI/path/to/file.1 srm://CNAF/path/to/file.1 &
lcg-cp -n 2 srm://KMI/path/to/file.2 srm://CNAF/path/to/file.2 &
lcg-cp -n 2 srm://KMI/path/to/file.3 srm://CNAF/path/to/file.3 &
lcg-cp -n 2 srm://KMI/path/to/file.4 srm://CNAF/path/to/file.4 &
USAGE_MESSAGE)

function signal_handler() {
    local LASTLINE=$1
    local LASTERR=$2
    local lineno_last_exit=$(cat -n $script_dir/$script_name | tail | grep -e 'exit.*0' | awk '{print $1}')

    if test $LASTLINE -eq $lineno_last_exit; then
        echo "$script_name: [INFO] successfully exited at the line: $LASTLINE (EOF) with return code: $LASTERR."
    elif test $LASTERR -eq 0; then
        echo "$script_name: [WARN] Exited with 0 but not ended at EOF. signal trapped at the line: $LASTLINE with return code: $LASTERR."
    else
        echo "$script_name: [ERR] signal trapped at the line: $LASTLINE with return code: $LASTERR."
    fi
    exit $LASTERR
}

trap 'signal_handler ${LINENO} $?' EXIT HUP INT QUIT TERM

voms-proxy-info --exists > /dev/null 2>&1;
if test $? -ne 0; then
    echo "[ERR] no valid proxy cert." >&2
    exit 1
fi

voms-proxy-info --vo | grep -q belle
if test $? -ne 0; then
    echo "[ERR] found a proxy cert but not for belle." >&2
    exit 1
fi



while getopts s:d:n:p:l:h opt; do
    case $opt in
        s)
            opt_s=true
            src_site=$OPTARG
            ;;
        d)
            opt_d=true
            dst_site=$OPTARG
            ;;
        n)
            opt_n=true
            n_tcp=$OPTARG
            ;;
        p)
            opt_p=true
            n_parallel=$OPTARG
            ;;
        l)
            opt_l=true
            n_loop=$OPTARG
            ;;
        h)
            echo "$usage_message" >&2
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))


#lcg-ls --nobdii --setype srmv2 srm://dcache-se-desy.desy.de:8443/srm/managerv2?SFN=/pnfs/desy.de/belle/user/iwai
#=> srm://${se_desy_endpoint}?SFN=${se_desy_filepath}


if $opt_s; then
    # echo $src_site | grep -qi "$grep_site_candidate"
    valid_site $src_site
    if test $? -eq 0; then
        src_site=$(echo $src_site | tr '[:lower:]' '[:upper:]')
    else
        echo "[ERR] invalid site name src_site=$src_site" >&2
        echo "$usage_message" >&2
        exit 1
    fi
else
    src_site=$default_src_site
fi

if $opt_d; then
    valid_site $dst_site
    if test $? -eq 0; then
        dst_site=$(echo $dst_site | tr '[:lower:]' '[:upper:]')
    else
        echo "[ERR] invalid site name dst_site=$dst_site" >&2
        echo "$usage_message" >&2
        exit 1
    fi
else
    dst_site=$default_dst_site
fi

if test $src_site = $dst_site; then
    echo "$usage_message" >&2
    exit 1
fi

if $opt_n; then
    echo $n_tcp | egrep -q '^[[:digit:]]+$'
    if test $? -ne 0; then
        echo "$usage_message" >&2
        exit 1
    fi
else
    n_tcp=$default_n_tcp
fi

if $opt_p; then
    echo $n_parallel | egrep -q '^[[:digit:]]+$'
    if test $? -ne 0; then
        echo "$usage_message" >&2
        exit 1
    fi
else
    n_parallel=$default_n_parallel
    if test $n_parallel -gt $max_n_parallel; then
        echo "$script_name: [ERR] invalid number \"n_parallel=$n_parallel\". so far max # of parallel transfer is $max_n_parallel." >&2
        exit 1
    fi
fi

if $opt_l; then
    echo $n_loop | egrep -q '^[[:digit:]]+$'
    if test $? -ne 0; then
        echo "$usage_message" >&2
        exit 1
    fi
else
    n_loop=$default_n_loop
fi

# default_src_site=KEK
# default_dst_site=KMI
# default_n_tcp=4
# default_n_parallel=4
# default_n_loop=2

# DEBUG
echo "src_site=$src_site"
echo "dst_site=$dst_site"
echo "n_tcp=$n_tcp"
echo "n_parallel=$n_parallel"
echo "n_loop=$n_loop"

# example below
# [iwai@ccw13 kek_cnaf]$ lcg-cp --verbose --nobdii --srcsetype srmv2 --dstsetype srmv2 srm://kek2-se01.cc.kek.jp:8444/srm/managerv2?SFN=/belle/TMP/1GB srm://dcache-se-desy.desy.de:8443/srm/managerv2?SFN=/pnfs/desy.de/belle/user/iwai/1GB
#=> srm://${se_desy_endpoint}?SFN=${se_desy_filepath}

# echo se_KEK_endpoint=$se_KEK_endpoint
# # eval echo '$HOGE_'$i
# var_src_surl=$(eval echo se_${src_site}_endpoint)
# echo var_src_surl=$var_src_surl
# src_surl=$(eval echo '$'$var_src_surl)
src_surl=$(eval echo srm://'$'$(eval echo se_${src_site}_endpoint)?SFN='$'$(eval echo se_${src_site}_filepath))
dst_filepath_prefix=$(eval echo '$'$(eval echo se_${dst_site}_filepath))
dst_filepath_prefix=$(dirname $dst_filepath_prefix)/from_${src_site}_to_${dst_site}_1GB_$(date +%Y-%m-%d_%H%M%S)
# echo dst_filepath_prefix=$dst_filepath_prefix
dst_surl_prefix=$(eval echo srm://'$'$(eval echo se_${dst_site}_endpoint)?SFN=${dst_filepath_prefix})

# DEBUG
echo src_surl=$src_surl
echo dst_surl_prefix=$dst_surl_prefix

nn=1 && while test $nn -le $n_loop; do
    cmd_del="seq $n_parallel | parallel --jobs $n_parallel 'gfal-rm --verbose ${dst_surl_prefix}_${nn}.{#}'"

    #cmd_transfer="seq $n_parallel | parallel --jobs $n_parallel 'gfal-copy --verbose --nbstreams $n_tcp ${src_surl}.{#} ${dst_surl_prefix}_${nn}.{#}'"
    cmd_transfer="seq $n_parallel | parallel --jobs $n_parallel 'gfal-copy --verbose --checksum ADLER32 --nbstreams $n_tcp ${src_surl}.{#} ${dst_surl_prefix}_${nn}.{#}'"
    _do $cmd_transfer

    if test $? -eq 0; then
        echo "[OK] successfully transfer 1GB of files from $src_site to $dst_site in $n_parallel prallel jobs with $n_tcp tcp streams by $n_loop times repeats."
    else
        echo "[FATAL] error while copying $src_site to $dst_site in $n_parallel parallel jobs with $n_tcp tcp stream(s) in $nn of $n_loop times." >&2
        _do $cmd_del
        exit 1
    fi

    _do $cmd_del

    if test $? -eq 0; then
        echo "[OK] successfully deletion $n_parallel of 1GB files in $dst_site."
    else
        echo "[FATAL] error while deleting files in $dst_site. make sure to delete those files. To check zombie files:" >&2
        zmb_filepath_prefix=$(eval echo '$'$(eval echo se_${dst_site}_filepath))
        zmb_filepath_prefix=$(dirname $zmb_filepath_prefix)/
        zmb_surl_dir=$(eval echo srm://'$'$(eval echo se_${dst_site}_endpoint)?SFN=${zmb_filepath_prefix})
        _do "gfal-ls --verbose --long --human-readable $zmb_surl_dir"
        exit 1
    fi

    nn=$((nn+1))
done

exit 0
