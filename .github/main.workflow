workflow "Check Scripts" {
  on = "push"
  resolves = ["update-scripts", "show-failures"]
}

action "run-test" {
  uses = "ailin-nemui/actions-irssi/check-irssi-scripts@master"
  args = "before_install global_env install before_script"
}

action "report-test" {
  uses = "ailin-nemui/actions-irssi/check-irssi-scripts@master"
  needs = ["run-test"]
  args = "global_env script"
}

action "On Master Branch" {
  uses = "actions/bin/filter@master"
  needs = ["report-test"]
  args = "branch master"
}

action "update-scripts" {
  uses = "ailin-nemui/actions-irssi/check-irssi-scripts@master"
  needs = ["On Master Branch"]
  args = "global_env after_script"
  secrets = ["GITHUB_TOKEN"]
}

action "On Pull Request" {
  uses = "actions/bin/filter@master"
  needs = ["report-test"]
  args = "not branch master"
}

action "show-failures" {
  uses = "ailin-nemui/actions-irssi/check-irssi-scripts@master"
  needs = ["On Pull Request"]
  args = "global_env after_script"
}
