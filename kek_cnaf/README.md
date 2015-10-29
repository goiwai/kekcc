- `dd` 遅いし、とりあえず、 TMP 以下に 1GB ファイルがステージされてあることを前提に。。。
- KEK/KMI/DESY/CNAF 4サイトキメ打ち
- まとめは wiki に置いていくか http://wiki.kek.jp/display/~iwai/KEK-CNAF+file+transfer
    - この README.md でよいか？

# references

- [fts dashboard](http://dashb-fts-transfers.cern.ch/ui/#date.interval=40320&dst.host=%28%22storm-fe-archive.cr.cnaf.infn.it%22%29&grouping.dst=%28host,token%29&grouping.src=%28host,token%29&j.grouping=file_state&m.content=%28efficiency,errors,successes,throughput%29&p.grouping=src&r.grouping=dst&r.metrics=%28ts%29&server=%28%29&src.host=%28%22kek2-se01.cc.kek.jp%22%29&tab=transfer_plots&vo=%28belle%29)
- [ggus ticket](https://ggus.eu/index.php?mode=ticket_info&ticket_id=113435)

# 途中経過

- 10/13 ちょっとやったくらいでは失敗しなかった
    - 1 GB のファイルをローカルから kek storm へ転送
    - 1 GB のファイルを kek storm から cnaf storm へ転送
    - 1 GB のファイルを cnaf storm から kek storm へ転送
- 10/22 10 並列で  1GB ファイル転送すると失敗する
    - 転送は終わっているようだが、 connection が切れないようだ
    - FTS で転送しているときに頻発しているエラーと同種のものか定かではない
    - storm-dsi とか gpfs 的な問題の可能性もある
    - KEK-DESY 間で同じことをやると成功する

```
globus_ftp_client: the server responded with an error
500 500-Command failed. : an end-of-file was reached
500-globus_xio: An end of file occurred
500 End.
```

# mesh sites test

`./parallel_file_transfer.sh -s src -d dst -n 10 -p 4 -l 2` で試す。

- 2015/10/26 引数指定が間違っていた、やり直し
- 2015/10/27 CNAF storm が不調 `~~ appropriate VSF~~` とかなんとかメッセージが出る、やり直し
- 2015/10/27 3度めのトライ
    - 11:30 頃に証明書 revoke して再配置
        - 影響はなかった模様
    - 3時間くらいで終了


| src \ dst  | KEK | KEKDISK | KMI | DESY | CNAF |
|---------|---------|---------|---------|---------|---------|
| **KEK** |  ==== | OK  | OK |  OK |  **ERR**  |
| **KEKDISK** | OK | ====  | OK | OK  |  **ERR**  |
| **KMI** | OK  | OK  |==== | OK  | OK   |
| **DESY** |  OK | OK  | OK | ====|  OK  |
| **CNAF** | OK | OK  | OK | OK  |====|


# 1 file への並列数分だけ同時アクセスするのをやめてみる

- 2015/10/28 9:56 開始 2015/10/28 12:06 終了
    - 2時間くらいで終了
- まあ結果は同じですね。

| src \ dst  | KEK | KEKDISK | KMI | DESY | CNAF |
|---------|---------|---------|---------|---------|---------|
| **KEK** |  ==== | OK  | OK |  OK |  **ERR**  |
| **KEKDISK** | OK | ====  | OK | OK  |  **ERR**  |
| **KMI** | OK  | OK  |==== | OK  | OK   |
| **DESY** |  OK | OK  | OK | ====|  OK  |
| **CNAF** | OK | OK  | OK | OK  |====|


# parallel 数もしくは connection 数 (parallel x tcp stream) が trigger になっているような印象

2並列くらいから上げていってみる

- OK `./parallel_file_transfer.sh -s kekdisk -d cnaf -n 4 -p 2 -l 2`
- ERR `./parallel_file_transfer.sh -s kekdisk -d cnaf -n 4 -p 3 -l 2`
- OK `./parallel_file_transfer.sh -s kekdisk -d cnaf -n 1 -p 4 -l 2`
- ERR `./parallel_file_transfer.sh -s kekdisk -d cnaf -n 4 -p 4 -l 2`
- OK `./parallel_file_transfer.sh -s kekdisk -d cnaf -n 1 -p 5 -l 2`
- OK `./parallel_file_transfer.sh -s kekdisk -d cnaf -n 1 -p 6 -l 2`
- ERR `./parallel_file_transfer.sh -s kekdisk -d cnaf -n 1 -p 8 -l 2`
- OK `./parallel_file_transfer.sh -s kekdisk -d cnaf -n 2 -p 4 -l 2`
- ERR `./parallel_file_transfer.sh -s kekdisk -d cnaf -n 2 -p 3 -l 2`
- ERR `./parallel_file_transfer.sh -s kekdisk -d cnaf -n 1 -p 7 -l 2`

総計 6--8 streams または 8 parallel transfer あたりから `500-globus_xio: An end of file occurred` 問題が発生している。

# 次は生の gridftp KEK to CNAF

なんか gridftp でやると問題が発生しないな。。。 `globus-url-copy` を使用しているが `uberftp` でも結果は同じ。

## urls

- KEK local `gsiftp://kek2-storm01.cc.kek.jp/var/tmp/1GB.3`
- KEK GPFS `gsiftp://kek2-storm01.cc.kek.jp:2811//ghi/fs01/belle/grid/storm/TMP/1GB.3`
- CNAF local `gsiftp://gridftp-storm-archive.cr.cnaf.infn.it/tmp/1GB.3`
- CNAF GPFS `gsiftp://gridftp-storm-archive.cr.cnaf.infn.it:2811//storage/gpfs_data/belle/TMP/from_KEK_to_CNAF_1GB_2015-10-29_101904_1.3`

なお `gridftp-storm-archive.cr.cnaf.infn.it` は以下2つのアドレスにラウンドロビンされており、

```
Name:    gridftp-storm-archive.cr.cnaf.infn.it
Address: 131.154.130.76
Name:   gridftp-storm-archive.cr.cnaf.infn.it
Address: 131.154.130.75
```
それぞれ、

```
ds-202-11-03.cr.cnaf.infn.it
ds-202-11-01.cr.cnaf.infn.it
```

であるので、実際は `gsiftp://ds-202-11-01.cr.cnaf.infn.it/tmp/1GB.{#}` だとか `gsiftp://ds-202-11-03.cr.cnaf.infn.it/storage/gpfs_data/belle/TMP/1GB.{#}` のように指定する。


## 準備

```
seq 10 | parallel --jobs 10 'globus-url-copy -verbose-perf -parallel 4 file:///group/ce/ccx/iwai/rndfile/1GB gsiftp://kek2-storm01.cc.kek.jp/tmp/1GB.{#}'
```

なんかこの段階ですでにエラーが発生している模様。

```
error: an end-of-file was reached
globus_xio: An end of file occurred

```


あれ。。。 `/tmp` 以下のファイル消えた...

とりあえず parallel & multiple streams transfer をやめよう。

```
[iwai@ccw07 from_KEK_to_CNAF]$ for n in {1..10}; do globus-url-copy -verbose-perf file:///group/ce/ccx/iwai/rndfile/1GB gsiftp://kek2-storm01.cc.kek.jp/var/tmp/1GB.$n; done
```

```
UberFTP> ls 1GB.1
-rw-r--r--   1 belleuser027 bellegrid    821915648 Oct 29 14:08 /tmp/1GB.1
UberFTP> ls 1GB.2
-rw-r--r--   1 belleuser027 bellegrid    898760704 Oct 29 14:09 /tmp/1GB.2
UberFTP> ls 1GB.5
-rw-r--r--   1 belleuser027 bellegrid    947163136 Oct 29 14:10 /tmp/1GB.5
UberFTP> ls 1GB.10
-rw-r--r--   1 belleuser027 bellegrid    913833984 Oct 29 14:02 /tmp/1GB.10
UberFTP> ls 1GB 
-rw-r--r--   1 belleuser027 bellegrid   1073741824 Oct 29 14:00 /tmp/1GB
UberFTP> ls 1GB.2
-rw-r--r--   1 belleuser027 bellegrid    898760704 Oct 29 14:09 /tmp/1GB.2
```
なんや、これ。 1GB にならんやんけ。と思ったら

```
error: an end-of-file was reached
globus_xio: An end of file occurred
```

これが発生していました。

`/tmp` は 10GB しかないので `/var/tmp` にしてくれとのこと。


## results



### OK: gpfs to gpfs

```
seq 10 | parallel --jobs 10 'globus-url-copy -verbose-perf -parallel 4 gsiftp://kek2-storm01.cc.kek.jp/ghi/fs01/belle/grid/storm/TMP/1GB.{#} gsiftp://ds-202-11-03.cr.cnaf.infn.it/storage/gpfs_data/belle/TMP/from_KEK_to_CNAF_1GB.{#}'
```



### OK: gpfs to local

```
seq 10 | parallel --jobs 10 'globus-url-copy -verbose-perf -parallel 4 gsiftp://kek2-storm01.cc.kek.jp/ghi/fs01/belle/grid/storm/TMP/1GB.{#} gsiftp://ds-202-11-03.cr.cnaf.infn.it/tmp/1GB.{#}' > ftp2.out 2> ftp2.err
```

出力見る限りは問題なさげ


### OK: local to gpfs

```
seq 10 | parallel --jobs 10 'globus-url-copy -verbose-perf -parallel 4 gsiftp://kek2-storm01.cc.kek.jp/var/tmp/1GB.{#} gsiftp://ds-202-11-03.cr.cnaf.infn.it/storage/gpfs_data/belle/TMP/from_KEK_to_CNAF_1GB.{#}'
```

出力見る限りは問題なさげ


### OK: local to local

```
seq 10 | parallel --jobs 10 'globus-url-copy -verbose-perf -parallel 4 gsiftp://kek2-storm01.cc.kek.jp/var/tmp/1GB.{#} gsiftp://ds-202-11-03.cr.cnaf.infn.it/tmp/1GB.{#}' > ftp.out 2> ftp.err
```

出力見る限りは問題なさげ

```
for n in {1..10}; do uberftp -ls gsiftp://ds-202-11-03.cr.cnaf.infn.it/tmp/1GB.$n; done
-rw-r--r--   1 belle024    belle   1073741824 Oct 29 06:33 /tmp/1GB.1
-rw-r--r--   1 belle024    belle   1073741824 Oct 29 06:32 /tmp/1GB.2
-rw-r--r--   1 belle024    belle   1073741824 Oct 29 06:33 /tmp/1GB.3
-rw-r--r--   1 belle024    belle   1073741824 Oct 29 06:33 /tmp/1GB.4
-rw-r--r--   1 belle024    belle   1073741824 Oct 29 06:32 /tmp/1GB.5
-rw-r--r--   1 belle024    belle   1073741824 Oct 29 06:33 /tmp/1GB.6
-rw-r--r--   1 belle024    belle   1073741824 Oct 29 06:33 /tmp/1GB.7
-rw-r--r--   1 belle024    belle   1073741824 Oct 29 06:33 /tmp/1GB.8
-rw-r--r--   1 belle024    belle   1073741824 Oct 29 06:33 /tmp/1GB.9
-rw-r--r--   1 belle024    belle   1073741824 Oct 29 06:33 /tmp/1GB.10

```

消せない。。。

```
for n in {1..10}; do uberftp -rm gsiftp://ds-202-11-03.cr.cnaf.infn.it/tmp/1GB.$n; done
500 Command failed : error: commands denied
500 Command failed : error: commands denied
500 Command failed : error: commands denied
500 Command failed : error: commands denied
500 Command failed : error: commands denied
500 Command failed : error: commands denied
500 Command failed : error: commands denied
500 Command failed : error: commands denied
500 Command failed : error: commands denied
500 Command failed : error: commands denied
```
