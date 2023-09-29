#!/usr/bin/env python

import argparse

import requests
import urllib3

def main():
    parser = argparse.ArgumentParser("httping", description="see if a webpage is available")

    parser.add_argument("url", help="the url to request")
    # parser.add_argument("-r", "--retry", "--retries", default=False, type=int, help="Retry a given number of times")
    # parser.add_argument("-v", "--verbose", help="give more informative output")

    args = parser.parse_args()

    sesh = requests.session()

    resp = sesh.head(args.url)
    print(resp)

if __name__ == "__main__":
    main()

