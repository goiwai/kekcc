#! /bin/sh

H=`hostname -s`

RC=0
for N in `seq 1 10`
do
	SN=${N}
	if [ ${N} -lt 10 ]; then
		SN="000${N}"
	fi

	lfc-mkdir /grid/belle/TMP/testdir/${H}
	lfc-mkdir /grid/belle/TMP/testdir/${H}/${SN}

	srmmkdir srm://tli53.cc.kek.jp:8444/belle/TMP/testdir/${H}
	srmmkdir srm://tli53.cc.kek.jp:8444/belle/TMP/testdir/${H}/${SN}

	for M in `seq 0 999`
	do
		SM=${M}
		if [ ${M} -lt 10 ]; then
			SM="00${M}"
		elif [ ${M} -lt 100 ]; then
			SM="0${M}"
		fi

		SURL="srm://tli53.cc.kek.jp:8444/belle/TMP/testdir/${H}/${SN}/output_${SM}.root"
		LFN="/grid/belle/TMP/testdir/${H}/${SN}/output_${SM}.root"

		lcg-cr -d ${SURL} -l lfn:${LFN} file:///dev/shm/output_0.root > /dev/null 2>&1

		sleep 1
	done
done

