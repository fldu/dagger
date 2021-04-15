setup() {
    load 'helpers'

    common_setup
}

@test "dagger list" {
    run "$DAGGER" list
    assert_success
    assert_output ""

    "$DAGGER" new --plan-dir "$TESTDIR"/cli/simple simple

    run "$DAGGER" list
    assert_success
    assert_output --partial "simple"
}

@test "dagger new --plan-dir" {
    run "$DAGGER" list
    assert_success
    assert_output ""

    "$DAGGER" new --plan-dir "$TESTDIR"/cli/simple simple

    # duplicate name
    run "$DAGGER" new --plan-dir "$TESTDIR"/cli/simple simple
    assert_failure

    # verify the plan works
    "$DAGGER" up -d "simple"

    # verify we have the right plan
    run "$DAGGER" query -f cue -d "simple" -c -f json
    assert_success
    assert_output --partial '{
  "bar": "another value",
  "computed": "test",
  "foo": "value"
}'
}

@test "dagger new --plan-git" {
    "$DAGGER" new --plan-git https://github.com/samalba/dagger-test.git simple
    "$DAGGER" up -d "simple"
    run "$DAGGER" query -f cue -d "simple" -c
    assert_success
    assert_output --partial '{
    foo: "value"
    bar: "another value"
}'
}

@test "dagger query" {
    "$DAGGER" new --plan-dir "$TESTDIR"/cli/simple simple
    run "$DAGGER" query -l error -d "simple"
    assert_success
    assert_output '{
  "bar": "another value",
  "foo": "value"
}'
    # concrete should fail at this point since we haven't up'd
    run "$DAGGER" query -d "simple" -c
    assert_failure

    # target
    run "$DAGGER" -l error query -d "simple" foo
    assert_success
    assert_output '"value"'

    # ensure computed values show up
    "$DAGGER" up -d "simple"
    run "$DAGGER" -l error query -d "simple"
    assert_success
    assert_output --partial '"computed": "test"'

    # concrete should now work
    "$DAGGER" query -d "simple" -c

    # --no-computed should yield the same result as before
    run "$DAGGER" query -l error --no-computed -d "simple"
    assert_success
    assert_output '{
  "bar": "another value",
  "foo": "value"
}'

    # --no-plan should give us only the computed values
    run "$DAGGER" query -l error --no-plan -d "simple"
    assert_success
    assert_output '{
  "computed": "test"
}'
}

@test "dagger plan" {
    "$DAGGER" new --plan-dir "$TESTDIR"/cli/simple simple

    # plan dir
    "$DAGGER" -d "simple" plan dir "$TESTDIR"/cli/simple
    run "$DAGGER" -d "simple" query
    assert_success
    assert_output --partial '"foo": "value"'

    # plan git
    "$DAGGER" -d "simple" plan git https://github.com/samalba/dagger-test.git
    run "$DAGGER" -d "simple" query
    assert_success
    assert_output --partial '"foo": "value"'
}

@test "dagger input" {
    "$DAGGER" new --plan-dir "$TESTDIR"/cli/input "input"

    # missing input
    "$DAGGER"  up -d "input"
    run "$DAGGER" -l error query -d "input"
    assert_success
    assert_output '{
  "foo": "bar"
}'

    # input dir
    "$DAGGER" input -d "input" dir "source" "$TESTDIR"/cli/input/testdata
    "$DAGGER" "${DAGGER_BINARY_ARGS[@]}" up -d "input"
    "$DAGGER"  up -d "input"
    run "$DAGGER" -l error query -d "input"
    assert_success
    assert_output '{
  "bar": "thisisatest\n",
  "foo": "bar",
  "source": {}
}'

    # input git
    "$DAGGER" input -d "input" git "source" https://github.com/samalba/dagger-test-simple.git
    "$DAGGER" up -d "input"
    run "$DAGGER" -l error query -d "input"
    assert_output '{
  "bar": "testgit\n",
  "foo": "bar",
  "source": {}
}'
}