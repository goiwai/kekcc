# coding=utf-8
import sys, os, stat
import threading
import time
import datetime
import lfcthr as lfc

class slave(threading.Thread):
    """docstring for a class slave"""

    def __init__(self, slave_id, root_dir):
        super(slave, self).__init__()
        self.slave_id_ = slave_id
        # これしとけば background で走ってくれるようだ
        self.daemon = True
        self.root_dir_ = root_dir

    def run(self):
        print "!!!slave#", self.slave_id_, self.root_dir_, self.count_entry(self.root_dir_)

    def print_error(self, msg):
        err_num = lfc.cvar.serrno
        err_string = lfc.sstrerror(err_num)
        print >> sys.stderr, msg, "Error " + str(err_num) + " (" + err_string + ")"
        return err_num

    def count_entry(self, root_dir):
        dir = lfc.lfc_opendirg(root_dir, "")

        counter = {"dir":0, "file":0}

        if (dir == None) or (dir == 0):
            self.print_error("Error while looking for " + root_dir)
            return counter

        while True:
            read_pt = lfc.lfc_readdirxr(dir,"")
            if (read_pt == None) or (read_pt == 0):
                break
            entry, list = read_pt
            new_path = root_dir + '/' + entry.d_name
            if stat.S_ISDIR(entry.filemode):
                counter['dir'] += 1
                cnt = self.count_entry(new_path)
                #print cnt
                counter['dir'] += cnt['dir']
                counter['file'] += cnt['file']
            else:
                counter['file'] += 1
        lfc.lfc_closedir(dir)
        return counter


if __name__ == '__main__':
    path_list = ['/grid/belle/user/onuki',
                 '/grid/belle/user/ueda',
                 '/grid/belle/user/okazu',
                 '/grid/belle/mc/mc',
                 '/grid/belle/software',
                 '/grid/belle/desy']

    slaves = []
    for slave_id, path in enumerate(path_list):
        slv = slave(slave_id, path)
        slaves.append(slv)
        slv.start()


    # join してやらんと daemon になって処理がおわらんうちに終わってしまう
    # 果たしてこれで良いのか。。。
    for slv in slaves:
        print "!!! waiting slave#", slv.slave_id_, 'for a path:', slv.root_dir_
        slv.join()
