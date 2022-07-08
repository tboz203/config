#!/usr/bin/python3
"""
Find git repositories and guess tracking branches.
"""

# things i'm interested in having:
# - a goddamn stroke
# - match local branches to remotes w/ the same name
# - `--correct-existing`: that plus correcting existing branches
# - `--validate`: like `--correct-existing` but just checks, doesn't change

import argparse
import logging
from typing import Any, Callable, List, Optional, Sequence

import git  # type: ignore
from update_repos import find_git_repos

logger = logging.getLogger("set-tracking-branches")


def set_unset_tracking_branches(repo: git.Repo) -> None:
    """
    find and update branches in a git repo that have no tracking branch set,
    but for which a remote branch exists with the same name.

    e.g. `master` is set to track `origin/master`, `story/foo/bar` is set to
    track `origin/story/foo/bar`, etc.

    note: we currently only consider the `origin` remote.
    """

    for branch in repo.heads:
        if not branch.tracking_branch():
            origin = repo.remotes["origin"]
            # best way I could find to check if a branch exists
            if hasattr(origin.refs, branch.name):
                logger.info("setting tracking branch: %s %s", repo.working_dir, branch)
                branch.set_tracking_branch(origin.refs[branch.name])
            else:
                logger.info('matching upstream branch does not exist: %s %s', repo.working_dir, branch)
        else:
            logger.debug("already tracking: %s %s", repo.working_dir, branch)


def correct_existing_tracking_branches(repo: git.Repo) -> None:
    """
    detect and correct all branches with remote tracking branches that do not
    have the same name.

    e.g. if `master` has a tracking branch, it must be `origin/master`, and if
    `story/foo/bar` is set to track `origin/master` while
    `origin/story/foo/bar` exists, it will be updated to track the latter.

    note: we currently only consider the `origin` remote.
    """
    origin = repo.remotes["origin"]
    for branch in repo.heads:
        tracking = branch.tracking_branch()
        if not tracking:
            logger.debug("no tracking branch: %s %s", repo.working_dir, branch)
            continue
        correct_remote = origin.refs[branch.name]
        if branch.name != tracking.remote_head and correct_remote.is_valid():
            logger.info("correcting tracking branch: %s %s", repo.working_dir, branch)
            branch.set_tracking_branch(correct_remote)
        else:
            logger.debug("already tracking: %s %s", repo.working_dir, branch)


def validate_tracking_branches(repo: git.Repo) -> bool:
    """
    detect and log all branches with remote tracking branches that to not have
    the same name.

    e.g. if `master` has a tracking branch, it must be `origin/master`, and if
    `story/foo/bar` is set to track `origin/master`, a warning will be logged.

    note: in the case of `story/foo/bar` above, a message will be logged
    regardless of the existence of `origin/story/foo/bar`, an intentional
    asymmetry between this function and `correct_existing_tracking_branches`.
    """
    all_valid = True
    for branch in repo.heads:
        tracking = branch.tracking_branch()
        if not tracking:
            logger.debug("no tracking branch to validate: %s %s", repo.working_dir, branch)
            continue
        if branch.name != tracking.remote_head:
            all_valid = False
            logging.warning("asymmetric tracking branch: %s %s -> %s", repo.working_dir, branch, tracking)
        else:
            logger.debug("tracking branch is valid: %s %s", repo.working_dir, branch)
    return all_valid


def parse_arguments(argv: Optional[Sequence[str]]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Update tracking branches in git repos.")
    parser.add_argument(
        "directories",
        nargs="*",
        default=["."],
        help="directories to search for repositories (defaults to current directory)",
    )
    parser.add_argument(
        "-d",
        "--depth",
        type=int,
        help="maximum depth to search for repositories",
    )
    parser.add_argument(
        "-e",
        "--exclude",
        action="append",
        help="directories to exclude from consideration; may be repeated; accepts wildcards (remember to quote them!)",
    )
    action_group = parser.add_mutually_exclusive_group()
    action_group.add_argument(
        "-c",
        "--correct-existing",
        action="store_true",
        help="Instead of setting unset tracking branches, "
        "find and correct existing tracking branches that do not match.",
    )
    action_group.add_argument(
        "-v",
        "--validate",
        action="store_true",
        help="Instead of setting unset tracking branches, find and log existing tracking branches that do not match.",
    )

    volume_group = parser.add_mutually_exclusive_group()
    volume_group.add_argument("-V", "--verbose", action="store_true", help="Be more verbose")
    volume_group.add_argument("-q", "--quiet", action="store_true", help="Be quieter")
    args = parser.parse_args(argv)
    return args


def main(argv: Optional[Sequence[str]] = None) -> None:
    logging.basicConfig(level=logging.DEBUG, format="[%(levelname)8s %(asctime)s] %(message)s")
    args = parse_arguments(argv)

    if args.verbose:
        logger.setLevel(logging.DEBUG)
    elif args.quiet:
        logger.setLevel(logging.WARNING)
    else:
        logger.setLevel(logging.INFO)

    action: Callable[[git.Repo], Any]
    if args.correct_existing:
        action = correct_existing_tracking_branches
    elif args.validate:
        action = validate_tracking_branches
    else:
        action = set_unset_tracking_branches

    for directory in args.directories:
        for path in find_git_repos(directory, maxdepth=args.depth, exclude=args.exclude):
            action(git.Repo(path))


if __name__ == "__main__":
    main()
