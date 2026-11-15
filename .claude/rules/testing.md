# Testing
There is no test suite. Verification is syntax plus lint:
`cd .claude/scripts && for f in *.sh lib/common.sh; do /bin/bash -n "$f"; done && shellcheck -x -S warning *.sh lib/common.sh`
Test new checks against a throwaway local server or AirPlay (5000/7000); delete any run created and restore `latest`.
