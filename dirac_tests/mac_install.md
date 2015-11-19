http://diracgrid.org/files/docs/UserGuide/GettingStarted/InstallingClient/index.html

wget -np -O dirac-install http://lhcbproject.web.cern.ch/lhcbproject/dist/Dirac_project/dirac-install --no-check-certificate
chmod +x dirac-install
./dirac-install -V Belle

と mac 上でやるとコンパイルでこけたり、タイムアウトで終わったりした。 2015年10月下旬

DIRAC 以下にあるサードパーティコンパイル用のスクリプトに手を入れて、 `dirac-install` 実行時に置き換えて実行させた。

timeout 値を長くとる、と。デフォルトは 300 でどうも、 `dirac-install` の処理全てが完了するまでのアラームになっている。

```
cd ~
ln -s work/dirac/dirac-compile-externals.py .
cd work/dirac
./dirac-install -d -V Belle -T 500000
```

# You have now installed DIRAC version required by Belle

source bashrc
dirac-proxy-init -x
#  -x   --nocs            : Disable CS check 

dirac-configure defaults-Belle.cfg
# You have now connected to the Belle DIRAC installation

dirac-proxy-init -g belle_sgm
belle ではジョブ投入できなくなっていた。
# You have now delegated a proxy to Belle DIRAC


# 後ほどこれは git か bitbucket にあげる
dirac-wms-job-submit dirac_tests/GenericJob.jdl 
JobID = 981066
# You have now submitted your first DIRAC job

