se_DESY=dcache-se-desy.desy.de
se_KEK=kek2-se01.cc.kek.jp
se_KEKDISK=kek2-diskse01.cc.kek.jp
se_CNAF=storm-fe-archive.cr.cnaf.infn.it
se_KMI=nsrmfe01.hepl.phys.nagoya-u.ac.jp

se_DESY_endpoint=$se_DESY:8443/srm/managerv2
se_KEK_endpoint=$se_KEK:8444/srm/managerv2
se_KEKDISK_endpoint=$se_KEKDISK:8444/srm/managerv2
se_CNAF_endpoint=$se_CNAF:8444/srm/managerv2
se_KMI_endpoint=$se_KMI:8444/srm/managerv2

se_DESY_filepath=/pnfs/desy.de/belle/user/iwai/1GB
se_KEK_filepath=/belle/TMP/1GB
se_KEKDISK_filepath=/belle/TMP/1GB
se_CNAF_filepath=/belle/TMP/1GB
se_KMI_filepath=/belle/TMP/1GB

se_nimonic="KEK DESY KEKDISK CNAF KMI"

function valid_site() {
    local site_name=$1
    for se in $se_nimonic; do
        echo $site_name | egrep -qi "^${se}$"
        if test $? -eq 0; then
            return 0
        fi
    done
    return 1
}
