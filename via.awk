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
	if ( chainname !~ chain_selector && chain_selector != "")
		next
	in_chain=1
	policy=chainname "_" $4
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
		label=label "dst:" $9
	if ( label == "" )
		label = "*"
	print indent name " [class=rule, label=\"" label "\"]"
	print indent last, "->", name
	last=name
	filter_nodes[num_targets++] = name
	targets[name] = chainname "_" $3
	target_labels[chainname "_" $3] = $3
}

# End of chain
/^$/ {
	if (in_chain)
		finalize_chain()
	in_chain=0
}

function finalize_chain() {
	print indent chainname "_END" "	[shape=none]"
	print indent last " -- " chainname "_END -> " policy
	# { End filter group
	indent="    "
	print indent "}"
	for ( idx in filter_nodes ) {
		name = filter_nodes[idx]
		target = targets[name]
		target_label = target_labels[target]
		if ( target ~ "_ACCEPT$" )
			linestyle=" [color=\"green\"]"
		else if ( target ~ "_REJECT$" )
			linestyle=" [color=\"red\"]"
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
		else if ( target ~ "_REJECT$" ) {
			print indent chainname "_REJECT [class=reject]"
		}
		else {
			print indent target " [class=target, label=\"" target_label "\"]"
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
	if (in_chain)
		finalize_chain()
	print indent "class chain_head [shape=ellipse]"
	print indent "class rule [shape=diamond, width=200]"
	print indent "class target [shape=ellipse]"
	print indent "class reject [color = \"red\", label=\"REJECT\"]"
	print indent "class accept [color = \"lightgreen\", label=\"ACCEPT\"]"
	print indent "class fake [shape=none, width=1]"
	for (i=0; i<=fakenode; i++)
		print indent "f" i " [class=fake]"
	# { End blockdiag
	indent=""
	print indent "}"
}
