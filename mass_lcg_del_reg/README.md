- [python api examples やや古い](http://gilda.ct.infn.it/wikimain?p_p_id=54_INSTANCE_t9W0&p_p_lifecycle=0&p_p_state=normal&p_p_mode=view&p_p_col_id=column-2&p_p_col_count=1&_54_INSTANCE_t9W0_struts_action=%2Fwiki_display%2Fview&_54_INSTANCE_t9W0_nodeName=Main&_54_INSTANCE_t9W0_title=LFCPythonAPI#section-LFCPythonAPI-PythonAPICodeExamples)
- [lfc api 1行の説明 古い 2006](https://twiki.cern.ch/twiki/bin/view/LCG/LfcApi)

元々の問題はというと。。。


```
岩井 様

    IBM 中央計算機システム SE 中谷です。
    お世話になっております。

    大量削除中の LFN 登録テスト時に使用したスクリプトを送付致します。
    スクリプト内では lcg-cr を使用しています。

    なお当方で以下コマンドを試行しましたが、全て add replica となる
    事が確認されたため、テストには lcg-cr を使用した次第となります。

      lcg-rf
      gfal-copy
      gfal-legacy-register

    宜しくお願い致します。
```


```
岩井 様

    IBM 中央計算機システム SE 中谷です。
    お世話になっております。

    LFN 削除スクリプトを送付させていただきます。
    lcg-uf ( Unregister Files ) コマンドを使用しています。

    当該スクリプトの実行の前提として、削除対象となるディレクトリ/
    ファイルエントリの存在が必要になります。

    テスト時は、事前に先程お送りした lfc-cr.sh を使用して作成しました。
    ディレクトリパスにホスト名と通し番号を付与し、ホスト毎に並行して、
    大量の削除が実施可能としました。

    宜しくお願い致します。
```


- DIRAC による大量ファイル削除実施
    - 100 files を remove する処理が ~90 並列で走る bulk remove
- MySQL 処理増大 (削除処理によるロックが頻発？)
- 並行して行っている LFN 登録処理がデッドロック
- MySQL innodb_lock_wait_timeout = 50秒に抵触し以下エラー発生：

これで

1. 10,000 lfn 登録して `lfc_registerfiles`
2. 100 lfn 削除 を 100 並列で流す
3. 2. と並列に登録処理を流す `lfc_registerfiles`

で再現できるか試す


```
import lfc2thr as lfc 
lfc.init()


```


http://egee-jra1-data.web.cern.ch/egee-jra1-data/dpm-lfc-python2-preview/lfc2_python.html


```
lfc_delreplica ( string guid, struct lfc_fileid *file_uniqueid, string sfn )

lfc_delreplicas ( ListOfString sfns, string se ) -> ListOfInt results

 lfc_registerfiles ( ListOf struct  lfc_filereg  files  )  ->  ListOfInt
       results

```

なんか、そもそも threading が並列に動いていなくて sequential に slave が実施されて言ってるな。 `self.daemon = True` とかしないといけないのかも

DIRAC:

```
fileChunk = [] # list object

while some conditions:
    oFile = lfc.lfc_filereg()
    oFile.lfn = self.dd__fullLfn( lfn )
    oFile.sfn = pfn
    oFile.size = size
    oFile.mode = 0664
    oFile.server = se
    oFile.guid = guid
    oFile.csumtype = 'AD'
    oFile.status = 'U'
    oFile.csumvalue = lfnInfo['Checksum']

    fileChunk.append( oFile )

error, errCodes = lfc.lfc_registerfiles( fileChunk )
```

