#!/usr/bin/expect -f

set timeout -1

spawn gh pr create --title "Update ${OPERATOR_NAME} to ${OPERATOR_VERSION}" --repo $REPO_OWNER/$REPO_NAME

expect "Body"

send -- "\n"

expect "What's next"

send -- "Submit\n"

expect eof