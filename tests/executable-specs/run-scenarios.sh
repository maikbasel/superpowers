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

USAGE="usage: run-scenarios.sh <brainstorming|writing-adrs|writing-acceptance-tests> <red|green> [runs] [s1|s2|s3|p1|p2|p3|all|pressure]"
SKILL="${1:?$USAGE}"
ARM="${2:?$USAGE}"
RUNS="${3:-1}"
WHICH="${4:-both}"
MODEL="${MODEL:-sonnet}"
BASE_REF="${BASE_REF:-0f9581f}"
OUT_DIR="${OUT_DIR:-$(mktemp -d)}"
TIMEOUT=600
ACC=src/test/java/club/voting/acceptance

mkdir -p "$OUT_DIR"
SKILL_DIR="$OUT_DIR/skill"

# Freeze the skill text under test, outside every run's project.
case "$SKILL:$ARM" in
    brainstorming:red)
        mkdir -p "$SKILL_DIR/brainstorming"
        git -C "$REPO_ROOT" archive "$BASE_REF" skills/brainstorming |
            tar -x -C "$SKILL_DIR/brainstorming" --strip-components=2
        ;;
    brainstorming:green | writing-adrs:green | writing-acceptance-tests:green)
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
    [ "$SKILL" = "writing-acceptance-tests" ] || return 0
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
            [ "$scenario" = "s1" ] && transcript=s1-proxy-voting.md || transcript=s2-late-joiners.md
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
                echo "names_supersedes=$(yn grep -qiE '^supersedes: *(adr *)?0*1\b' ${new[@]+"${new[@]}"} /dev/null)"
            fi
            echo "next_is_writing_acceptance_tests=$(yn grep -qi 'writing-acceptance-tests' <<<"$next")"
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
            --model "$MODEL" --allowed-tools "Read,Write,Edit,Glob,Grep,Bash(git:*),Bash(mvn:*)" \
            --output-format stream-json --verbose >"$out.jsonl" 2>&1) || echo "(claude exited $?)" >>"$out"
        jq -r 'select(.type=="result") | .result // empty' "$out.jsonl" >>"$out" 2>/dev/null || true
    fi
    # The last commit by the fixture author is where the agent took over.
    local setup_head
    setup_head=$(git -C "$dir" log --author=Fixture -1 --format=%H)
    check_run "$base" "$dir" "$out" "$setup_head" >"$out.checks"
}

case "$SKILL" in
    brainstorming) ALL="s1 s2" PRESSURE="p1" ;;
    writing-adrs) ALL="s1 s2" PRESSURE="p1 p2" ;;
    writing-acceptance-tests) ALL="s1 s2 s3" PRESSURE="p1 p2 p3" ;;
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
