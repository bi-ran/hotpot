#!/usr/bin/env python

from __future__ import print_function

import argparse
import contextlib
import math
import sys

from collections import defaultdict

from CRABAPI.RawCommand import crabCommand as crab

class void():
    def write(self, x):
        pass


@contextlib.contextmanager
def silence():
    original = sys.stdout
    sys.stdout = void()
    yield
    sys.stdout = original


def site_performance(params):
    with silence():
        crab_resp = crab('status', dir=params['dir'])

    joblist = crab_resp['jobList']
    jobs = crab_resp['jobs']

    site_times = defaultdict(list)
    for job in joblist:
        # iterate over jobs that finished
        if job[0] == 'finished':
            jobinfo = jobs[job[1]]
            site_times[jobinfo['SiteHistory'][-1]].append(
                jobinfo['WallDurations'][-1])

    site_summary = {}
    for site, times in site_times.iteritems():
        site_summary[site] = [sum(times) / len(times), len(times)]

    for site, time in sorted(site_summary.items(), key=lambda x: x[1][0]):
        print('{} [{}]: {:.2f}'.format(site, time[1], time[0]))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('dir')

    args = parser.parse_args()

    site_performance(vars(args))
