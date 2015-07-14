#! /usr/bin/env python

import os, sys
import lfc
#import lfcthr as lfc
#from threading import Thread
import stat
import time

_n_threads = 10
_path_to_dir = '/grid/belle'

#from threading import Thread

def print_error(msg):
    err_num = lfc.cvar.serrno
    err_string = lfc.sstrerror(err_num)
    print msg
    print "Error " + str(err_num) + " (" + err_string + ")"
    return err_num

def print_GUID(path_to_file):
    #name = "/grid/belle/MC/test/testua/hoge1.root"
    stat = lfc.lfc_filestatg()
    res = lfc.lfc_statg(path_to_file, "", stat)
    if res == 0:
        guid = stat.guid
        print path_to_file + ": " + guid
        return 0
    else:
        return print_error("There was an error while looking for " + path_to_file)


def scan_dir(root_dir):
    dir = lfc.lfc_opendirg(root_dir, "")

    if (dir == None) or (dir == 0):
        return print_err("Error while looking for " + root_dir)


    while True:
        read_pt = lfc.lfc_readdirxr(dir,"")
        
        if (read_pt == None) or (read_pt == 0):
            break
        entry, list = read_pt
        p = root_dir + '/' + entry.d_name
        if stat.S_ISDIR(entry.filemode):
            scan_dir(p)
        else:
            print_GUID(p)
            try:
                n_replica = len(list)
                for i in range(n_replica):
                    print " ==> replica (%d/%d) %s" % (i+1, n_replica, list[i].sfn)
            except TypeError, x:
                print " ==> None"

    lfc.lfc_closedir(dir)
    return



if __name__ == '__main__':
    #os.environ['LFC_HOST'] = 'kek2-lfc.cc.kek.jp'

    if len(sys.argv) == 2:
        n_threads = int(sys.argv[1])
        path_to_dir = _path_to_dir
    elif len(sys.argv) == 3:
        n_threads = int(sys.argv[1])
        path_to_dir = str(sys.argv[2])
    else:
        n_threads = _n_threads
        path_to_dir = _path_to_dir


    print >> sys.stderr, 'n_threads=', n_threads, 'path_to_dir=', path_to_dir,
    for i in range(5):
        sys.stderr.write('.')
        sys.stderr.flush()
        time.sleep(1)
    print >> sys.stderr

    for i in xrange(n_threads):
        scan_dir(path_to_dir)
