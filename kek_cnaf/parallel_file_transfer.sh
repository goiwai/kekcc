#! /bin/sh
script_name=$(basename $0)
script_dir=$(cd $(dirname $0) && pwd)
dir_at_exec=$(cd . && pwd)

voms-proxy-info --exists > /dev/null 2>&1;
if test $? -ne 0; then
    echo "$script_name: no valid proxy cert." >&2
    exit 1
fi

voms-proxy-info --vo | grep -q belle
if test $? -ne 0; then
    echo "$script_name: found a proxy cert but not for belle." >&2
    exit 1
fi


default_src_site=KEK
default_dst_site=KMI
default_n_tcp=4
default_n_parallel=4
default_n_loop=2

opt_s=false
opt_d=false
opt_n=false
opt_p=false
opt_l=false

se_DESY=dcache-se-desy.desy.de
se_KEK=kek2-se01.cc.kek.jp
se_CNAF=storm-fe-archive.cr.cnaf.infn.it
se_KMI=nsrmfe01.hepl.phys.nagoya-u.ac.jp

se_DESY_endpoint=$se_DESY:8443/srm/managerv2
se_KEK_endpoint=$se_KEK:8444/srm/managerv2
se_CNAF_endpoint=$se_CNAF:8444/srm/managerv2
se_KMI_endpoint=$se_KMI:8444/srm/managerv2

se_DESY_filepath=/pnfs/desy.de/belle/user/iwai/1GB
se_KEK_filepath=/belle/TMP/1GB
se_CNAF_filepath=/belle/TMP/1GB
se_KMI_filepath=/belle/TMP/1GB

function _do() {
    local cmd="$*"
    echo "$cmd"
    eval $cmd
    return $?
}

usage_message=$(cat <<USAGE_MESSAGE
Usage: $script_name [-s <KMI|DESY|CNAF|KEK>] [-d <KMI|DESY|CNAF|KEK>] [-n <# of tcp streams>] [-p <# of transfer processes>] [-l <# of repeats>]
To transfer a file of 1GB with 2 TCP streams, and with 2 jobs, and then repeat this twice:
$script_name -s KMI -d CNAF -n 2 -p 4 -l 2

This will consequently create a transfer sequence like:
#1
lcg-cp -n 2 srm://KMI/path/to/file srm://CNAF/path/to/file.1 &
lcg-cp -n 2 srm://KMI/path/to/file srm://CNAF/path/to/file.2 &
lcg-cp -n 2 srm://KMI/path/to/file srm://CNAF/path/to/file.3 &
lcg-cp -n 2 srm://KMI/path/to/file srm://CNAF/path/to/file.4 &
#2
lcg-cp -n 2 srm://KMI/path/to/file srm://CNAF/path/to/file.1 &
lcg-cp -n 2 srm://KMI/path/to/file srm://CNAF/path/to/file.2 &
lcg-cp -n 2 srm://KMI/path/to/file srm://CNAF/path/to/file.3 &
lcg-cp -n 2 srm://KMI/path/to/file srm://CNAF/path/to/file.4 &
USAGE_MESSAGE)

function signal_handler() {
    local LASTLINE=$1
    local LASTERR=$2
    local lineno_last_exit=$(cat -n $script_dir/$script_name | tail | grep -e 'exit.*0' | awk '{print $1}')

    if test $LASTLINE -eq $lineno_last_exit; then
        echo "$script_name: [INFO] successfully exited at the line: $LASTLINE with return code: $LASTERR."
    elif test $LASTERR -eq 0; then
        echo "$script_name: [WARN] Exited with 0 but not ended at EOF. signal trapped at the line: $LASTLINE with return code: $LASTERR."
    else
        echo "$script_name: [ERR] signal trapped at the line: $LASTLINE with return code: $LASTERR."
    fi
    exit $LASTERR
}

trap 'signal_handler ${LINENO} $?' EXIT HUP INT QUIT TERM


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
    echo $src_site | grep -qi 'kek\|cnaf\|desy\|kmi'
    if test $? -eq 0; then
        src_site=$(echo $src_site | tr '[:lower:]' '[:upper:]')
    else
        echo "$usage_message" >&2
        exit 1
    fi
else
    src_site=$default_src_site
fi

if $opt_d; then
    echo $dst_site | grep -qi 'kek\|cnaf\|desy\|kmi'
    if test $? -eq 0; then
        dst_site=$(echo $dst_site | tr '[:lower:]' '[:upper:]')
    else
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
    cmd_transfer="seq $n_parallel | parallel --jobs $n_parallel 'lcg-cp --verbose -n $n_tcp --nobdii --srcsetype srmv2 --dstsetype srmv2 ${src_surl} ${dst_surl_prefix}_${nn}.{#}'"
    _do $cmd_transfer

    cmd_del="seq $n_parallel | parallel --jobs $n_parallel 'lcg-del --verbose --nolfc --nobdii --defaultsetype srmv2 ${dst_surl_prefix}_${nn}.{#}'"

    if test $? -eq 0; then
        echo "[OK] successfully transfer 1GB of files from $src_site to $dst_site in $n_parallel prallel jobs with $n_tcp tcp streams by $n_loop times repeats."
    else
        echo "[FATAL] error while copying $src_site to $dst_site in $n_parallel parallel jobs with $n_tcp tcp streams in $nn of $n_loop times."
        _do $cmd_del
        exit 1
    fi

    _do $cmd_del

    nn=$((nn+1))
done

exit 0
