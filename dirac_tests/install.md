wget --no-check-certificate http://lhcbproject.web.cern.ch/lhcbproject/dist/Dirac_project/dirac-install
chmod +x dirac-install
./dirac-install -V Belle

cd ~
ln -s work/dirac/dirac-compile-externals.py .
cd work/dirac
./dirac-install -d -V Belle -T 500000
# You have now installed DIRAC version required by Belle

source bashrc
dirac-proxy-init -x
#  -x   --nocs            : Disable CS check 

dirac-configure defaults-Belle.cfg
# You have now connected to the Belle DIRAC installation

dirac-proxy-init
# You have now delegated a proxy to Belle DIRAC

dirac-wms-job-submit $DIRAC/DIRAC/WorkloadManagementSystem/tests/GenericJob.jdl 
JobID = 981066
# You have now submitted your first DIRAC job

