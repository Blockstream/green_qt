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

    with open('cmake/ProjectMeta.cmake') as file:
        meta = file.read()

    for line in meta.splitlines():
        if line.startswith('set(BLOCKSTREAM_VERSION'):
            current_version = Version.parse(re.search(r'"([^"]+)"', line).group(1))
            break

    assert current_version < next_version

    with open('CHANGELOG.md') as file:
        changelog = file.read().replace('## [Unreleased]', '## [Unreleased]\n### Added\n\n### Changed\n\n### Fixed\n\n## [{}] - {}'.format(current_version, date.today().strftime('%Y-%m-%d')))
    with open('CHANGELOG.md', 'w') as file:
        file.write(changelog)

    repo.git.add('CHANGELOG.md')
    repo.git.commit('-m', 'app: close version {} in changelog'.format(current_version))

    with open('cmake/ProjectMeta.cmake', 'w') as file:
        file.write(meta.replace(str(current_version), str(next_version)))

    repo.git.add('cmake/ProjectMeta.cmake')
    repo.git.commit('-m', 'app: bump to version {}'.format(next_version))

    print('version updated', current_version, '->', next_version)
