#!/usr/bin/expect -f

set timeout -1

spawn gh pr create --title "Update $::env(OPERATOR_NAME) to $::env(OPERATOR_VERSION)" --repo $::env(REPO_OWNER)/$::env(REPO_NAME)

expect "Body"

send -- "\n"

expect "What's next"

send -- "Submit\n"

expect eof