#! /usr/bin/env python

import os, sys, time, stat
import lfc
#import lfcthr as lfc
import threading


_n_threads = 10
_path_to_dir = '/grid/belle'


class slave(threading.Thread):
    def __init__ (self, slave_id, path_to_dir):
        super(slave, self).__init__()
        self.slave_id_ = slave_id
        self.path_to_dir_ = path_to_dir

    def run(self):
        print "slave number: ", self.slave_id_
        self.scan_dir(self.path_to_dir_)

    def print_error(self, msg):
        err_num = lfc.cvar.serrno
        err_string = lfc.sstrerror(err_num)
        print >> sys.stderr, msg, "Error " + str(err_num) + " (" + err_string + ")"
        return err_num

    def print_GUID(self, path_to_file):
        stat = lfc.lfc_filestatg()
        res = lfc.lfc_statg(path_to_file, "", stat)
        if res == 0:
            guid = stat.guid
            print path_to_file + ": " + guid
            return 0
        else:
            return self.print_error("There was an error while looking for " + path_to_file)

    def scan_dir(self, root_dir):
        dir = lfc.lfc_opendirg(root_dir, "")

        if (dir == None) or (dir == 0):
            return self.print_error("Error while looking for " + root_dir)

        while True:
            read_pt = lfc.lfc_readdirxr(dir,"")
        
            if (read_pt == None) or (read_pt == 0):
                break

            entry, list = read_pt
            p = root_dir + '/' + entry.d_name
            if stat.S_ISDIR(entry.filemode):
                self.scan_dir(p)
            else:
                self.print_GUID(p)
                try:
                    n_replica = len(list)
                    for i in range(n_replica):
                        print " ==> replica (%d/%d) %s" % (i+1, n_replica, list[i].sfn)
                except TypeError, x:
                    print " ==> None"

        lfc.lfc_closedir(dir)
        return



def print_config(msg):
    print >> sys.stderr, msg,
    for i in range(5):
        sys.stderr.write('.')
        sys.stderr.flush()
        time.sleep(1)
    print >> sys.stderr


if __name__ == '__main__':
    # os.environ['LFC_HOST'] = 'kek2-lfc.cc.kek.jp'
    #    Threaded library initialisation
    #lfc.init()
    #
    #    Start up of threads

    if len(sys.argv) == 2:
        n_threads = int(sys.argv[1])
        path_to_dir = _path_to_dir
    elif len(sys.argv) == 3:
        n_threads = int(sys.argv[1])
        path_to_dir = str(sys.argv[2])
    else:
        n_threads = _n_threads
        path_to_dir = _path_to_dir

    print_config('n_threads=' + str(n_threads) + ' path_to_dir=' + path_to_dir)

    for i in xrange(n_threads):
        slv = slave(i, path_to_dir)
        slv.start()
