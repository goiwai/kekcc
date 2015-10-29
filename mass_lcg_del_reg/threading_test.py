# coding=utf-8
import threading
import time
import datetime


class slave(threading.Thread):
    """docstring for a class slave"""

    def __init__(self, slave_id):
        super(slave, self).__init__()
        self.slave_id_ = slave_id
        # これしとけば background で走ってくれるようだ
        self.daemon = True
        self.time_to_sleep_ = 1 / n_slaves * slave_id
        self.n_times_ = n_slaves - slave_id

    def run(self):
        self.print_and_sleep()

    def print_and_sleep(self):
        print "!!!slave#", self.slave_id_, "/", n_slaves
        print " === start sub thread (sub class) === "
        for i in range(self.n_times_):
            print i, "/", self.n_times_, "sleeping", self.time_to_sleep_, "sec..."
            time.sleep(self.time_to_sleep_)
            print "sub thread (sub class) : " + str(datetime.datetime.today())
        print " === end sub thread (sub class) === "


if __name__ == '__main__':
    n_slaves = 100
    slaves = []
    for i in xrange(n_slaves):
        slv = slave(i)
        slaves.append(slv)
        slv.start()

    # join してやらんと daemon になって処理がおわらんうちに終わってしまう
    # 果たしてこれで良いのか。。。
    for slv in slaves:
        print "!!! waiting slave#", self.slave_id_, "/", n_slaves
        slv.join()
