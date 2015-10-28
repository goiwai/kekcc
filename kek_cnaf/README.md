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

| src \ dst  | KEK | KEKDISK | KMI | DESY | CNAF |
|---------|---------|---------|---------|---------|---------|
| **KEK** |  ==== |   |  |   |    |
| **KEKDISK** |  | ====  |  |   |    |
| **KMI** |   |   |==== |   |    |
| **DESY** |   |   |  | ====|    |
| **CNAF** |  |   |  |   |====|
