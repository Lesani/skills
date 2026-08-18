#!/usr/bin/env bash
# ste-lint.sh - mechanical STE (Simplified Technical English) checks for markdown prose.
# General-purpose: run it on any prose artifact (docs, READMEs, PR text, skills, reports).
#
# Usage:
#   scripts/ste-lint.sh file.md [file2.md ...]
#
# Checks (ERROR -> exit 1):
#   contractions        don't, it's, they're, ...
#   semicolons          in prose (code blocks and inline code are skipped)
#   british-spelling    behaviour, colour, optimise, ...
#   banned-words        utilize, prior to, in order to, marketing adjectives
# Checks (WARN -> reported, exit unaffected):
#   passive-marker      is being, has been, is <verb>ed by, ...
#   long-sentence       sentence over 25 words
#
# Suppression: add <!-- ste-ignore --> to a line to skip it (judgment beats the rule).
# The script fixes FORM only. It cannot judge the right technical noun or a kept slogan.

set -u

if [ "$#" -eq 0 ]; then
    echo "usage: $(basename "$0") file.md [file2.md ...]" >&2
    exit 2
fi
files=("$@")

errors=0
warnings=0

for f in "${files[@]}"; do
    [ -f "$f" ] || { echo "ste-lint: no such file: $f" >&2; errors=$((errors+1)); continue; }

    result="$(awk '
    BEGIN {
        IGNORECASE = 1
        in_fence = 0
        para = ""; para_start = 0
        err = 0; warn = 0
    }

    function report(sev, cat, lineno, text) {
        gsub(/^[ \t]+|[ \t]+$/, "", text)
        if (length(text) > 100) text = substr(text, 1, 97) "..."
        printf "%s:%d: [%s] %s: %s\n", FILENAME, lineno, sev, cat, text
        if (sev == "ERROR") err++; else warn++
    }

    # flush accumulated paragraph: sentence-length check (prose wraps across lines)
    function flush_para(    tmp, n, i, words) {
        if (para == "") { para_start = 0; return }
        tmp = para
        # protect common abbreviations from being treated as sentence ends
        gsub(/e\.g\./, "eg", tmp); gsub(/i\.e\./, "ie", tmp)
        gsub(/vs\./, "vs", tmp);   gsub(/etc\./, "etc", tmp)
        n = split(tmp, sentences, /[.!?]+/)
        for (i = 1; i <= n; i++) {
            words = split(sentences[i], _w, /[ \t]+/)
            if (words > 25)
                report("WARN", "long-sentence", para_start, sentences[i] " (" words " words)")
        }
        para = ""; para_start = 0
    }

    {
        line = $0

        # toggle fenced code blocks
        if (line ~ /^[ \t]*(```|~~~)/) { in_fence = !in_fence; flush_para(); next }
        if (in_fence) next

        # explicit suppression
        if (line ~ /<!-- *ste-ignore *-->/) next

        # strip inline code spans and link targets before matching
        gsub(/`[^`]*`/, "", line)
        gsub(/\]\([^)]*\)/, "]", line)

        # blank line or structural line ends the running paragraph
        if (line ~ /^[ \t]*$/ || line ~ /^#/ || line ~ /^[ \t]*[-*]|^[ \t]*[0-9]+\./ || line ~ /^\|/ || line ~ /^---/) {
            flush_para()
        }

        # accumulate prose (skip pure table/heading separators for the word count too)
        if (line !~ /^[ \t]*$/) {
            if (para == "") para_start = NR
            para = para " " line
        }

        # --- ERROR checks ---
        if (line ~ /[a-z]n'\''t\>/)
            report("ERROR", "contraction", NR, $0)
        if (line ~ /\<(it|what|that|there|here|who|how|let|she|he|one)'\''s\>/)
            report("ERROR", "contraction", NR, $0)
        if (line ~ /\<(you|we|they)'\''(re|ve|ll|d)\>|\<I'\''(m|ve|ll|d)\>|\<(he|she|it|who|that|there|what)'\''(ll|d)\>/)
            report("ERROR", "contraction", NR, $0)
        if (line ~ /;/ && line !~ /&[a-z]+;/)
            report("ERROR", "semicolon", NR, $0)
        if (line ~ /\<(behaviour|colour|favour|flavour|organis(e|ed|es|ing|ation)|optimis(e|ed|es|ing)|maximis(e|ed|es|ing)|minimis(e|ed|es|ing)|analyse|licence|centre|artefact)\>/)
            report("ERROR", "british-spelling", NR, $0)
        if (line ~ /\<(utili[sz]e|prior to|subsequent to|in order to|facilitate)\>/)
            report("ERROR", "banned-word", NR, $0)
        if (line ~ /\<(seamless|robust|powerful|cutting-edge|effortless|world-class|next-generation|revolutionary)\>/)
            report("ERROR", "marketing-word", NR, $0)

        # --- WARN checks ---
        if (line ~ /\<(is|are|was|were) being\>|\<(has|have|had) been\>|\<(is|are|was|were) [a-z]+ed by\>/)
            report("WARN", "passive-marker", NR, $0)
    }

    END {
        flush_para()
        printf "__COUNTS__ %d %d\n", err, warn
    }
    ' "$f")"

    counts="$(printf '%s\n' "$result" | grep '^__COUNTS__')"
    printf '%s\n' "$result" | grep -v '^__COUNTS__' || true
    errors=$((errors + $(echo "$counts" | awk '{print $2}')))
    warnings=$((warnings + $(echo "$counts" | awk '{print $3}')))
done

echo "----"
echo "ste-lint: $errors error(s), $warnings warning(s) in ${#files[@]} file(s)"
[ "$errors" -eq 0 ]
