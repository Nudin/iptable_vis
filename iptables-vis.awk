#!/usr/bin/awk -f
#
BEGIN {
	print indent "blockdiag {" # }
	indent="  "
	print indent "orientation=portrait"
	counter = 0
}

# Begin of a chain
/^Chain/ {
	chainname = $2
	in_chain=1
	is_a_chain[chainname] = 1
	if ( chainname !~ chain_selector && chain_selector != "")
		next
	in_relevant_chain=1
	if ( $3 == "(policy" )
		policy=$4
	else
		policy=0
	last=chainname
	print indent "group {" # } group the chain
	indent="    "
	print indent "orientation=portrait"
	print indent "shape=line; style=none"
	print indent "group {" # } group the filter rules
	indent="      "
	print indent "orientation=portrait"
	print indent "shape=line; style=none"
}

# Filter in chain
in_chain && /^ *[0-9]/ {
	filters_in_chain++
	if ( !in_relevant_chain )
		next
	name="Node" counter++
	reject_with=""
	label=""
	if ( $4 != "all" )
		label=label $4 " "
	if ( $5 != "--" )
		label=label $5 " "
	if ( $6 != "any" )
		label=label "in:" $6 " "
	if ( $7 != "any" )
		label=label "out:" $7 " "
	if ( $8 != "anywhere" )
		label=label "src:" $8 " "
	if ( $9 != "anywhere" )
		label=label "dst:" $9 " "
	comment=0
	for (i=10; i<=NF; i++) {
		if ( $i == "/*" )
			comment=1
		else if ( $i == "*/" )
			comment=0
		else if ( $i == "reject-with" ) {
			i++
			reject_with = $i
			i++
		}
		else if ( ! comment )
			label=label " " $i
	}
	if ( label == "" )
		label = "*"
	gsub(/  /, " ", label);
	gsub(/^ *| *$/, "", label);
	gsub(/'/, "\\'", label);
	print indent name " [class=rule, label='" label "']"
	print indent last, "->", name
	last=name
	filter_nodes[num_targets++] = name
	target_node_name = chainname "_" $3
	if ( reject_with )
		target_node_name = target_node_name "_" reject_with
	target_label = $3
	if ( reject_with )
		target_label = target_label "\\n" reject_with

	targets[name] = $3
	all_targets[name] = $3
	target_node_names[name] = target_node_name
	target_labels[target_node_name] = target_label
}

# End of chain
/^$/ {
	in_chain=0
	filter_number[chainname] = filters_in_chain
	if (in_relevant_chain)
		finalize_chain()
	filters_in_chain=0
	in_relevant_chain=0
}

function finalize_chain() {
	if ( filters_in_chain || include_empty_chains ) {
		if ( chainname ~ "^(INPUT|OUTPUT|FORWARD|PREROUTING|POSTROUTING)$" )
			print indent chainname " [class=chain_head, shape=box]"
		else
			print indent chainname " [class=chain_head]"
	}
	if ( policy ) {
		print indent last " -- " chainname "_END -> " chainname "_" policy
		print indent chainname "_END" "	[shape=none]"
	}
	# { End filter group
	indent="    "
	print indent "}"

	# Draw all connections to targets
	for ( idx in filter_nodes ) {
		name = filter_nodes[idx]
		target = targets[name]
		target_node_name = target_node_names[name]
		target_label = target_labels[target_node_name]
		if ( target ~ "^ACCEPT$" )
			linestyle=" [class=accept_line]"
		else if ( target ~ "^REJECT($|_)|DROP$" )
			linestyle=" [class=reject_line]"
		else if ( target ~ "^RETURN$" )
			linestyle=" [class=return_line]"
		else
			linestyle=""
		# To avoid issues of the dia rendering, a "fakenode" – a node that is
		# empty, not visible and of minimal size has to be used.
		# For connections to the policy we use an extra node, to make sure the
		# line doesn't cross any other.
		if ( target != policy )
			print indent name, "-- f" fakenode++, "->", target_node_name linestyle;
		else
			print indent name, "-- f" fakenode++, "-> f" fakenode++, "->", target_node_name linestyle;
	}

	# Format all target nodes
	if ( policy ) {
		targets[++num_targets] = policy # Policies are also targets
		target_node_names[num_targets] = chainname "_" policy # Policies are also targets
		}
	for ( name in target_node_names ) {
		target = targets[name]
		target_node_name = target_node_names[name]
		target_label = target_labels[target_node_name]
		target_label_esc = gensub(/'/, "\\'", "g", target_label)
		if ( allready_rendered[target_node_name] )
			continue
		else
			allready_rendered[target_node_name] = 1
		if ( target ~ "^ACCEPT$" ) {
			print indent chainname "_ACCEPT [class=accept]"
		}
		else if ( target ~ "^DROP$" ) {
			print indent chainname "_DROP [class=drop]"
		}
		else if ( target ~ "^REJECT($|_)" ) {
			print indent target_node_name " [class=reject, label='" target_label_esc"']"
		}
		else if ( target ~ "^RETURN$" ) {
			print indent chainname "_RETURN [class=return]"
		}
		else {
			print indent target_node_name " [class=target, class='" target_label_esc"', label='" target_label_esc "']"
		}
	}
	delete filter_nodes
	delete targets
	delete target_node_names
	delete target_labels
	delete allready_rendered
	# { End group around chain
	indent="  "
	print indent "}"
}

END {
	filter_number[chainname] = filters_in_chain
	if (in_relevant_chain)
		finalize_chain()
	print indent "class chain_head [shape=ellipse]"
	print indent "class rule [shape=diamond, width=200]"
	print indent "class target [width=150]"
	print indent "class reject [color = \"red\", label=\"REJECT\"]"
	print indent "class reject_line [color = \"red\"]"
	print indent "class drop [color = \"red\", label=\"DROP\"]"
	print indent "class return [color = \"#1ab3ff\", label=\"RETURN\"]"
	print indent "class return_line [color = \"blue\"]"
	print indent "class accept [color = \"lightgreen\", label=\"ACCEPT\"]"
	print indent "class accept_line [color = \"green\"]"
	print indent "class fake [shape=none, width=1]"
	for (i=0; i<=fakenode; i++)
		print indent "f" i " [class=fake]"
	# Style the targets depending on their type and content
	for ( idx in all_targets ) {
		target=all_targets[idx]
		if ( ! is_a_chain[target] )
			style="shape=box"
		else if (filter_number[all_targets[idx]] == 0 )
			style="shape=ellipse, style=dotted, linecolor=\"#444\", textcolor=\"#444\""
		else
			style="shape=ellipse, linecolor=black"
		print indent "class", all_targets[idx], "["style"]"
	}
	# { End blockdiag
	indent=""
	print indent "}"
}
