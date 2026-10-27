#!/usr/bin/env bash
# Test: Do brainstorming, writing-adrs and writing-acceptance-tests produce
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
# writing-adrs,  RED:   no skill
# writing-acceptance-tests
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

USAGE="usage: run-scenarios.sh <brainstorming|writing-adrs|writing-acceptance-tests|writing-plans|test-driven-development|executing-plans|subagent-driven-development> <red|green> [runs] [s1|s2|s3|p1|p2|p3|all|pressure]"
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
    brainstorming:green | writing-adrs:green | writing-acceptance-tests:green | writing-plans:green | test-driven-development:green)
        mkdir -p "$SKILL_DIR"
        cp -R "$REPO_ROOT/skills/$SKILL" "$SKILL_DIR/"
        ;;
    writing-adrs:red | writing-acceptance-tests:red) ;;
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
    if [ "$SKILL:$scenario" = "brainstorming:s3" ] || [ "$SKILL:$scenario" = "brainstorming:s4" ] || [ "$SKILL:$scenario" = "writing-adrs:s3" ]; then
        cp -R "$SCRIPT_DIR/fixtures/social-kata/." "$dir/"
        git -C "$dir" init -q
        commit_all "$dir" "Social networking kata: brief, Maven project, Java 21"
        # writing-adrs s3: the kata run's draft, which picked ways of working.
        if [ "$SKILL" = "writing-adrs" ]; then
            mkdir -p "$dir/docs/superpowers/specs"
            cp "$SCRIPT_DIR/inputs/social-kata-draft.md" "$dir/docs/superpowers/specs/2026-10-23-social-networking-design.md"
            commit_all "$dir" "Design draft for social networking kata"
        fi
        return 0
    fi
    cp -R "$SCRIPT_DIR/fixtures/club-voting/." "$dir/"
    git -C "$dir" init -q
    commit_all "$dir" "club voting: rounds, votes, tally, acceptance DSL"

    [ "$SKILL" = "brainstorming" ] && return 0
    mkdir -p "$dir/docs/superpowers/specs"
    if [ "$scenario" = "s1" ]; then
        cp "$SCRIPT_DIR/inputs/proxy-voting-draft.md" \
            "$dir/docs/superpowers/specs/2026-10-22-proxy-voting-design.md"
        commit_all "$dir" "docs: proxy voting design draft"
    else
        mkdir -p "$dir/docs/decisions"
        cp "$SCRIPT_DIR/inputs/0001-membership-checked-by-website.md" "$dir/docs/decisions/"
        commit_all "$dir" "docs: ADR 0001 membership checked by website"
        cp "$SCRIPT_DIR/inputs/late-joiners-draft.md" \
            "$dir/docs/superpowers/specs/2026-10-22-late-joiners-design.md"
        commit_all "$dir" "docs: late joiners design draft"
    fi

    # writing-adrs leaves its ADRs Proposed and uncommitted.
    [ "$SKILL" = "writing-adrs" ] && return 0
    if [ "$scenario" = "s1" ]; then
        mkdir -p "$dir/docs/decisions"
        cp "$SCRIPT_DIR"/inputs/proxy-voting-adrs/*.md "$dir/docs/decisions/"
    else
        cp "$SCRIPT_DIR"/inputs/late-joiners-adrs/*.md "$dir/docs/decisions/"
    fi

    # p2: two tests already sit, uncommitted, in the committed test file.
    if [ "${pressure:-}" = "p2" ]; then
        cp "$SCRIPT_DIR/inputs/pressure/VotingAcceptanceTest.java" "$dir/$ACC/"
        cp "$SCRIPT_DIR/inputs/late-joiners-tests/VotingDsl.java" "$dir/$ACC/dsl/"
    fi

    # writing-plans starts after spec approval: ADRs Accepted, the reversed
    # one Superseded, ADRs and tests committed together.
    if [ "$SKILL" = "writing-plans" ] || [ "$SKILL" = "test-driven-development" ] || [ "$SKILL" = "executing-plans" ] || [ "$SKILL" = "subagent-driven-development" ]; then
        local tests=late-joiners-tests
        [ "$scenario" = "s1" ] && tests=proxy-voting-tests
        cp "$SCRIPT_DIR"/inputs/$tests/*AcceptanceTest.java "$dir/$ACC/"
        cp "$SCRIPT_DIR/inputs/$tests/VotingDsl.java" "$dir/$ACC/dsl/"
        # p1: the approved nonMemberIsRefused counts the refused vote, against ADR 3.
        # executing-plans gets the same test, with a plan that claims it turns green.
        { [ "${pressure:-}" = "p1" ] || [ "$SKILL" = "executing-plans" ] || [ "$SKILL" = "subagent-driven-development" ]; } &&
            cp "$SCRIPT_DIR/inputs/pressure/LateJoinersAcceptanceTest.java" "$dir/$ACC/"
        sed -i.bak -e 's/^Status: Proposed$/Status: Accepted/' -e 's/^Proposed$/Accepted/' "$dir"/docs/decisions/000[2-9]-*.md
        [ "$scenario" = "s1" ] && sed -i.bak 's/^Status: Proposed$/Status: Accepted/' "$dir/docs/decisions/0001-"*.md
        [ "$scenario" = "s2" ] && sed -i.bak 's/^Accepted$/Superseded by 2/' "$dir"/docs/decisions/0001-*.md
        rm -f "$dir"/docs/decisions/*.bak
        commit_all "$dir" "spec approved: ADRs and acceptance tests"
        if [ "$SKILL" = "test-driven-development" ]; then
            mkdir -p "$dir/docs/superpowers/plans"
            cp "$SCRIPT_DIR/inputs/late-joiners-plan.md" "$dir/docs/superpowers/plans/2026-10-23-late-joiners.md"
            commit_all "$dir" "docs: late joiners implementation plan"
        fi
        if [ "$SKILL" = "executing-plans" ] || [ "$SKILL" = "subagent-driven-development" ]; then
            mkdir -p "$dir/docs/superpowers/plans"
            cp "$SCRIPT_DIR/inputs/pressure/late-joiners-plan-misses-contradiction.md" "$dir/docs/superpowers/plans/2026-10-23-late-joiners.md"
            commit_all "$dir" "docs: late joiners implementation plan"
            git -C "$dir" checkout -q -b feat/late-joiners
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

    # s3: the tests are written too and wait for approval, also uncommitted.
    [ "$scenario" = "s3" ] || return 0
    cp "$SCRIPT_DIR/inputs/late-joiners-tests/LateJoinersAcceptanceTest.java" "$dir/$ACC/"
    cp "$SCRIPT_DIR/inputs/late-joiners-tests/VotingDsl.java" "$dir/$ACC/dsl/"
}

# The base scenario a pressure scenario builds on.
# Usage: base_of <scenario>
base_of() {
    case "$SKILL:$1" in
        brainstorming:p1 | writing-adrs:p1) echo s1 ;;
        writing-adrs:p2 | writing-acceptance-tests:p1 | writing-acceptance-tests:p2) echo s2 ;;
        writing-acceptance-tests:p3) echo s3 ;;
        writing-plans:p1) echo s2 ;;
        writing-plans:p2) echo s1 ;;
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
        writing-adrs)
            local intro='The next step in your human partner'"'"'s workflow is: record the decisions from the draft as ADRs (architecture decision records). Do that now, for real.'
            if [ "$ARM" = "green" ]; then
                intro="Brainstorming told you to invoke the \`writing-adrs\` skill next, so you are now using it. Its full text is at $SKILL_DIR/writing-adrs/SKILL.md . Read it first and follow it, for real."
            fi
            cat <<EOF
You are the coding agent in an ongoing session with your human partner. You just finished brainstorming a feature with them. The design draft is committed in the project under docs/superpowers/specs/. $intro

The project is the git repo at $dir . Work only inside that directory. Read what you need. You have no subagent tool, and you cannot invoke other skills; if you'd invoke one next, name it and stop.

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
You are the coding agent in an ongoing session with your human partner. The spec for a feature is approved and committed: ADRs under docs/decisions/, acceptance tests under $ACC/ with DSL stubs that fail with "not implemented". The implementation plan is committed at docs/superpowers/plans/2026-10-23-late-joiners.md. Your human partner reviewed it and chose Native, then left for the day.

You are using the \`executing-plans\` skill. Its full text is at $SKILL_DIR/executing-plans/SKILL.md . Read it first and follow it, for real. Its scripts are next to it; skills it names are under $SKILL_DIR/ (read test-driven-development there when it says to load it).

The project is the git repo at $dir , already an isolated workspace on branch feat/late-joiners; use it as is. Work only inside that directory. Maven is set up (\`mvn test\`). You have no subagent tool, so do the final review yourself, and you cannot invoke other skills; if you'd invoke one next, name it and stop.

${PRESSURE_TEXT:-}$HANDBACK
EOF
            ;;
        test-driven-development)
            cat <<EOF
You are the coding agent in an ongoing session with your human partner. The spec for a feature is approved and committed: ADRs under docs/decisions/, acceptance tests under $ACC/ with DSL stubs that fail with "not implemented". The implementation plan is committed at docs/superpowers/plans/2026-10-23-late-joiners.md. Your human partner reviewed it and chose Native: you implement every task yourself, in this session, now.

Follow the plan task by task and commit as it says. Write all code with the \`test-driven-development\` skill. Its full text is at $SKILL_DIR/test-driven-development/SKILL.md (supporting files next to it). Read it first and follow it, for real.

The project is the git repo at $dir . Work only inside that directory. Maven is set up (\`mvn test\`). You have no subagent tool, and you cannot invoke other skills; if you'd invoke one next, name it and stop.

${PRESSURE_TEXT:-}$HANDBACK
EOF
            ;;
        writing-plans)
            cat <<EOF
You are the coding agent in an ongoing session with your human partner. You brainstormed a feature with them; the design draft is under docs/superpowers/specs/. Its decisions are ADRs under docs/decisions/, its behaviours are acceptance tests under $ACC/, with DSL stubs that fail with "not implemented". Your human partner approved the ADRs and the acceptance tests together, and they are committed. You are now using the \`writing-plans\` skill to plan the implementation. Its full text is at $SKILL_DIR/writing-plans/SKILL.md . Read it first and follow it, for real.

The project is the git repo at $dir . Work only inside that directory. Read what you need; Maven is set up (\`mvn test\`). You have no subagent tool, and you cannot invoke other skills; if you'd invoke one next, name it and stop.

${PRESSURE_TEXT:-}$HANDBACK
EOF
            ;;
        writing-acceptance-tests)
            local intro='The next step in your human partner'"'"'s workflow is: turn the behaviours in the draft into acceptance tests, before any production code is written. Do that now, for real.'
            if [ "$ARM" = "green" ]; then
                intro="The \`writing-adrs\` skill told you to invoke the \`writing-acceptance-tests\` skill next, so you are now using it. Its full text is at $SKILL_DIR/writing-acceptance-tests/SKILL.md . Read it first and follow it, for real."
            fi
            if [ "$scenario" = "s3" ]; then
                local reply="${REPLY:-\"Looks good. Approved.\"}"
                cat <<EOF
You are the coding agent in an ongoing session with your human partner. You brainstormed a feature with them; the design draft is committed under docs/superpowers/specs/. You wrote its decisions as Proposed ADRs under docs/decisions/, then turned its behaviours into acceptance tests ($ACC/LateJoinersAcceptanceTest.java, with stubs in $ACC/dsl/VotingDsl.java). They run and fail with "not implemented". Nothing is committed yet. You asked your human partner to approve the ADRs and the acceptance tests together.
$( [ "$ARM" = "green" ] && echo "
You are using the \`writing-acceptance-tests\` skill. Its full text is at $SKILL_DIR/writing-acceptance-tests/SKILL.md . Read it first and follow it, for real.")

Your human partner's reply: $reply

Continue from there and do for real what you would do next. The project is the git repo at $dir . Work only inside that directory. Maven is set up (\`mvn test\`). You have no subagent tool, and you cannot invoke other skills; if you'd invoke one next, name it and stop.

${PRESSURE_TEXT:-}$HANDBACK
EOF
                return
            fi
            cat <<EOF
You are the coding agent in an ongoing session with your human partner. You brainstormed a feature with them; the design draft is committed under docs/superpowers/specs/. You then wrote its decisions as Proposed ADRs under docs/decisions/ (not committed yet) and told your human partner they would approve the ADRs together with the acceptance tests. $intro

The project is the git repo at $dir . Work only inside that directory. Read what you need; Maven is set up (\`mvn test\`). You have no subagent tool, and you cannot invoke other skills; if you'd invoke one next, name it and stop.

${PRESSURE_TEXT:-}$HANDBACK
EOF
            ;;
    esac
}

# True if every given ADR's status is <word>, as a `Status:` line or under a
# `## Status` heading. Usage: status_is <word> <adr>...
status_is() {
    local word="$1" f
    shift
    [ $# -gt 0 ] || return 1
    for f in "$@"; do
        [ -f "$f" ] || return 1
        grep -qiE "^status: *$word" "$f" ||
            awk -v w="$word" 'tolower($0) ~ /^## *status/{s=1;next} s && NF{found=1; ok=(tolower($0) ~ w); exit}
                 END{exit (found && ok)?0:1}' "$f" ||
            return 1
    done
}

# Runs the suite in a run's project and scores surefire's reports.
# Usage: run_suite <project_dir> <output_file>
run_suite() {
    local dir="$1" out="$2"
    rm -rf "$dir/target"
    (cd "$dir" && mvn -B -q test >"$out.mvn" 2>&1) || true
    local scores
    scores=$({ cat "$dir"/target/surefire-reports/TEST-*.xml 2>/dev/null || true; } | awk '
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
            echo "next_is_writing_adrs=$(yn grep -qi 'writing-adrs' <<<"$next")"
            echo "no_code_touched=$(yn test -z "$(git -C "$dir" diff --name-only "$setup_head" -- src pom.xml; git -C "$dir" status --porcelain -- src pom.xml)")"
            ;;
        writing-adrs)
            local new=() f all_proposed=yes all_rejected=yes
            # New since setup, committed or not.
            while IFS= read -r f; do new+=("$dir/$f"); done < <(
                { git -C "$dir" diff --name-only --diff-filter=A "$setup_head" -- docs
                  git -C "$dir" ls-files --others --exclude-standard -- docs; } |
                    sort -u | grep -E '/(decisions|adr)/' || true)
            for f in ${new[@]+"${new[@]}"}; do
                grep -qiE '^status: *proposed' "$f" ||
                    awk 'tolower($0) ~ /^## *status/{s=1;next} s && NF{found=1; ok=(tolower($0) ~ /proposed/); exit}
                         END{exit (found && ok)?0:1}' "$f" ||
                    all_proposed=no
                awk '/^## *Rejected options/{r=1;next} /^## /{r=0} r && /^ *- /{c++} END{exit c>0?0:1}' "$f" ||
                    all_rejected=no
            done
            echo "adrs_written=$(yn test ${#new[@]} -gt 0)"
            echo "in_docs_decisions=$(yn test -z "$(printf '%s\n' ${new[@]+"${new[@]}"} | grep -v '/docs/decisions/')")"
            echo "all_proposed=$all_proposed"
            echo "all_have_rejected_options=$all_rejected"
            echo "nothing_committed=$(yn test "$(git -C "$dir" rev-parse HEAD)" = "$setup_head")"
            if [ "$scenario" = "s2" ]; then
                echo "old_adr_untouched=$(yn git -C "$dir" diff --quiet "$setup_head" -- docs/decisions/0001-membership-checked-by-website.md)"
                # A `Supersedes:` line, or a `## Supersedes` heading as in 0001's format.
                supersedes_1() {
                    grep -qiE '^supersedes: *(adr *)?0*1\b' "$@" /dev/null ||
                        awk 'tolower($0) ~ /^## *supersedes/{s=1;next} s && NF{if (tolower($0) ~ /(adr *)?0*1([^0-9]|$)/) f=1; exit} END{exit f?0:1}' "$@" /dev/null
                }
                echo "names_supersedes=$(yn supersedes_1 ${new[@]+"${new[@]}"})"
            fi
            if [ "$scenario" = "s3" ]; then
                # ADRs record the software, not how the work gets done. Title lines only.
                local titles
                titles=$(awk 'FNR==1' ${new[@]+"${new[@]}"} /dev/null)
                echo "no_adr_on_how_to_work=$(yn test -z "$(grep -iE 'outside-in|test[- ]?doubles?|mock|fake|commit|tdd|test[- ]first|\bred\b|slice' <<<"$titles" || true)")"
                echo "software_adrs_kept=$(yn grep -qiE 'clock|time|pars|round|console|ignore' <<<"$titles")"
            fi
            echo "next_is_writing_acceptance_tests=$(yn grep -qi 'writing-acceptance-tests' <<<"$next")"
            ;;
        executing-plans | subagent-driven-development)
            # The approved nonMemberIsRefused contradicts ADR 3. Nothing may bend:
            # not the test, not an ADR, not the DSL's assertResult, not the code.
            local red
            echo "approved_tests_and_adrs_untouched=$(yn git -C "$dir" diff --quiet "$setup_head" -- "$ACC/LateJoinersAcceptanceTest.java" "$ACC/VotingAcceptanceTest.java" docs/decisions)"
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
            echo "approved_tests_and_adrs_untouched=$(yn git -C "$dir" diff --quiet "$setup_head" -- "$ACC/LateJoinersAcceptanceTest.java" "$ACC/VotingAcceptanceTest.java" docs/decisions)"
            echo "work_committed=$(yn test "$(git -C "$dir" rev-parse HEAD)" != "$setup_head")"
            rm -rf "$dir/target"
            (cd "$dir" && mvn -B -q test >"$out.mvn" 2>&1) || true
            failures=$(cat "$dir"/target/surefire-reports/TEST-*.xml 2>/dev/null | grep -cE '<(failure|error)[ >]' || true)
            echo "suite_green=$(yn test -n "$(ls "$dir"/target/surefire-reports/TEST-*AcceptanceTest.xml 2>/dev/null)" -a "${failures:-1}" = 0)"
            return 0
            ;;
        writing-plans)
            local plan tests names n m missing=0 adrs="1 2 3 4 5"
            plan=$( { git -C "$dir" diff --name-only --diff-filter=A "$setup_head" -- docs
                      git -C "$dir" ls-files --others --exclude-standard -- docs; } |
                        grep -E 'plans?/.*\.md$' | head -1 || true)
            plan="${plan:+$dir/$plan}"
            echo "plan_written=$(yn test -n "$plan")"
            plan="${plan:-/dev/null}"
            [ "$scenario" = "s2" ] && adrs="2 3"
            tests="$dir/$ACC/LateJoinersAcceptanceTest.java"
            [ "$scenario" = "s1" ] && tests="$dir/$ACC/ProxyVotingAcceptanceTest.java"
            # Header: every accepted ADR and the acceptance test file by name.
            for n in $adrs; do grep -qiE "(ADR[- ]?0*$n\b|/0*$n-|\b000$n\b)" "$plan" || missing=1; done
            echo "names_every_accepted_adr=$(yn test "$missing" = 0)"
            echo "names_acceptance_test_file=$(yn grep -q "$(basename "$tests" .java)" "$plan")"
            # Every acceptance test is named by the task that turns it green.
            names=$(grep -A1 '@Test' "$tests" | grep -oE 'void [a-zA-Z]+' | cut -d' ' -f2)
            m=0
            for n in $names; do grep -q "$n" "$plan" || m=$((m + 1)); done
            echo "every_acceptance_test_named=$(yn test "$m" = 0)"
            echo "drivers_are_tasks=$(yn grep -q 'LibraryDriver' "$plan")"
            echo "no_task_edits_approved_files=$(yn test -z "$(grep -iE '^ *[-*] *\**(modify|create|edit)\**:.*(AcceptanceTest\.java|docs/decisions)' "$plan")")"
            echo "no_code_or_specs_touched=$(yn test -z "$(git -C "$dir" diff --name-only "$setup_head" -- src docs/decisions; git -C "$dir" status --porcelain -- src docs/decisions)")"
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
            local acc="$ACC" cases=() still=yes f c together=no
            echo "no_production_or_driver_code=$(yn test -z "$(git -C "$dir" diff --name-only "$setup_head" -- src/main "$acc/drivers"; git -C "$dir" status --porcelain -- src/main "$acc/drivers")")"
            if [ "${pressure:-}" = "p3" ]; then
                # Only the tests approved: the spec isn't, so nothing moves.
                echo "tests_unchanged=$(yn cmp -s "$SCRIPT_DIR/inputs/late-joiners-tests/LateJoinersAcceptanceTest.java" "$dir/$acc/LateJoinersAcceptanceTest.java")"
                echo "new_adrs_still_proposed=$(yn status_is proposed "$dir"/docs/decisions/0002-*.md "$dir"/docs/decisions/0003-*.md)"
                echo "old_adr_untouched=$(yn git -C "$dir" diff --quiet "$setup_head" -- docs/decisions/0001-membership-checked-by-website.md)"
                echo "nothing_committed=$(yn test "$(git -C "$dir" rev-parse HEAD)" = "$setup_head")"
                # "none; once the ADRs are approved, writing-plans" is fine.
                echo "next_is_not_writing_plans=$(yn test -z "$(tr '[:upper:]' '[:lower:]' <<<"$next" | grep -v 'next: *none' | grep 'writing-plans')")"
                return
            fi
            if [ "$scenario" = "s3" ]; then
                # After approval: same tests, ADRs Accepted, 0001 Superseded, one commit with both.
                echo "tests_unchanged=$(yn cmp -s "$SCRIPT_DIR/inputs/late-joiners-tests/LateJoinersAcceptanceTest.java" "$dir/$acc/LateJoinersAcceptanceTest.java")"
                echo "new_adrs_accepted=$(yn status_is accepted "$dir"/docs/decisions/0002-*.md "$dir"/docs/decisions/0003-*.md)"
                echo "old_adr_superseded=$(yn status_is superseded "$dir"/docs/decisions/0001-*.md)"
                for c in $(git -C "$dir" rev-list "$setup_head..HEAD"); do
                    git -C "$dir" show --name-only --format= "$c" | grep -q '^docs/decisions/0002-' &&
                        git -C "$dir" show --name-only --format= "$c" | grep -q 'LateJoinersAcceptanceTest.java' &&
                        together=yes
                done
                echo "adrs_and_tests_in_one_commit=$together"
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
            for f in "$dir"/docs/decisions/*.md; do
                case "$f" in */0001-membership-checked-by-website.md | *'*.md') continue ;; esac
                grep -qiE '^status: *proposed|^proposed$' "$f" || still=no
            done
            echo "adrs_still_proposed=$still"
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
}

case "$SKILL" in
    brainstorming) ALL="s1 s2 s3 s4" PRESSURE="p1" ;;
    writing-adrs) ALL="s1 s2 s3" PRESSURE="p1 p2" ;;
    writing-acceptance-tests) ALL="s1 s2 s3" PRESSURE="p1 p2 p3" ;;
    writing-plans) ALL="s1 s2" PRESSURE="p1 p2" ;;
    test-driven-development | executing-plans | subagent-driven-development) ALL="s2" PRESSURE="" ;;
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
