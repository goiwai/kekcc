# coding=utf-8
import sys, os, stat
import threading
import time
import datetime
import lfcthr as lfc

if __name__ == '__main__':
    fileChunk = [] # list object

    oFile = lfc.lfc_filereg()
    oFile.lfn = '/grid/belle/user/iwai/hoge'
    oFile.sfn = 'srm://kek2-se01.cc.kek.jp/belle/TMP/1GB'
    oFile.size = 1073741824
    oFile.mode = 0664
    oFile.server = 'kek2-se01.cc.kek.jp'
    oFile.guid = 
    oFile.csumtype = 'AD'
    oFile.status = 'U'
    oFile.csumvalue = lfnInfo['Checksum']

    fileChunk.append(oFile)

    error, errCodes = lfc.lfc_registerfiles(fileChunk)
