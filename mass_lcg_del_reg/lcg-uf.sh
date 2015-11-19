#! /bin/sh

H=`hostname -s`

#for N in `seq 1 10`
for N in `seq 10 10`
do
	SN="${N}"
	if [ ${N} -lt 10 ]; then
		SN="0${N}"
	fi

	DIR="/grid/belle/TMP/testdir/${H}/${SN}"
	for F in `lfc-ls ${DIR}`
	do
		GUID=`lcg-lg lfn:${DIR}/${F}`
		SURL=`lcg-lr lfn:${DIR}/${F}`

		lcg-uf -f ${GUID} ${SURL}
	done
done
