#!/usr/bin/env python3

'''
watch the output of a job running in jenkins, because in old enough versions of
jenkins, its broken.
'''

import argparse
import sys
import time

import requests

def watch_job():
    '''display the console log of a job running in jenkins on stdout'''

    requests.packages.urllib3.disable_warnings()

    parser = argparse.ArgumentParser()
    parser.add_argument('job', help='the name of the job to watch, including folder structure')
    parser.add_argument('--skip', action='store_true', help='when starting, skip to the end of the log')
    parser.add_argument('--delay', type=int, default=3, help='how long to wait (in seconds) between fetches')
    parser.add_argument('--jenkins', default='https://mombuild.cgifederal.com',
                        help='the url of the jenkins server (with protocol)')

    args = parser.parse_args()

    job_url = "%s/job/%s" % (args.jenkins, args.job)

    sesh = requests.Session()
    sesh.verify = False

    job_resp = sesh.get("%s/api/json" % job_url, params={'tree': 'builds[building,url]{0}'})
    job_resp.raise_for_status()
    job_json = job_resp.json()

    if not job_json['builds'][0]['building']:
        exit('[X] Job is not building')

    build_url = job_json['builds'][0]['url']
    data_url = "%s/logText/progressiveText" % build_url

    start = 0
    if args.skip:
        length = sesh.head(data_url).headers['X-Text-Size']
        start = max(0, int(length) - 5000)

    while True:
        try:
            data_resp_head = sesh.head(data_url, params={'start': start})
            if int(data_resp_head.headers['X-Text-Size']) > start:
                data_resp = sesh.get(data_url, params={'start': start})
                start = int(data_resp.headers['X-Text-Size'])
                print(data_resp.text, end='')
            if 'X-More-Data' not in data_resp_head.headers:
                print('[-] Stream ended', file=sys.stderr)
                break
            time.sleep(args.delay)
        except KeyboardInterrupt:
            exit('[!] Caught Interrupt')


if __name__ == '__main__':
    watch_job()
