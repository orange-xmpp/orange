# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 The Orange authors

# Rewrap the paragraphs and list items of a Markdown file to at most
# WIDTH columns (default 80).  Headings, tables, HTML comments, block
# quotes and fenced code blocks are copied unchanged.  A single word
# longer than WIDTH stays on a line of its own.
#
# Usage: awk -f md-wrap.awk [-v width=N] FILE > OUTPUT

BEGIN {
	if (width == "")
		width = 80
	text = ""
}

# A word that would change the Markdown structure if it started a line:
# a list marker, a heading, a quote, a table row, a setext underline.
function risky(word) {
	return word ~ /^([-*+]|[0-9]+[.)])$/ || word ~ /^#+$/ ||
	    word ~ /^>/ || word ~ /^\|/ || word ~ /^(=+|-+)$/
}

function flush(    count, words, index_, line, fresh) {
	if (text == "")
		return
	count = split(text, words, " ")
	line = first
	fresh = 1
	for (index_ = 1; index_ <= count; index_++) {
		if (fresh) {
			line = line words[index_]
			fresh = 0
		} else if (length(line) + 1 + length(words[index_]) <= width ||
		    risky(words[index_])) {
			line = line " " words[index_]
		} else {
			print line
			line = rest words[index_]
		}
	}
	print line
	text = ""
}

function spaces(count,    result) {
	result = ""
	while (count-- > 0)
		result = result " "
	return result
}

/^[ \t]*(```|~~~)/ {
	flush()
	print
	in_fence = !in_fence
	next
}

in_fence {
	print
	next
}

/^[ \t]*$/ || /^#+([ \t]|$)/ || /^[ \t]*\|/ || /^[ \t]*<!--/ || /^[ \t]*>/ {
	flush()
	print
	next
}

match($0, /^[ \t]*([-*+]|[0-9]+[.)])[ \t]+(\[[ xX]\][ \t]+)?/) {
	flush()
	first = substr($0, 1, RLENGTH)
	text = substr($0, RLENGTH + 1)
	match($0, /^[ \t]*([-*+]|[0-9]+[.)])/)
	rest = spaces(RLENGTH + 1)
	next
}

{
	if (text != "") {
		text = text " " $0
	} else {
		match($0, /^[ \t]*/)
		first = rest = substr($0, 1, RLENGTH)
		text = $0
	}
}

END {
	flush()
}
