#!/usr/bin/env gawk -f

BEGIN {
    in_node = 0
    in_edge = 0
    in_graphics = 0

    print "{"
    print "  \"nodes\": ["
    node_count = 0
    link_count = 0
}
# /^\s*genepos\s*/ {
#     next
# }

# /^\s*path\s*/ {
#     next
# }

# /^\s*sequence\s*/ {
#     next
# }

/^\s*node\s*\[/ {
    if (in_graphics) {
        print "parsing error in node in graphics"
        exit 1
    }
    in_node = 1
    id = ""
    fill = ""
    next
}

/^\s*edge\s*\[/ {
    if (in_graphics) {
        print "parsing error in edge in graphics"
        exit 1
    }
    in_edge = 1
    source = ""
    target = ""
    weight = ""
    label = ""
    fill = ""
    in_path = "false"
    next
}

/^\s*graphics\s*\[/ {
    in_graphics = 1
    next
}

/^\s*steps\s*\[/ {
    in_steps = 1
    next
}

/^\s*\]/ {
    if (in_graphics) {
        in_graphics = 0
    } if (in_steps) {
        in_steps = 0
    } else if (in_node) {
        if (node_count++ > 0) print ","
        printf "    {\"id\": \"%s\"}", id
        in_node = 0
    } else if (in_edge) {
        if (link_count++ == 0) edge_json = "\n  ],\n  \"links\": ["
        else edge_json = ","
        printf "%s\n    {\"source\": \"%s\", \"target\": \"%s\", \"label\": \"%s\", \"weight\": %s, \"in_path\": %s, \"fill\": \"%s\"}", edge_json, source, target, label, (weight=="" ? 1 : weight), in_path, fill
        in_edge = 0
    }
    next
}

{
    if (in_node) {
        if ($1 == "id") id = $2
        else if (in_graphics && $1 == "fill") {
            fill = $2
            gsub("\"", "", fill)
        } 
    } else if (in_edge) {
        if (in_steps) {
            in_path = "true"
            next
        }
        if ($1 == "source") {source = $2}
        if ($1 == "target") {target = $2}
        if ($1 == "weight") {weight = $2}
        if ($1 == "label") {
            label = $0
            sub(/^[^"]*"/, "", label)
            sub(/"[^"]*$/, "", label)
        } 
        if (in_graphics && $1 == "fill") {
            fill = $2
            gsub("\"", "", fill)
        }
    }
}


END {
    printf "\n  ]"
    if (link_count == 0) {
    print ",\n  \"links\": ["
     print ""  # les liens ont déjà été imprimés
    print "  ]"
    }
    print "\n}"
}
