# coding=utf8

import os, sys
# import lfc

# from threading import Thread
import stat
import time
#import lfc
import lfcthr as lfc
#import lfc2thr as lfc 
#lfc.init()

#_n_threads = 10
_path_to_dir = '/grid/belle/mc/mc'

#from threading import Thread

def print_error(msg):
    err_num = lfc.cvar.serrno
    err_string = lfc.sstrerror(err_num)
    print >> sys.stderr, msg, "Error " + str(err_num) + " (" + err_string + ")"
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


def count_entry(root_dir):
    dir = lfc.lfc_opendirg(root_dir, "")

    counter = {"dir":0, "file":0}

    if (dir == None) or (dir == 0):
        print_error("Error while looking for " + root_dir)
        return counter

    while True:
        read_pt = lfc.lfc_readdirxr(dir,"")
        
        if (read_pt == None) or (read_pt == 0):
            break
        entry, list = read_pt
        p = root_dir + '/' + entry.d_name
        if stat.S_ISDIR(entry.filemode):
            counter['dir'] += 1
            cnt = count_entry(p)
            #print cnt
            counter['dir'] += cnt['dir']
            counter['file'] += cnt['file']
        else:
            counter['file'] += 1

    lfc.lfc_closedir(dir)
    return counter


def print_config(msg):
    print >> sys.stderr, msg, 'this takes some times, maybe 10 sec or so.'
    for i in range(2):
        sys.stderr.write('.')
        sys.stderr.flush()
        time.sleep(1)
    print >> sys.stderr


if __name__ == '__main__':
    # os.environ['LFC_HOST'] = 'kek2-lfc.cc.kek.jp'

    if len(sys.argv) == 2:
        path_to_dir = str(sys.argv[1])
    else:
        path_to_dir = _path_to_dir

    print_config('path_to_dir=' + path_to_dir)

    print count_entry(path_to_dir)

