- 日付ディレクトリを tar して HSM へコピーする。
- 毎時過去7日分くらいやっていくか
- DEBUG もあるので、 checksum validation してやる
- HSM は FTS サーバ上では見えていないようなので、転送方法は SE 室でやってもらう


ひとまずは毎時で動かすということで
`/etc/cron.d/fts-log-copy-to-hsm` でも作ってもらう。

```
12 * * * * adm cd /path/to/script && ./fts-log-copy-to-hsm.sh > /path/to/std.out 2> /path/to/std.err
```
