#!/usr/bin/env bats

setup(){
  export GITHUB_REF='refs/heads/master'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
}

teardown() {
  unset INPUT_SNAPSHOT
  unset INPUT_DOCKERFILE
  unset INPUT_REGISTRY
  unset INPUT_CACHE
  unset GITHUB_SHA
}

@test "it pushes master branch to latest" {
  export GITHUB_REF='refs/heads/master'

  run /entrypoint.sh

  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: build -t my/repository:latest .
Called mock with: push my/repository:latest
Called mock with: logout"
  [ "$output" = "$expected" ]
}

@test "it pushes branch as name of the branch" {
  export GITHUB_REF='refs/heads/myBranch'

  run /entrypoint.sh

  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: build -t my/repository:myBranch .
Called mock with: push my/repository:myBranch
Called mock with: logout"
  [ "$output" = "$expected" ]
}

@test "it pushes tags to latest" {
  export GITHUB_REF='refs/tags/myRelease'

  run /entrypoint.sh

  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: build -t my/repository:latest .
Called mock with: push my/repository:latest
Called mock with: logout"
  [ "$output" = "$expected" ]
}

@test "it pushes specific Dockerfile to latest" {
  export INPUT_DOCKERFILE='MyDockerFileName'

  run /entrypoint.sh

  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: build -f MyDockerFileName -t my/repository:latest .
Called mock with: push my/repository:latest
Called mock with: logout"
  [ "$output" = "$expected" ]
}

@test "it pushes branch by sha and date in addition" {
  export INPUT_SNAPSHOT='true'
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export MOCK_DATE='197001010101'

  run /entrypoint.sh

  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: build -t my/repository:latest -t my/repository:19700101010112169e .
Called mock with: push my/repository:latest
Called mock with: push my/repository:19700101010112169e
Called mock with: logout"
  [ "$output" = "$expected" ]
}

@test "it caches image from former build and uses it for snapshot" {
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export MOCK_DATE='197001010101'
  export INPUT_SNAPSHOT='true'
  export INPUT_CACHE='true'

  run /entrypoint.sh

  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: pull my/repository:latest
Called mock with: build --cache-from my/repository:latest -t my/repository:latest -t my/repository:19700101010112169e .
Called mock with: push my/repository:latest
Called mock with: push my/repository:19700101010112169e
Called mock with: logout"
  [ "$output" = "$expected" ]
}

@test "it pushes branch by sha and date with specific Dockerfile" {
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export MOCK_DATE='197001010101'
  export INPUT_SNAPSHOT='true'
  export INPUT_DOCKERFILE='MyDockerFileName'

  run /entrypoint.sh

  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: build -f MyDockerFileName -t my/repository:latest -t my/repository:19700101010112169e .
Called mock with: push my/repository:latest
Called mock with: push my/repository:19700101010112169e
Called mock with: logout"
  [ "$output" = "$expected" ]
}

@test "it caches image from former build and uses it for snapshot with specific Dockerfile" {
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export MOCK_DATE='197001010101'
  export INPUT_SNAPSHOT='true'
  export INPUT_CACHE='true'
  export INPUT_DOCKERFILE='MyDockerFileName'

  run /entrypoint.sh

  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: pull my/repository:latest
Called mock with: build -f MyDockerFileName --cache-from my/repository:latest -t my/repository:latest -t my/repository:19700101010112169e .
Called mock with: push my/repository:latest
Called mock with: push my/repository:19700101010112169e
Called mock with: logout"
  [ "$output" = "$expected" ]
}

@test "it performs a login to another registry" {
  export INPUT_REGISTRY='https://myRegistry'

  run /entrypoint.sh

  local expected="Called mock with: login -u USERNAME --password-stdin https://myRegistry
Called mock with: build -t my/repository:latest .
Called mock with: push my/repository:latest
Called mock with: logout"
  [ "$output" = "$expected" ]
}

@test "it caches the image from a former build" {
  export INPUT_CACHE='true'

  run /entrypoint.sh

  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: pull my/repository:latest
Called mock with: build --cache-from my/repository:latest -t my/repository:latest .
Called mock with: push my/repository:latest
Called mock with: logout"
  [ "$output" = "$expected" ]
}

@test "it errors when with.name was not set" {
  unset INPUT_NAME

  run /entrypoint.sh

  local expected="Unable to find the repository name. Did you set with.name?"
  [ "$output" = "$expected" ]
}

@test "it errors when with.username was not set" {
  unset INPUT_USERNAME

  run /entrypoint.sh

  local expected="Unable to find the username. Did you set with.username?"
  [ "$output" = "$expected" ]
}

@test "it errors when with.password was not set" {
  unset INPUT_PASSWORD

  run /entrypoint.sh

  local expected="Unable to find the password. Did you set with.password?"
  [ "$output" = "$expected" ]
}