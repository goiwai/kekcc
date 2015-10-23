#! /bin/sh
script_name=$(basename $0)
script_dir=$(cd $(dirname $0) && pwd)
dir_at_exec=$(cd . && pwd)

_do() {
    local cmd="$*"
    echo "$cmd"
    eval $cmd
    return $?
}

se_cnaf=storm-fe-archive.cr.cnaf.infn.it
se_kek=kek2-se01.cc.kek.jp

n_loop=2
#n_loop=2
#n_parallel=10
n_parallel=8
n_tcp=4

# create 1 GB of file
outfile=$dir_at_exec/rndfile_1GB_$(date +%Y-%m-%d_%H%M%S)

#1GB
cmd="dd bs=$((1024*1024)) if=/dev/urandom of=$outfile count=1024"
#256MB
#cmd="dd bs=$((1024*1024)) if=/dev/urandom of=$outfile count=256"
echo "this (dd) takes some times..."
_do $cmd

# copy from local to kek
name_on_SE=$(basename $outfile)
cmd_local_to_kek="lcg-cp -v file:///$outfile srm://$se_kek/belle/TMP/$name_on_SE"
_do $cmd_local_to_kek


if test $? -eq 0; then
    echo "success."
else
    echo "error while copying local to storm/kek."
    cmd_del="lcg-del -l srm://$se_kek/belle/TMP/$name_on_SE"
    _do $cmd_del
    cmd_del="rm $outfile"
    _do $cmd_del
    exit 1
fi

nn=0 && while test $nn -lt $n_loop; do

    # copy from kek to cnaf
    #cmd_kek_to_cnaf="lcg-cp -v srm://$se_kek/belle/TMP/$name_on_SE srm://$se_cnaf/belle/user/iwai/from_kek_$name_on_SE"

    cmd_kek_to_cnaf="seq $n_parallel | parallel --jobs $n_parallel 'lcg-cp -n $n_tcp -v srm://$se_kek/belle/TMP/$name_on_SE srm://$se_cnaf/belle/user/iwai/from_kek_${name_on_SE}_${nn}.{#}'"
#"lcg-cp -n 4 -v srm://kek2-se01.cc.kek.jp/belle/4GB.tmp file:///tmp/4GB.{#}"

    _do $cmd_kek_to_cnaf


    # do parallel below
    if test $? -eq 0; then
	echo "success."
    else
	echo "error while copying storm/kek to storm/cnaf."
	cmd_del="lcg-del -l srm://$se_kek/belle/TMP/$name_on_SE"
	_do $cmd_del
	cmd_del="seq $n_parallel | parallel --jobs $n_parallel 'lcg-del -l srm://$se_cnaf/belle/user/iwai/from_kek_${name_on_SE}_${nn}.{#}'"
    #cmd_del="lcg-del -l srm://$se_cnaf/belle/user/iwai/from_kek_$name_on_SE"
	_do $cmd_del
    
	cmd_del="rm $outfile"
	_do $cmd_del
	exit 1
    fi


    # copy from cnaf to kek
    cmd_cnaf_to_kek="seq $n_parallel | parallel --jobs $n_parallel 'lcg-cp -n $n_tcp -v srm://$se_cnaf/belle/user/iwai/from_kek_${name_on_SE}_${nn}.{#} srm://$se_kek/belle/TMP/from_cnaf_${name_on_SE}_${nn}.{#}'"
    _do $cmd_cnaf_to_kek

    if test $? -eq 0; then
	echo "success."
    else
	echo "error while copying storm/cnaf to storm/kek."
	cmd_del="lcg-del -l srm://$se_kek/belle/TMP/$name_on_SE"
	_do $cmd_del

	cmd_del="seq $n_parallel | parallel --jobs $n_parallel 'lcg-del -l srm://$se_cnaf/belle/user/iwai/from_kek_${name_on_SE}_${nn}.{#}'"
	_do $cmd_del

	cmd_del="seq $n_parallel | parallel --jobs $n_parallel 'lcg-del -l srm://$se_kek/belle/TMP/from_cnaf_${name_on_SE}_${nn}.{#}'"
        #cmd_del="lcg-del -l srm://$se_kek/belle/TMP/from_cnaf_$name_on_SE"
	_do $cmd_del

	cmd_del="rm $outfile"
	_do $cmd_del
	exit 1
    fi

    nn=$((nn+1))
done


nn=0 && while test $nn -lt $n_loop; do
    cmd_del="seq $n_parallel | parallel --jobs $n_parallel 'lcg-del -v -l srm://$se_cnaf/belle/user/iwai/from_kek_${name_on_SE}_${nn}.{#}'"
    _do $cmd_del
    cmd_del="seq $n_parallel | parallel --jobs $n_parallel 'lcg-del -v -l srm://$se_kek/belle/TMP/from_cnaf_${name_on_SE}_${nn}.{#}'"
    _do $cmd_del

    nn=$((nn+1))
done

cmd_del="lcg-del -l srm://$se_kek/belle/TMP/$name_on_SE"
_do $cmd_del

cmd_del="rm $outfile"
_do $cmd_del

exit 0
