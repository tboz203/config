#!/usr/bin/python3

import argparse
import datetime
import fnmatch
import getpass
import json

# from urllib.parse import urljoin

import requests

# import dateutil.parser

from pathlib import Path
from base64 import b64decode


def urljoin(head, *parts):
    url = head
    for part in parts:
        url = url.rstrip('/') + '/' + part.lstrip('/')
    return url

class Connection:
    DATEFORMAT = '%Y-%m-%dT%H:%M:%S.%f'
    MAX_ATTEMPTS = 3

    def _request(self, method, url, headers={}, check_status=True, attempt=0):
        for i in range(self._retries):
            try:
                resp = self._sesh.request(method, url, headers=headers)
                if check_status:
                    resp.raise_for_status()
                break
            except requests.HTTPError as exc:
                if attempt < self.MAX_ATTEMPTS and exc.response.status_code == 401:
                    print('Request failed: Unauthorized')
                    username = input('Username: ')
                    self._sesh.auth = get_credentials(username)
                    return self._request(method, url, headers, check_status, attempt+1)
                else:
                    raise
            except OSError as exc:
                exception = exc
                print(f'request: trapped exec (attempt {i}): {exc}')
            except json.JSONDecodeError:
                print(resp.content)
                raise
        else:
            raise exception

        return resp


    def _get_json(self, url):
        return self._request('get', url).json()


    def _delete(self, url):
        self._request('delete', url)


    def __init__(self, url, credentials, retries=3, tls_verify=True):
        if not '://' in url:
            url = 'https://' + url
        self._url = url

        self._sesh = requests.Session()
        self._sesh.verify = tls_verify
        self._sesh.headers = {
            'Accept': 'application/vnd.docker.distribution.manifest.v2+json, application/json',
            'User-Agent': "docker or something",
        }

        if credentials:
            self._sesh.auth = credentials

        self._retries = retries


    def get_catalog(self):
        url = urljoin(self._url, 'v2/_catalog')
        data = self._get_json(url)
        return data['repositories']

    def get_tags(self, name):
        url = urljoin(self._url, 'v2/%s/tags/list' % name)
        data = self._get_json(url)
        return data['tags']

    def get_manifest(self, name, tag):
        url = urljoin(self._url, 'v2/%s/manifests/%s' % (name, tag))
        data = self._get_json(url)
        return data

    # def get_digest(self, name, tag):
    #     manifest = self.get_manifest(name, tag)
    #     blob = manifest['history'][0].get('v1Compatibility', None)
    #     if not blob:
    #         raise NotImplementedError("Can't do that :)")
    #     data = json.loads(blob)
    #     return data['id']

    # def get_created_date(self, name, tag):
    #     try:
    #         manifest = self.get_manifest(name, tag)
    #     except OSError:
    #         return None
    #     nested = manifest['history'][0]['v1Compatibility']
    #     nested = json.loads(nested)
    #     # cutting off the last few digits b/c python can't natively handle nanoseconds
    #     timestamp = nested['created'][:-4]
    #     return datetime.datetime.strptime(timestamp, self.DATEFORMAT)

    def get_blob(self, name, digest):
        url = urljoin(self._url, f'v2/{name}/blobs/{digest}')
        data = self._get_json(url)
        return data

    def get_digest(self, name, tag):
        return self.get_manifest(name, tag).get('config', {}).get('digest', '?????')

    def get_created_date(self, name, tag):
        try:
            digest = self.get_digest(name, tag)
        except OSError:
            return None
        blob = self.get_blob(name, digest)
        if not 'created' in blob:
            return None
        # cutting off the last few digits b/c python can't natively handle nanoseconds
        timestamp = blob['created'][:-4]
        return datetime.datetime.strptime(timestamp, self.DATEFORMAT)


def collect(registry, names, tag_pattern=None, fast=False, credentials=None, tls_verify=True):
    con = Connection(registry, credentials, tls_verify=tls_verify)

    catalog = con.get_catalog()
    matches = list()
    for name in names:
        matches += fnmatch.filter(catalog, name)

    lines = []
    for repo in matches:
        try:
            tags = con.get_tags(repo)
        except OSError as exc:
            print((exc, exc.filename))
            tags = []
        if tags:
            pairs = []
            if tag_pattern:
                tags = fnmatch.filter(tags, tag_pattern)

            if fast:
                for tag in tags:
                    lines.append((repo, tag, None, None))
            else:
                for tag in tags:
                    created = con.get_created_date(repo, tag)
                    if not created:
                        created = None
                    else:
                        created = str(created.replace(microsecond=0))
                    try:
                        digest = con.get_digest(repo, tag)
                    except (NotImplementedError, OSError):
                        digest = None
                    lines.append((repo, tag, digest, created))
        else:
            lines.append((repo, None, None, None))

    return lines


def display(lines):
    # don't look directly at this function or you may go insane
    sizes = [max(len(str(x)) for x in l) for l in zip(*lines)]
    for repo, tag, digest, created in lines:
        print('{repo!s:{}} | {tag!s:{}} | {digest!s:{}} | {created!s:{}}'.format(*sizes, repo=repo, tag=tag, digest=digest, created=created))


def display_json(lines):
    structure = [{'repo': repo, 'tag': tag, 'digest': digest, 'created': created} for repo, tag, digest, created in lines]
    print(json.dumps(structure, sort_keys=True, indent=4))


def display_images(lines):
    for repo, tag, digest, created in lines:
        if repo and tag:
            print(f'{repo}:{tag}')


def get_docker_config_auth(filename=None) -> dict:
    if not filename:
        filename = Path('~/.docker/config.json').expanduser()

    with open(filename) as fin:
        config_data = json.load(fin)

    if 'auth' not in config_data:
        return {}

    # return {f'https://{host}': hostdict['auth'] for host, hostdict in config_data.get('auth', {}).items()}
    config_dict = {}
    for host, hostdict in config_data['auth']:
        host = f'https://{host}'
        auth = hostdict.get('auth')
        try:
            # undo http basic auth encoding so we can compare usernames later
            auth = b64decode(auth).split(':', 1)
        except Exception:
            pass
        config_dict[host] = auth
    return config_dict


def pick_registry_and_credentials(registry=None, user=None):
    """returns a 2-tuple of (registry, credentials)"""

    # registry passed or not
    # passed registry in config or not
    # user passed or not
    # passed user in config or not

    config_auth = get_docker_config_auth()
    if not registry:
        if config_auth:
            registry, auth = config_auth.popitem()

    credentials = get_credentials(args.user)


def get_credentials(user):
    '''
    given a string in the form `user[:password]`, extract username and
    password, prompting the user for a password if necessary.
    if `user` is `None`, return `None`
    '''

    if user is None:
        return None

    user, password = user.split(':', 1)
    if not password:
        password = getpass.getpass()
    return user, password


def main():
    parser = argparse.ArgumentParser(description='list stuff from docker registry')
    # parser.add_argument('-r', '--registry', default='https://gntbuild.cgifederal.com:5000', help='the registry to list')
    # parser.add_argument('-r', '--registry', default='https://artifacts.cgifederal.com:30100', help='the registry to list')
    # parser.add_argument('-r', '--registry', default='https://docker-approved.artpro.digitalglobe.com:443', help='the registry to list')
    # parser.add_argument('-r', '--registry', default='https://docker.artpro.digitalglobe.com:443', help='the registry to list')
    parser.add_argument('-r', '--registry', help='the registry to list')
    parser.add_argument('names', nargs='+', help='The name(s) of the repos to list. Accepts shell wildcards. (remember to quote them!)')
    parser.add_argument('-t', '--tag-pattern', default=None, help='Shell wildcard pattern to match tags against. (remember to quote them!)')
    parser.add_argument('-u', '--user', help='user[:password] - credentials for the given repository')
    parser.add_argument('--fast', action='store_true', help='just list repos and tags')
    parser.add_argument('-k', '--insecure', action='store_true', help='ignore TLS certificate errors')

    output_group = parser.add_mutually_exclusive_group()
    output_group.add_argument('-j', '--json', action='store_true', help='output in json format')
    output_group.add_argument('-i', '--images', action='store_true', help='output image names (implies --fast)')

    args = parser.parse_args()

    args.fast |= args.images

    try:
        registry, credentials = pick_registry_and_credentials(args.registry, args.user)

        lines = collect(registry, args.names, args.tag_pattern, args.fast, credentials, not args.insecure)

        if args.json:
            display_json(lines)
        elif args.images:
            display_images(lines)
        else:
            display(lines)
    except (KeyboardInterrupt, BrokenPipeError):
        pass


if __name__ == '__main__':
    main()
