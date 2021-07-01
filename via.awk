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
	if ( chainname !~ chain_selector && chain_selector != "")
		next
	in_relevant_chain=1
	if ( $3 == "(policy" )
		policy=chainname "_" $4
	else
		policy=0
	last=chainname
	print indent "group {" # } group the chain
	indent="    "
	print indent "orientation=portrait"
	print indent "shape=line; style=none"
	print indent chainname " [class=chain_head]"
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
	for (i=10; i<=NF; i++) {
		if ( $i == "/*" )
			break
		label=label " " $i
	}
	if ( label == "" )
		label = "*"
	gsub(/  /, " ", label);
	gsub(/^ *| *$/, "", label);
	print indent name " [class=rule, label=\"" label "\"]"
	print indent last, "->", name
	last=name
	filter_nodes[num_targets++] = name
	targets[name] = chainname "_" $3
	all_targets[name] = $3
	target_labels[chainname "_" $3] = $3
}

# End of chain
/^$/ {
	in_chain=0
	filter_number[chainname] = filters_in_chain
	filters_in_chain=0
	if (in_relevant_chain)
		finalize_chain()
	in_relevant_chain=0
}

function finalize_chain() {
	print indent chainname "_END" "	[shape=none]"
	if ( policy )
		print indent last " -- " chainname "_END -> " policy
	# { End filter group
	indent="    "
	print indent "}"
	for ( idx in filter_nodes ) {
		name = filter_nodes[idx]
		target = targets[name]
		target_label = target_labels[target]
		if ( target ~ "_ACCEPT$" )
			linestyle=" [class=accept_line]"
		else if ( target ~ "_REJECT|_DROP$" )
			linestyle=" [class=reject_line]"
		else if ( target ~ "_RETURN$" )
			linestyle=" [class=return_line]"
		else
			linestyle=""
		# To avoid issues of the dia rendering, a "fakenode" – a node that is
		# empty, not visible and of minimal size has to be used.
		# For connections to the policy we use an extra node, to make sure the
		# line doesn't cross any other.
		if ( target != policy )
			print indent name, "-- f" fakenode++, "->", target linestyle;
		else
			print indent name, "-- f" fakenode++, "-> f" fakenode++, "->", target linestyle;
	}
	if ( policy )
		targets[++num_targets] = policy # Policies are also targets
	# Format all targets
	for ( idx in targets ) {
		target = targets[idx]
		target_label = target_labels[target]
		if ( allready_rendered[target] )
			continue
		else
			allready_rendered[target] = 1
		if ( target ~ "_ACCEPT$" ) {
			print indent chainname "_ACCEPT [class=accept]"
		}
		else if ( target ~ "_DROP$" ) {
			print indent chainname "_DROP [class=drop]"
		}
		else if ( target ~ "_REJECT$" ) {
			print indent chainname "_REJECT [class=reject]"
		}
		else if ( target ~ "_RETURN$" ) {
			print indent chainname "_RETURN [class=return]"
		}
		else {
			print indent target " [class=target, class=" target_label ", label=\"" target_label "\"]"
		}
	}
	delete filter_nodes
	delete targets
	delete target_labels
	delete allready_rendered
	# { End group around chain
	indent="  "
	print indent "}"
}

END {
	if (in_relevant_chain)
		finalize_chain()
	print indent "class chain_head [shape=ellipse]"
	print indent "class rule [shape=diamond, width=200]"
	print indent "class target [shape=ellipse]"
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
	for ( idx in all_targets ) {
		if (filter_number[all_targets[idx]] == 0 )
			print indent "class", all_targets[idx], "[style=dotted, linecolor=\"#444\", textcolor=\"#444\"]"
		else
			print indent "class", all_targets[idx], "[linecolor=black]"
	}
	# { End blockdiag
	indent=""
	print indent "}"
}
