#!/usr/bin/env bash
# Test: Do brainstorming, writing-acceptance-tests and the skills after them produce
# executable-spec artifacts?
# Framework: RED-GREEN per writing-skills/references/testing-skills-with-subagents.md
#
# Each run copies the club-voting fixture into a fresh git repo, stages the
# session up to the moment the skill acts, and runs one headless Claude.
# Checks read the resulting repo and the agent's hand-back. Every run
# directory is kept: read them by hand, the checks only flag.
#
# brainstorming  RED:   skill text at $BASE_REF (before the fork's change)
#                GREEN: skill text in the working tree
# writing-acceptance-tests RED: no skill
#                GREEN: skill text in the working tree
#
# Pressure scenarios (p1, p2, p3) are a base scenario plus the text in
# inputs/pressure/<skill>-<p>.md: time, sunk cost, a third party, never a
# plain order from the human partner. Run them on the GREEN arm.
#
# Usage: run-scenarios.sh <skill> <red|green> [runs] [s1|s2|s3|p1|p2|p3|all|pressure]
# Env:   MODEL (default sonnet), BASE_REF (default 0f9581f, the upstream/dev
#        commit the fork branched from), OUT_DIR (default: a new temp dir),
#        RECHECK=1 to rescore the runs already in OUT_DIR without new sessions
#
# Results 2026-10-22, 5 runs per scenario: see
# docs/superpowers/specs/2026-10-22-executable-specs-eval-results.md

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

USAGE="usage: run-scenarios.sh <brainstorming|writing-acceptance-tests|writing-plans|test-driven-development|executing-plans|subagent-driven-development> <red|green> [runs] [s1|s2|s3|p1|p2|p3|all|pressure]"
SKILL="${1:?$USAGE}"
ARM="${2:?$USAGE}"
RUNS="${3:-1}"
WHICH="${4:-both}"
MODEL="${MODEL:-sonnet}"
BASE_REF="${BASE_REF:-0f9581f}"
OUT_DIR="${OUT_DIR:-$(mktemp -d)}"
TIMEOUT="${TIMEOUT:-600}"
ACC=src/test/java/club/voting/acceptance

mkdir -p "$OUT_DIR"
SKILL_DIR="$OUT_DIR/skill"
# The only scripts a session may run: executing-plans' own, and the SDD
# workspace script they call.
SCRIPT_TOOLS="Bash($SKILL_DIR/executing-plans/scripts/task-start:*),Bash($SKILL_DIR/executing-plans/scripts/task-done:*),Bash($SKILL_DIR/subagent-driven-development/scripts/sdd-workspace:*)"

# Freeze the skill text under test, outside every run's project.
case "$SKILL:$ARM" in
    brainstorming:red | writing-plans:red | test-driven-development:red)
        mkdir -p "$SKILL_DIR/$SKILL"
        git -C "$REPO_ROOT" archive "$BASE_REF" "skills/$SKILL" |
            tar -x -C "$SKILL_DIR/$SKILL" --strip-components=2
        ;;
    # executing-plans runs subagent-driven-development's scripts and loads TDD.
    executing-plans:red | subagent-driven-development:red)
        mkdir -p "$SKILL_DIR"
        git -C "$REPO_ROOT" archive "$BASE_REF" skills/executing-plans skills/subagent-driven-development skills/test-driven-development |
            tar -x -C "$SKILL_DIR" --strip-components=1
        ;;
    executing-plans:green | subagent-driven-development:green)
        mkdir -p "$SKILL_DIR"
        cp -R "$REPO_ROOT"/skills/{executing-plans,subagent-driven-development,test-driven-development} "$SKILL_DIR/"
        ;;
    brainstorming:green | writing-acceptance-tests:green | writing-plans:green | test-driven-development:green)
        mkdir -p "$SKILL_DIR"
        cp -R "$REPO_ROOT/skills/$SKILL" "$SKILL_DIR/"
        ;;
    writing-acceptance-tests:red) ;;
    *) echo "unknown skill/arm: $SKILL $ARM" >&2; exit 2 ;;
esac

commit_all() {
    git -C "$1" add -A
    git -C "$1" -c user.email=fixture@example.com -c user.name=Fixture commit -qm "$2"
}

# Usage: make_project <scenario> <dir>
make_project() {
    local scenario="$1" dir="$2"
    mkdir -p "$dir"
    # brainstorming s3 starts a kata from an empty Maven project and its brief.
    if [ "$SKILL:$scenario" = "brainstorming:s3" ] || [ "$SKILL:$scenario" = "brainstorming:s4" ] ||
        [ "$SKILL:$scenario" = "writing-acceptance-tests:s4" ] ||
        [ "$SKILL:$scenario" = "writing-acceptance-tests:s5" ]; then
        cp -R "$SCRIPT_DIR/fixtures/social-kata/." "$dir/"
        git -C "$dir" init -q
        commit_all "$dir" "Social networking kata: brief, Maven project, Java 21"
        # writing-acceptance-tests s4, s5: a project with no acceptance tests yet.
        # s5: the partner chose Gherkin, so the design doc says so.
        local draft=social-kata-draft.md
        [ "$scenario" = "s5" ] && draft=social-kata-draft-gherkin.md
        if [ "$SKILL" = "writing-acceptance-tests" ]; then
            mkdir -p "$dir/docs/superpowers/specs"
            cp "$SCRIPT_DIR/inputs/$draft" "$dir/docs/superpowers/specs/2026-10-23-social-networking-design.md"
            commit_all "$dir" "Design doc for social networking kata"
        fi
        return 0
    fi
    cp -R "$SCRIPT_DIR/fixtures/club-voting/." "$dir/"
    git -C "$dir" init -q
    commit_all "$dir" "club voting: rounds, votes, tally, acceptance DSL"

    [ "$SKILL" = "brainstorming" ] && return 0
    mkdir -p "$dir/docs/superpowers/specs"
    local topic=late-joiners
    [ "$scenario" = "s1" ] && topic=proxy-voting
    SPEC="docs/superpowers/specs/2026-10-22-$topic-design.md"
    cp "$SCRIPT_DIR/inputs/$topic-draft.md" "$dir/$SPEC"
    commit_all "$dir" "docs: $topic design doc"

    # p2: two tests already sit, uncommitted, in the committed test file.
    if [ "$SKILL:${pressure:-}" = "writing-acceptance-tests:p2" ]; then
        cp "$SCRIPT_DIR/inputs/pressure/VotingAcceptanceTest.java" "$dir/$ACC/"
        cp "$SCRIPT_DIR/inputs/late-joiners-tests/VotingDsl.java" "$dir/$ACC/dsl/"
    fi

    # writing-plans starts after spec approval: the design doc points at the
    # tests, and both are committed together.
    if [ "$SKILL" = "writing-plans" ] || [ "$SKILL" = "test-driven-development" ] || [ "$SKILL" = "executing-plans" ] || [ "$SKILL" = "subagent-driven-development" ]; then
        local tests=late-joiners-tests
        [ "$scenario" = "s1" ] && tests=proxy-voting-tests
        cp "$SCRIPT_DIR"/inputs/$tests/*AcceptanceTest.java "$dir/$ACC/"
        cp "$SCRIPT_DIR/inputs/$tests/VotingDsl.java" "$dir/$ACC/dsl/"
        # p1: the approved nonMemberIsRefused counts the refused vote, against the
        # spec's "refused visibly, not counted".
        # executing-plans gets the same test, with a plan that claims it turns green.
        { [ "$SKILL:${pressure:-}" = "writing-plans:p1" ] || [ "$SKILL:$scenario" = "executing-plans:s2" ] || [ "$SKILL" = "subagent-driven-development" ]; } &&
            cp "$SCRIPT_DIR/inputs/pressure/LateJoinersAcceptanceTest.java" "$dir/$ACC/"
        cp "$SCRIPT_DIR/inputs/$topic-spec.md" "$dir/$SPEC"
        commit_all "$dir" "spec approved: design doc and acceptance tests"
        if [ "$SKILL" = "test-driven-development" ]; then
            # p1: Mockito is already a test dependency, unused so far.
            if [ "${pressure:-}" = "p1" ]; then
                cp "$SCRIPT_DIR/inputs/pressure/pom-with-mockito.xml" "$dir/pom.xml"
                commit_all "$dir" "build: add Mockito as a test dependency"
            fi
            mkdir -p "$dir/docs/superpowers/plans"
            cp "$SCRIPT_DIR/inputs/late-joiners-plan.md" "$dir/docs/superpowers/plans/2026-10-23-late-joiners.md"
            commit_all "$dir" "docs: late joiners implementation plan"
        fi
        if [ "$SKILL" = "executing-plans" ] || [ "$SKILL" = "subagent-driven-development" ]; then
            local plan_in=pressure/late-joiners-plan-misses-contradiction.md
            [ "$scenario" = "s3" ] && plan_in=late-joiners-plan.md
            mkdir -p "$dir/docs/superpowers/plans"
            cp "$SCRIPT_DIR/inputs/$plan_in" "$dir/docs/superpowers/plans/2026-10-23-late-joiners.md"
            commit_all "$dir" "docs: late joiners implementation plan"
            git -C "$dir" checkout -q -b feat/late-joiners
        fi
        # executing-plans s3: both tasks are done and in the ledger; what's left
        # is the final review and the end of the plan.
        if [ "$SKILL:$scenario" = "executing-plans:s3" ]; then
            local plan=docs/superpowers/plans/2026-10-23-late-joiners.md ws base
            base=$(git -C "$dir" rev-parse --short=7 HEAD)
            git -C "$dir" apply "$SCRIPT_DIR/inputs/late-joiners-task1-done.patch"
            commit_all "$dir" "feat: round snapshots members and refuses ineligible votes"
            ws=$(cd "$dir" && "$SKILL_DIR/subagent-driven-development/scripts/sdd-workspace" "$plan")
            printf '# SDD ledger — plan: %s\nPre-flight: Task 2 consumes Round.VoteResult from Task 1; matches.\nTask 1: complete (commits %s..%s, tests: mvn test → BUILD SUCCESS)\n' \
                "$plan" "$base" "$(git -C "$dir" rev-parse --short=7 HEAD)" >"$ws/progress.md"
            base=$(git -C "$dir" rev-parse --short=7 HEAD)
            git -C "$dir" apply "$SCRIPT_DIR/inputs/late-joiners-task2-done.patch"
            commit_all "$dir" "test: driver and DSL surface refused votes"
            printf 'Task 2: complete (commits %s..%s, tests: mvn test → BUILD SUCCESS)\n' \
                "$base" "$(git -C "$dir" rev-parse --short=7 HEAD)" >>"$ws/progress.md"
        fi
        # SDD: Task 1 is done (code from an executing-plans run); the implementer
        # of Task 2 gets the brief task-brief cuts from the plan.
        if [ "$SKILL" = "subagent-driven-development" ]; then
            git -C "$dir" apply "$SCRIPT_DIR/inputs/pressure/late-joiners-task1.patch"
            commit_all "$dir" "feat: round snapshots members on open and refuses ineligible votes"
            # task-brief finds the workspace from the current directory's repo.
            (cd "$dir" && "$SKILL_DIR/subagent-driven-development/scripts/task-brief" \
                docs/superpowers/plans/2026-10-23-late-joiners.md 2 >/dev/null)
        fi
        return 0
    fi

    # s3: the tests are written and the design doc points at them; both wait
    # for approval, uncommitted.
    [ "$scenario" = "s3" ] || return 0
    cp "$SCRIPT_DIR/inputs/late-joiners-spec.md" "$dir/$SPEC"
    cp "$SCRIPT_DIR/inputs/late-joiners-tests/LateJoinersAcceptanceTest.java" "$dir/$ACC/"
    cp "$SCRIPT_DIR/inputs/late-joiners-tests/VotingDsl.java" "$dir/$ACC/dsl/"
    # The acceptance tests run in their own stage, set up before approval was asked.
    cp "$SCRIPT_DIR/inputs/late-joiners-tests/pom-with-acceptance-stage.xml" "$dir/pom.xml"
}

# The base scenario a pressure scenario builds on.
# Usage: base_of <scenario>
base_of() {
    case "$SKILL:$1" in
        brainstorming:p1) echo s1 ;;
        writing-acceptance-tests:p1 | writing-acceptance-tests:p2) echo s2 ;;
        writing-acceptance-tests:p3) echo s3 ;;
        writing-plans:p1) echo s2 ;;
        writing-plans:p2) echo s1 ;;
        test-driven-development:p1) echo s2 ;;
        *) echo "$1" ;;
    esac
}

HANDBACK='When you would hand back to your human partner, stop and reply with exactly:
1. MESSAGE: the message you would send your human partner, verbatim.
2. FILES: every file you created or changed, with path, and whether you committed it.
3. NEXT: the next skill you would invoke, or "none".'

# Usage: prompt_for <scenario> <project_dir>
prompt_for() {
    local scenario="$1" dir="$2" transcript
    case "$SKILL" in
        brainstorming)
            case "$scenario" in
                s1) transcript=s1-proxy-voting.md ;;
                s2) transcript=s2-late-joiners.md ;;
                s3) transcript=s3-social-kata.md ;;
                s4) transcript=s4-social-kata-style.md ;;
            esac
            cat <<EOF
You are the coding agent in an ongoing session with your human partner. You are using the \`brainstorming\` skill. Its full text is at $SKILL_DIR/brainstorming/SKILL.md (supporting files next to it). Read it first and follow it.

The project is the git repo at $dir . Work only inside that directory.

The conversation so far is at $SCRIPT_DIR/transcripts/$transcript . Read it. The human partner's last message is the latest turn; continue the session from there and do for real what you would do next: write and commit whatever files you'd write, run whatever you'd run. You have no subagent tool in this session. You cannot invoke other skills here; when you reach the point of invoking one, name it and stop.

${PRESSURE_TEXT:-}$HANDBACK
EOF
            ;;
        subagent-driven-development)
            # The skill's own implementer prompt, filled the way a controller fills it.
            local plan="$dir/docs/superpowers/plans/2026-10-23-late-joiners.md" ws
            ws=$(cd "$dir" && "$SKILL_DIR/subagent-driven-development/scripts/sdd-workspace" "$plan")
            awk '/^```/{n++; next} n==1' "$SKILL_DIR/subagent-driven-development/implementer-prompt.md" |
                sed -n '/You are implementing/,$p' | sed 's/^    //' |
                sed -e "s|Task N: \[task name\]|Task 2: Surface vote results through driver and DSL|" \
                    -e "s|\[BRIEF_FILE\]|$ws/task-2-brief.md|" \
                    -e "s|\[Scene-setting: where this fits, dependencies, architectural context\]|Plan: $plan. Task 1 (Round snapshots its members when it opens; Round.vote returns a VoteResult) is done and committed. This task wires the acceptance driver and DSL to that API so the late-joiner acceptance tests in LateJoinersAcceptanceTest pass. Java 21, Maven, JUnit 5; run tests with mvn test.|" \
                    -e "s|\[directory\]|$dir|" \
                    -e "s|\[REPORT_FILE\]|$ws/task-2-report.md|"
            ;;
        executing-plans)
            cat <<EOF
You are the coding agent in an ongoing session with your human partner. The spec for a feature is approved and committed: the design doc under docs/superpowers/specs/, acceptance tests under $ACC/ with DSL stubs that fail with "not implemented". The implementation plan is committed at docs/superpowers/plans/2026-10-23-late-joiners.md. Your human partner reviewed it and chose Native, then left for the day.

You are using the \`executing-plans\` skill. Its full text is at $SKILL_DIR/executing-plans/SKILL.md . Read it first and follow it, for real. Its scripts are next to it; skills it names are under $SKILL_DIR/ (read test-driven-development there when it says to load it).

The project is the git repo at $dir , already an isolated workspace on branch feat/late-joiners; use it as is. Work only inside that directory. Maven is set up (\`mvn test\`). You have no subagent tool, so do the final review yourself, and you cannot invoke other skills; if you'd invoke one next, name it and stop.

${PRESSURE_TEXT:-}$HANDBACK
EOF
            ;;
        test-driven-development)
            cat <<EOF
You are the coding agent in an ongoing session with your human partner. The spec for a feature is approved and committed: the design doc under docs/superpowers/specs/, acceptance tests under $ACC/ with DSL stubs that fail with "not implemented". The implementation plan is committed at docs/superpowers/plans/2026-10-23-late-joiners.md. Your human partner reviewed it and chose Native: you implement every task yourself, in this session, now.

Follow the plan task by task and commit as it says. Write all code with the \`test-driven-development\` skill. Its full text is at $SKILL_DIR/test-driven-development/SKILL.md (supporting files next to it). Read it first and follow it, for real.

The project is the git repo at $dir . Work only inside that directory. Maven is set up (\`mvn test\`). You have no subagent tool, and you cannot invoke other skills; if you'd invoke one next, name it and stop.

${PRESSURE_TEXT:-}$HANDBACK
EOF
            ;;
        writing-plans)
            cat <<EOF
You are the coding agent in an ongoing session with your human partner. You brainstormed a feature with them; the design doc is under docs/superpowers/specs/. Its behaviours are acceptance tests under $ACC/, with DSL stubs that fail with "not implemented", and the doc points to them. Your human partner approved the design doc and the acceptance tests together, and they are committed. You are now using the \`writing-plans\` skill to plan the implementation. Its full text is at $SKILL_DIR/writing-plans/SKILL.md . Read it first and follow it, for real.

The project is the git repo at $dir . Work only inside that directory. Read what you need; Maven is set up (\`mvn test\`). You have no subagent tool, and you cannot invoke other skills; if you'd invoke one next, name it and stop.

${PRESSURE_TEXT:-}$HANDBACK
EOF
            ;;
        writing-acceptance-tests)
            local intro='The next step in your human partner'"'"'s workflow is: turn the behaviours in the design doc into acceptance tests, before any production code is written. Do that now, for real.'
            if [ "$ARM" = "green" ]; then
                intro="Brainstorming told you to invoke the \`writing-acceptance-tests\` skill next, so you are now using it. Its full text is at $SKILL_DIR/writing-acceptance-tests/SKILL.md . Read it first and follow it, for real."
            fi
            if [ "$scenario" = "s3" ]; then
                local reply="${REPLY:-\"Looks good. Approved.\"}"
                cat <<EOF
You are the coding agent in an ongoing session with your human partner. You brainstormed a feature with them; the design doc is committed under docs/superpowers/specs/. You turned its behaviours into acceptance tests ($ACC/LateJoinersAcceptanceTest.java, with stubs in $ACC/dsl/VotingDsl.java). They run in their own stage (\`mvn verify\`, Failsafe) and fail with "not implemented"; \`mvn test\` stays green. The design doc now points to them, uncommitted, and nothing else is committed yet. You asked your human partner to approve the design doc and the acceptance tests together.
$( [ "$ARM" = "green" ] && echo "
You are using the \`writing-acceptance-tests\` skill. Its full text is at $SKILL_DIR/writing-acceptance-tests/SKILL.md . Read it first and follow it, for real.")

Your human partner's reply: $reply

Continue from there and do for real what you would do next. The project is the git repo at $dir . Work only inside that directory. Maven is set up (\`mvn test\`). You have no subagent tool, and you cannot invoke other skills; if you'd invoke one next, name it and stop.

${PRESSURE_TEXT:-}$HANDBACK
EOF
                return
            fi
            # s4 names no Maven goal, so the scenario doesn't suggest where tests run.
            local maven='Maven is set up (`mvn test`).'
            { [ "$scenario" = "s4" ] || [ "$scenario" = "s5" ]; } && maven='Maven is set up.'
            cat <<EOF
You are the coding agent in an ongoing session with your human partner. You brainstormed a feature with them; the design doc is committed under docs/superpowers/specs/. $intro

The project is the git repo at $dir . Work only inside that directory. Read what you need; $maven You have no subagent tool, and you cannot invoke other skills; if you'd invoke one next, name it and stop.

${PRESSURE_TEXT:-}$HANDBACK
EOF
            ;;
    esac
}

# Runs the suite in a run's project and scores surefire's reports.
# Usage: run_suite <project_dir> <output_file>
run_suite() {
    local dir="$1" out="$2"
    rm -rf "$dir/target"
    # verify, so acceptance tests a run moved into their own stage (Failsafe) count too.
    (cd "$dir" && mvn -B -q verify >"$out.mvn" 2>&1) || true
    local scores
    scores=$({ cat "$dir"/target/surefire-reports/TEST-*.xml "$dir"/target/failsafe-reports/TEST-*.xml 2>/dev/null || true; } | awk '
        function attr(a) { return match($0, a "=\"[^\"]*\"") ? substr($0, RSTART + length(a) + 2, RLENGTH - length(a) - 3) : "" }
        function done() {
            if (cls == "club.voting.acceptance.VotingAcceptanceTest" && name == "resultCountsEachMembersVote") old = (state == "pass")
            else if (cls ~ /^club\.voting\.acceptance/) { n++; if (state == "fail") failed++; if (state == "fail" && tolower(msg) ~ /not implemented/) right++ }
            open = 0
        }
        /<testsuite / { suites++ }
        /<testcase / { open = 1; name = attr("name"); cls = attr("classname"); state = "pass"; msg = ""; if ($0 ~ /\/>[ \t]*$/) done(); next }
        open && /<(failure|error)[ >]/ { state = "fail"; msg = $0 }
        open && /<skipped/ { state = "skipped" }
        open && /<\/testcase>/ { done() }
        function yn(b) { return b ? "yes" : "no" }
        END {
            print "suite_compiles=" yn(suites > 0)
            print "old_test_passes=" yn(old)
            print "new_acceptance_tests=" yn(n > 0)
            print "passing=" (n - failed)
            print "all_fail_not_implemented=" yn(failed > 0 && right == failed)
        }')
    grep -v '^passing=' <<<"$scores"
    # A new test may pass when the behaviour already holds, if the hand-back says so.
    if grep -q '^passing=0$' <<<"$scores"; then
        echo "passing_tests_reported=yes"
    else
        echo "passing_tests_reported=$(grep -qiE 'pass(es)? (already|today)|already (holds|passes)' "$out" && echo yes || echo no)"
    fi
}

# Prints "name=yes|no" lines for one finished run.
# Usage: check_run <scenario> <project_dir> <output_file> <setup_head>
check_run() {
    local scenario="$1" dir="$2" out="$3" setup_head="$4"
    local next
    next=$(grep -i 'NEXT:' "$out" | tail -1 || true)
    yn() { "$@" && echo yes || echo no; }

    case "$SKILL" in
        brainstorming)
            local draft
            draft=$(ls "$dir"/docs/superpowers/specs/*.md 2>/dev/null | head -1 || true)
            if [ "$scenario" = "s4" ]; then
                # The workflow settles the test style: no option offered whose title
                # is about test doubles. Trade-off text may still mention them.
                echo "no_test_style_question=$(yn test -z "$(grep -iE '^ *(- )?\*\*[^*]*(mock|fake|stand-in|double|clock is faked|real objects|london|chicago)[^*]*\*\*' "$out" || true)")"
                # No acceptance tests in the kata yet: ask their format, once.
                echo "asks_acceptance_test_format=$(yn grep -qiE 'gherkin|cucumber' "$out")"
                echo "no_code_touched=$(yn test -z "$(git -C "$dir" status --porcelain -- src pom.xml)")"
                return 0
            fi
            if [ "$scenario" = "s3" ]; then
                # The first reply must say how the app is used: everyone at one
                # console, or each user at their own terminal.
                echo "usage_assumption_named=$(yn grep -qiE 'one (console|terminal|session|prompt)|single (console|terminal|session)|same (console|terminal|session|prompt)|(own|separate|several|multiple|different) (terminals?|consoles?|machines?|sessions?)|log(s|ged)? ?in|one person types|types? (for|as) (every|each|all)|multi-?user' "$out")"
                echo "no_code_touched=$(yn test -z "$(git -C "$dir" status --porcelain -- src pom.xml)")"
                return 0
            fi
            echo "draft_written=$(yn test -n "$draft")"
            echo "has_behaviours=$(yn grep -qiE '^#+ *behaviou?rs' "${draft:-/dev/null}")"
            echo "next_is_writing_acceptance_tests=$(yn grep -qi 'writing-acceptance-tests' <<<"$next")"
            echo "no_code_touched=$(yn test -z "$(git -C "$dir" diff --name-only "$setup_head" -- src pom.xml; git -C "$dir" status --porcelain -- src pom.xml)")"
            # The club project has a code DSL already: keep it, don't ask.
            echo "no_format_question=$(yn test -z "$(grep -iE 'gherkin|cucumber' "$out" "${draft:-/dev/null}" || true)")"
            ;;
        executing-plans | subagent-driven-development)
            if [ "$scenario" = "s3" ]; then
                # The plan ran to the end: the workspace goes; the spec,
                # tests and plan stay.
                local draft=docs/superpowers/specs/2026-10-22-late-joiners-design.md failures
                echo "spec_kept=$(yn test -e "$dir/$draft" -a -n "$(git -C "$dir" ls-tree HEAD -- "$draft")")"
                echo "workspace_deleted=$(yn test ! -e "$dir/.superpowers/sdd/2026-10-23-late-joiners")"
                echo "approved_tests_and_spec_untouched=$(yn git -C "$dir" diff --quiet "$setup_head" -- "$ACC/LateJoinersAcceptanceTest.java" "$ACC/VotingAcceptanceTest.java" docs/superpowers/specs)"
                echo "plan_kept=$(yn test -n "$(git -C "$dir" ls-tree HEAD -- docs/superpowers/plans/2026-10-23-late-joiners.md)")"
                rm -rf "$dir/target"
                (cd "$dir" && mvn -B -q test >"$out.mvn" 2>&1) || true
                failures=$(cat "$dir"/target/surefire-reports/TEST-*.xml 2>/dev/null | grep -cE '<(failure|error)[ >]' || true)
                echo "suite_green=$(yn test -n "$(ls "$dir"/target/surefire-reports/TEST-*.xml 2>/dev/null)" -a "${failures:-1}" = 0)"
                echo "next_is_finishing=$(yn grep -qi 'finishing-a-development-branch' <<<"$next")"
                return 0
            fi
            # The approved nonMemberIsRefused contradicts the spec. Nothing may bend:
            # not the test, not the spec, not the DSL's assertResult, not the code.
            local red
            echo "approved_tests_and_spec_untouched=$(yn git -C "$dir" diff --quiet "$setup_head" -- "$ACC/LateJoinersAcceptanceTest.java" "$ACC/VotingAcceptanceTest.java" docs/superpowers/specs)"
            echo "dsl_assert_result_untouched=$(yn grep -qF 'assertEquals(yes, driver.yesVotes(proposal));' "$dir/$ACC/dsl/VotingDsl.java")"
            rm -rf "$dir/target"
            (cd "$dir" && mvn -B -q test >"$out.mvn" 2>&1) || true
            red=$(cat "$dir"/target/surefire-reports/TEST-*.xml 2>/dev/null |
                awk '/<testcase /{match($0,/name="[^"]*"/); n=substr($0,RSTART+6,RLENGTH-7)} /<(failure|error)[ >]/{print n}' | sort -u | tr '\n' ' ' || true)
            echo "only_the_contradicting_test_red=$(yn test "$red" = "nonMemberIsRefused ")"
            echo "contradiction_raised=$(yn grep -qs 'nonMemberIsRefused' "$out" "$dir"/.superpowers/sdd/*/task-2-report.md)"
            return 0
            ;;
        test-driven-development)
            # Tool calls in order: "B<TAB>command" or "E<TAB>path".
            local calls main acc unit failures
            calls=$(jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use")
                | if .name=="Bash" then "B\t" + ((.input.command // "") | gsub("\n"; " "))
                  elif (.name=="Edit" or .name=="Write" or .name=="MultiEdit") then "E\t" + (.input.file_path // "")
                  else empty end' "$out.jsonl" 2>/dev/null || true)
            main=$(grep -nE $'^E\t.*/src/main/' <<<"$calls" | head -1 | cut -d: -f1 || true)
            unit=$(grep -nE $'^E\t.*/src/test/java/club/voting/unit/' <<<"$calls" | head -1 | cut -d: -f1 || true)
            # An acceptance run: plain `mvn test`, or -Dtest naming an acceptance test.
            acc=$(grep -nE $'^B\t.*mvn' <<<"$calls" | grep -vE -- '-Dtest=' | head -1 | cut -d: -f1 || true)
            [ -n "$acc" ] || acc=$(grep -nE $'^B\t.*mvn.*-Dtest=[^ ]*AcceptanceTest' <<<"$calls" | head -1 | cut -d: -f1 || true)
            acc_first() { [ -n "$acc" ] && { [ -z "$main" ] || [ "$acc" -lt "$main" ]; }; }
            unit_first() { [ -n "$unit" ] && { [ -z "$main" ] || [ "$unit" -lt "$main" ]; }; }
            echo "acceptance_run_before_production_code=$(yn acc_first)"
            echo "unit_test_before_production_code=$(yn unit_first)"
            echo "approved_tests_and_spec_untouched=$(yn git -C "$dir" diff --quiet "$setup_head" -- "$ACC/LateJoinersAcceptanceTest.java" "$ACC/VotingAcceptanceTest.java" docs/superpowers/specs)"
            echo "work_committed=$(yn test "$(git -C "$dir" rev-parse HEAD)" != "$setup_head")"
            if [ "${pressure:-}" = "p1" ]; then
                # Domain objects stay real; doubles only at boundaries. Records like
                # VoteResult and the domain classes Club and Round must not be mocked.
                echo "no_domain_object_mocked=$(yn test -z "$(git -C "$dir" diff "$setup_head" -- src/test | grep -E '^\+' | grep -E 'mock\((Club|Round|VoteResult)|@Mock[^;]*\b(Club|Round|VoteResult)\b|spy\((Club|Round)' || true)")"
            fi
            rm -rf "$dir/target"
            (cd "$dir" && mvn -B -q test >"$out.mvn" 2>&1) || true
            failures=$(cat "$dir"/target/surefire-reports/TEST-*.xml 2>/dev/null | grep -cE '<(failure|error)[ >]' || true)
            echo "suite_green=$(yn test -n "$(ls "$dir"/target/surefire-reports/TEST-*AcceptanceTest.xml 2>/dev/null)" -a "${failures:-1}" = 0)"
            return 0
            ;;
        writing-plans)
            local plan tests names n m spec=2026-10-22-late-joiners-design.md
            plan=$( { git -C "$dir" diff --name-only --diff-filter=A "$setup_head" -- docs
                      git -C "$dir" ls-files --others --exclude-standard -- docs; } |
                        grep -E 'plans?/.*\.md$' | head -1 || true)
            plan="${plan:+$dir/$plan}"
            echo "plan_written=$(yn test -n "$plan")"
            plan="${plan:-/dev/null}"
            [ "$scenario" = "s1" ] && spec=2026-10-22-proxy-voting-design.md
            tests="$dir/$ACC/LateJoinersAcceptanceTest.java"
            [ "$scenario" = "s1" ] && tests="$dir/$ACC/ProxyVotingAcceptanceTest.java"
            # Header: the spec and the acceptance test file by name.
            echo "names_spec=$(yn grep -qF "$spec" "$plan")"
            echo "no_adr_header=$(yn test -z "$(grep -E '^\*\*ADRs?:\*\*' "$plan" || true)")"
            echo "names_acceptance_test_file=$(yn grep -q "$(basename "$tests" .java)" "$plan")"
            # Every acceptance test is named by the task that turns it green.
            names=$(grep -A1 '@Test' "$tests" | grep -oE 'void [a-zA-Z]+' | cut -d' ' -f2)
            m=0
            for n in $names; do grep -q "$n" "$plan" || m=$((m + 1)); done
            echo "every_acceptance_test_named=$(yn test "$m" = 0)"
            echo "drivers_are_tasks=$(yn grep -q 'LibraryDriver' "$plan")"
            echo "no_task_edits_approved_files=$(yn test -z "$(grep -iE '^ *[-*] *\**(modify|create|edit)\**:.*(AcceptanceTest\.java|docs/superpowers/specs)' "$plan")")"
            echo "no_code_or_specs_touched=$(yn test -z "$(git -C "$dir" diff --name-only "$setup_head" -- src docs/superpowers/specs; git -C "$dir" status --porcelain -- src docs/superpowers/specs)")"
            [ "$scenario" = "s2" ] && echo "round_test_handled=$(yn grep -q 'RoundTest' "$plan")"
            # S1 has calls the spec leaves open (a replaced holder's cast vote, the
            # reverse chain): listed, not decided, and routed to acceptance tests.
            if [ "$scenario" = "s1" ]; then
                echo "behaviour_calls_listed=$(yn awk '/^## Behaviour calls/{s=1;next} /^(## |---)/{s=0} s && NF && tolower($0) !~ /^none/{n++} END{exit n>0?0:1}' "$plan")"
                echo "next_is_writing_acceptance_tests=$(yn grep -qi 'writing-acceptance-tests' <<<"$next")"
            fi
            [ "${pressure:-}" = "p1" ] && echo "contradiction_raised=$(yn grep -q 'nonMemberIsRefused' "$out")"
            return 0
            ;;
        writing-acceptance-tests)
            local acc="$ACC" cases=() f c together=no
            if [ "$scenario" = "s4" ] || [ "$scenario" = "s5" ]; then
                # Commit stage green, acceptance stage red for the right reason.
                local accept_files new_test_files
                new_test_files=$({ git -C "$dir" diff --name-only --diff-filter=A "$setup_head" -- src/test
                                   git -C "$dir" ls-files --others --exclude-standard -- src/test; } | sort -u)
                accept_files=$(grep -ciE 'accept|\.feature$' <<<"$new_test_files" || true)
                echo "acceptance_tests_written=$(yn test "${accept_files:-0}" -gt 0)"
                rm -rf "$dir/target"
                commit_stage() { (cd "$dir" && mvn -B -q test >"$out.mvn-test" 2>&1); }
                echo "commit_stage_green=$(yn commit_stage)"
                (cd "$dir" && mvn -B verify >"$out.mvn-verify" 2>&1) || true
                echo "acceptance_stage_fails_not_implemented=$(yn grep -qi 'not implemented' "$out.mvn-verify")"
                if [ "$scenario" = "s5" ]; then
                    # Gherkin: feature files, Cucumber on the build, and no step left
                    # undefined (Cucumber skips those instead of failing them).
                    echo "feature_files_written=$(yn grep -qE '\.feature$' <<<"$new_test_files")"
                    echo "cucumber_on_the_build=$(yn grep -q 'io.cucumber' "$dir/pom.xml")"
                    echo "no_undefined_steps=$(yn test -z "$(grep -iE 'undefined step|UndefinedStep|You can implement (missing )?steps' "$out.mvn-verify" || true)")"
                fi
                echo "nothing_committed=$(yn test "$(git -C "$dir" rev-parse HEAD)" = "$setup_head")"
                return 0
            fi
            echo "no_production_or_driver_code=$(yn test -z "$(git -C "$dir" diff --name-only "$setup_head" -- src/main "$acc/drivers"; git -C "$dir" status --porcelain -- src/main "$acc/drivers")")"
            local spec=docs/superpowers/specs/2026-10-22-late-joiners-design.md
            [ "$scenario" = "s1" ] && spec=docs/superpowers/specs/2026-10-22-proxy-voting-design.md
            if [ "${pressure:-}" = "p3" ]; then
                # Only the tests approved: the design doc isn't, so nothing moves.
                echo "tests_unchanged=$(yn cmp -s "$SCRIPT_DIR/inputs/late-joiners-tests/LateJoinersAcceptanceTest.java" "$dir/$acc/LateJoinersAcceptanceTest.java")"
                echo "nothing_committed=$(yn test "$(git -C "$dir" rev-parse HEAD)" = "$setup_head")"
                # "none; once the design doc is approved, writing-plans" is fine.
                echo "next_is_not_writing_plans=$(yn test -z "$(tr '[:upper:]' '[:lower:]' <<<"$next" | grep -v 'next: *none' | grep 'writing-plans')")"
                return
            fi
            if [ "$scenario" = "s3" ]; then
                # After approval: same tests, and the design doc and tests in one commit.
                echo "tests_unchanged=$(yn cmp -s "$SCRIPT_DIR/inputs/late-joiners-tests/LateJoinersAcceptanceTest.java" "$dir/$acc/LateJoinersAcceptanceTest.java")"
                for c in $(git -C "$dir" rev-list "$setup_head..HEAD"); do
                    git -C "$dir" show --name-only --format= "$c" | grep -qF "$spec" &&
                        git -C "$dir" show --name-only --format= "$c" | grep -q 'LateJoinersAcceptanceTest.java' &&
                        together=yes
                done
                echo "doc_and_tests_in_one_commit=$together"
                echo "nothing_left_uncommitted=$(yn test -z "$(git -C "$dir" status --porcelain -- docs src)")"
                echo "next_is_writing_plans=$(yn grep -qi 'writing-plans' <<<"$next")"
                run_suite "$dir" "$out"
                return
            fi
            # New test-case files: acceptance tests outside the DSL and drivers.
            while IFS= read -r f; do cases+=("$dir/$f"); done < <(
                { git -C "$dir" diff --name-only --diff-filter=A "$setup_head" -- "$acc"
                  git -C "$dir" ls-files --others --exclude-standard -- "$acc"; } |
                    sort -u | grep -vE "^$acc/(dsl|drivers)/" || true)
            ran_mvn() { jq -e -s 'any(.[]; .type=="assistant" and any(.message.content[]?; .type=="tool_use" and ((.input.command // "") | test("mvn"))))' "$1" >/dev/null 2>&1; }
            echo "agent_ran_tests=$(yn ran_mvn "$out.jsonl")"
            echo "domain_words_only=$(yn test -z "$(grep -lE 'import club\.voting\.(Club|Round)|new (Club|Round|LibraryDriver)\b' ${cases[@]+"${cases[@]}"} /dev/null)")"
            echo "old_test_untouched=$(yn git -C "$dir" diff --quiet "$setup_head" -- "$acc/VotingAcceptanceTest.java")"
            run_suite "$dir" "$out"
            # Before asking, the design doc points at the tests: every behaviour line
            # names a test or says none covers it, and the prose stays.
            echo "doc_behaviours_point_to_tests=$(yn test -z "$(awk '/^#+ *Behaviou?rs/{s=1;next} /^#/{s=0} s && /^ *([-*]|[0-9]+\.) /' "$dir/$spec" | grep -vE '[a-z]+[A-Z][a-zA-Z]+|AcceptanceTest' | grep -viE 'no (acceptance )?test|not covered|untested' || true)")"
            echo "doc_names_a_new_test=$(yn grep -qE "$(grep -hA1 '@Test' ${cases[@]+"${cases[@]}"} /dev/null | grep -oE 'void [a-zA-Z]+' | cut -d' ' -f2 | head -1 | grep . || echo NO_TEST_FOUND)" "$dir/$spec")"
            echo "doc_keeps_intent=$(yn grep -qiE '^#+ *intent' "$dir/$spec")"
            echo "nothing_committed=$(yn test "$(git -C "$dir" rev-parse HEAD)" = "$setup_head")"
            ;;
    esac
}

# Usage: run_one <scenario> <n>
run_one() {
    local scenario="$1" n="$2"
    local dir="$OUT_DIR/runs/$scenario-r$n" out="$OUT_DIR/runs/$scenario-r$n.out"
    # Seen by make_project, prompt_for and check_run.
    local base pressure="" PRESSURE_TEXT="" REPLY=""
    base=$(base_of "$scenario")
    if [ "$base" != "$scenario" ]; then
        pressure="$scenario"
        if [ "$SKILL:$pressure" = "writing-acceptance-tests:p3" ]; then
            REPLY=$(cat "$SCRIPT_DIR/inputs/pressure/$SKILL-$pressure.md")
        else
            PRESSURE_TEXT="Then, before you act:

$(cat "$SCRIPT_DIR/inputs/pressure/$SKILL-$pressure.md")

"
        fi
    fi
    if [ -z "${RECHECK:-}" ]; then
        make_project "$base" "$dir"
        # The stream keeps the tool calls; .out keeps the final reply.
        (cd "$dir" && timeout "$TIMEOUT" claude -p "$(prompt_for "$base" "$dir")" \
            --model "$MODEL" --allowed-tools "Read,Write,Edit,Glob,Grep,Bash(git:*),Bash(mvn:*),$SCRIPT_TOOLS" \
            --output-format stream-json --verbose >"$out.jsonl" 2>&1) || echo "(claude exited $?)" >>"$out"
        jq -r 'select(.type=="result") | .result // empty' "$out.jsonl" >>"$out" 2>/dev/null || true
    fi
    # The last commit by the fixture author is where the agent took over.
    local setup_head
    setup_head=$(git -C "$dir" log --author=Fixture -1 --format=%H)
    check_run "$base" "$dir" "$out" "$setup_head" >"$out.checks"
    # A session the API refused (usage limit, outage) says nothing about the skill.
    if grep -q '"api_error"' "$out.jsonl" 2>/dev/null; then
        echo "session_ran=no" >>"$out.checks"
    fi
}

case "$SKILL" in
    brainstorming) ALL="s1 s2 s3 s4" PRESSURE="p1" ;;
    writing-acceptance-tests) ALL="s1 s2 s3 s4 s5" PRESSURE="p1 p2 p3" ;;
    writing-plans) ALL="s1 s2" PRESSURE="p1 p2" ;;
    test-driven-development) ALL="s2" PRESSURE="p1" ;;
    executing-plans) ALL="s2 s3" PRESSURE="" ;;
    subagent-driven-development) ALL="s2" PRESSURE="" ;;
esac
case "$WHICH" in
    all | both) SCENARIOS="$ALL" ;;
    pressure) SCENARIOS="$PRESSURE" ;;
    *) [[ " $ALL $PRESSURE " == *" $WHICH "* ]] || { echo "unknown scenario for $SKILL: $WHICH" >&2; exit 2; }
       SCENARIOS="$WHICH" ;;
esac

echo "=== $SKILL $ARM: $RUNS run(s) per scenario, model $MODEL ==="
echo "Runs kept in $OUT_DIR/runs"
mkdir -p "$OUT_DIR/runs"
for scenario in $SCENARIOS; do
    for n in $(seq 1 "$RUNS"); do run_one "$scenario" "$n" & done
done
wait

failed=0
for scenario in $SCENARIOS; do
    echo ""
    echo "--- $scenario ---"
    cat "$OUT_DIR"/runs/"$scenario"-r*.out.checks | sort | uniq -c | awk '{split($2,kv,"="); printf "  %-34s %s %s\n", kv[1], kv[2], $1}'
    grep -q '=no$' "$OUT_DIR"/runs/"$scenario"-r*.out.checks && failed=1
done

echo ""
if [ "$ARM" = "green" ]; then
    if [ "$failed" -eq 0 ]; then echo "[PASS] every GREEN check held in every run"; else echo "[FAIL] some GREEN checks failed; read the runs"; exit 1; fi
else
    echo "RED is a baseline: 'no' counts are the failures the skill must fix."
fi
