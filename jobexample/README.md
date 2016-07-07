# Usage `zzz.jdl`

## Proxy creation

```
$ voms-proxy-init -voms belle
Contacting voms.cc.kek.jp:15020 [/C=JP/O=KEK/OU=CRC/CN=host/voms.cc.kek.jp] "belle"...
Remote VOMS server contacted succesfully.


Created proxy in /tmp/x509up_u21286.

Your proxy is valid until Thu Jul 07 21:21:17 JST 2016
```

## Job submission

```
$ glite-ce-job-submit -a -r kek2-ce01.cc.kek.jp:8443/cream-lsf-gridbelle_middle zzz.jdl
https://kek2-ce01.cc.kek.jp:8443/CREAM162280538
```

## Job status

```
$ glite-ce-job-status https://kek2-ce01.cc.kek.jp:8443/CREAM162280538

******  JobID=[https://kek2-ce01.cc.kek.jp:8443/CREAM162280538]
    Status        = [IDLE]

# then...

$ glite-ce-job-status https://kek2-ce01.cc.kek.jp:8443/CREAM162280538

******  JobID=[https://kek2-ce01.cc.kek.jp:8443/CREAM162280538]
    Status        = [DONE-OK]
    ExitCode      = [0]

```

## Job output

```
$ glite-ce-job-output https://kek2-ce01.cc.kek.jp:8443/CREAM162280538

2016-07-07 09:26:23,612 INFO - For JobID [https://kek2-ce01.cc.kek.jp:8443/CREAM162280538] output will be stored in the dir ./kek2-ce01.cc.kek.jp_8443_CREAM162280538

$ cat ./kek2-ce01.cc.kek.jp_8443_CREAM162280538/std.out 
Hello World!
I am ccb0261.cc.kek.jp

$ cat ./kek2-ce01.cc.kek.jp_8443_CREAM162280538/std.err 
message into the stderr...
```

## Proxy deletion

```
$ voms-proxy-destroy 
```
