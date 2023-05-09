#!/usr/bin/env python3
from argparse import ArgumentParser
from datetime import date
from git import Repo
from semver import Version
import re

if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('version')

    args = parser.parse_args()

    repo = Repo('.')
    print("Currently active branch: {}".format(repo.active_branch))

    next_version = Version.parse(args.version)
    print(next_version)

    with open('CMakeLists.txt') as file:
        cmake = file.read()

    for line in cmake.splitlines():
        if line.startswith('project'):
            current_version = Version.parse(line.split(' ')[2])
            break

    assert current_version < next_version

    with open('CHANGELOG.md') as file:
        changelog = file.read().replace('## [Unreleased]', '## [Unreleased]\n### Added\n\n### Changed\n\n### Fixed\n\n## [{}] - {}'.format(current_version, date.today().strftime('%Y-%m-%d')))
    with open('CHANGELOG.md', 'w') as file:
        file.write(changelog)

    repo.git.add('CHANGELOG.md')
    repo.git.commit('-m', 'app: close version {} in changelog'.format(current_version))

    with open('CMakeLists.txt', 'w') as file:
        file.write(cmake.replace(str(current_version), str(next_version)))

    repo.git.add('CMakeLists.txt')
    repo.git.commit('-m', 'app: bump to version {}'.format(next_version))

    print('version updated', current_version, '->', next_version)
