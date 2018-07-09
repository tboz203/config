#!/usr/bin/env python
# pylint: disable=missing-docstring

import sys
import time
import requests

requests.packages.urllib3.disable_warnings()

def watch_job(job_name, jenkins_url, delay, skip):
    job_url = "%s/job/%s" % (jenkins_url, job_name)

    sesh = requests.Session()
    sesh.verify = False

    job_resp = sesh.get("%s/api/json" % job_url,
                        params={'tree': 'builds[building,url]{0}'})
    job_resp.raise_for_status()
    job_json = job_resp.json()

    if not job_json['builds'][0]['building']:
        print('[X] Job is not building', file=sys.stderr)
        exit(1)

    build_url = job_json['builds'][0]['url']
    data_url = "%s/logText/progressiveText" % build_url

    start = 0
    if skip:
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
            time.sleep(delay)
        except KeyboardInterrupt:
            print('[!] Caught Interrupt', file=sys.stderr)
            break


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('job')
    parser.add_argument('--skip', action='store_true')
    parser.add_argument('--delay', type=int, default=3)
    parser.add_argument('--jenkins', default='https://mombuild.cgifederal.com')

    args = parser.parse_args()

    watch_job(args.job, args.jenkins, args.delay, args.skip)


if __name__ == '__main__':
    main()
