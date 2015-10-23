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

# create 1 GB of file
outfile=$dir_at_exec/rndfile_1GB_$(date +%Y-%m-%d_%H%M%S)
cmd="dd bs=$((1024*1024)) if=/dev/urandom of=$outfile count=1024"
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


# copy from kek to cnaf
cmd_kek_to_cnaf="lcg-cp -v srm://$se_kek/belle/TMP/$name_on_SE srm://$se_cnaf/belle/user/iwai/from_kek_$name_on_SE"
_do $cmd_kek_to_cnaf

if test $? -eq 0; then
    echo "success."
else
    echo "error while copying storm/kek to storm/cnaf."
    cmd_del="lcg-del -l srm://$se_kek/belle/TMP/$name_on_SE"
    _do $cmd_del
    cmd_del="lcg-del -l srm://$se_cnaf/belle/user/iwai/from_kek_$name_on_SE"
    _do $cmd_del

    cmd_del="rm $outfile"
    _do $cmd_del
    exit 1
fi

# copy from cnaf to kek
cmd_cnaf_to_kek="lcg-cp -v srm://$se_cnaf/belle/user/iwai/from_kek_$name_on_SE srm://$se_kek/belle/TMP/from_cnaf_$name_on_SE"
_do $cmd_cnaf_to_kek

if test $? -eq 0; then
    echo "success."
else
    echo "error while copying storm/cnaf to storm/kek."
    cmd_del="lcg-del -l srm://$se_kek/belle/TMP/$name_on_SE"
    _do $cmd_del
    cmd_del="lcg-del -l srm://$se_cnaf/belle/user/iwai/from_kek_$name_on_SE"
    _do $cmd_del
    cmd_del="lcg-del -l srm://$se_kek/belle/TMP/from_cnaf_$name_on_SE"
    _do $cmd_del
    cmd_del="rm $outfile"
    _do $cmd_del
    exit 1
fi

cmd_del="lcg-del -l srm://$se_kek/belle/TMP/$name_on_SE"
_do $cmd_del
cmd_del="lcg-del -l srm://$se_cnaf/belle/user/iwai/from_kek_$name_on_SE"
_do $cmd_del
cmd_del="lcg-del -l srm://$se_kek/belle/TMP/from_cnaf_$name_on_SE"
_do $cmd_del
cmd_del="rm $outfile"
_do $cmd_del

exit 0
