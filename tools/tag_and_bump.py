#!/usr/bin/env python3
from argparse import ArgumentParser
from git import Repo
from semver import VersionInfo


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('--major', type=int, required=True)
    parser.add_argument('--minor', type=int, required=True)
    parser.add_argument('--patch', type=int, required=True)
    parser.add_argument('--sign', default=False, action='store_true')
    parser.add_argument('--release_notes', type=str)

    args = parser.parse_args()

    repo = Repo('.')
    assert str(repo.active_branch) == 'master'
    assert not repo.is_dirty()

    next_version = VersionInfo(args.major, args.minor, args.patch)

    with open('version.pri') as file:
        major = int(next(file).split(' = ')[1])
        minor = int(next(file).split(' = ')[1])
        patch = int(next(file).split(' = ')[1])
        current_version = VersionInfo(major, minor, patch)

    assert current_version < next_version

    tag = repo.create_tag('release_{}'.format(current_version), sign=args.sign)
    print('tag created', tag)

    with open('version.pri', 'w') as file:
        file.write('VERSION_MAJOR = {}\n'.format(next_version.major))
        file.write('VERSION_MINOR = {}\n'.format(next_version.minor))
        file.write('VERSION_PATCH = {}\n'.format(next_version.patch))
        file.write('VERSION_PRERELEASE =\n')

    repo.git.add('version.pri')
    repo.git.commit('-m', 'Bump to version {}'.format(next_version))

    print('version updated', current_version, '->', next_version)
