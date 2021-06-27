BEGIN {
	print "blockdiag {" # }
	print "orientation=portrait"
	counter = 0
}

/^Chain/ {
	chainname = $2
	if ( chainname !~ chain_selector && chain_selector != "")
		next
	in_chain=1
	policy=chainname "_" $4
	print chainname " [shape = ellipse]"
	last=chainname
	print "group {" # }
	print "orientation=portrait"
	print "shape=line; style=none"
	print "group {" # }
	print "orientation=portrait"
	print "shape=line; style=none"
}

in_chain && /^$/ {
	in_chain=0
	print chainname "_END" "  [shape=none]"
	print last " -- " chainname "_END -> " policy
	# {
	print "}"
	for ( node in nodes ) {
		name = nodes[node]
		target = targets[name]
		print target " [label=" target_labels[target] "]"
		if ( target != policy )
		   print name " -- f" fakenode++ " -> " target;
		else
		   print name " -- f" fakenode++ " -> f" fakenode++ " -> " target;
	   if ( target ~ "_ACCEPT$" ) {
		   print "[color=\"green\"]"
			print chainname "_ACCEPT [color = \"lightgreen\", label=\"" target_labels[target] "\"]"
		}
	   else if ( target ~ "_REJECT$" ) {
		   print "[color=\"red\"]"
			print chainname "_REJECT [color = \"red\", label=\"" target_labels[target] "\"]"
		}
		else {
			print target " [shape=ellipse]"
		}
   }
   delete nodes
	# {
	print "}"

	if ( policy ~ "_REJECT$")
		print chainname "_REJECT [color = \"red\", label=\"REJECT\"]"
	if ( policy ~ "_ACCEPT$")
		print chainname "_ACCEPT [color = \"lightgreen\", label=\"ACCEPT\"]"

	#if( in_chain )
	#	exit
}

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
	#for (i=10; i<=NF; i++)
	#	label=label " " $i
	print name " [label = \"" label "\", shape=diamond]"
	print last " -> " name
	last=name
	nodes[num_targets++] = name
	targets[name] = chainname "_" $3
	target_labels[chainname "_" $3] = $3
}

END {
	print "class fake [shape=none, width=1]"
	for (i=0; i<=fakenode; i++)
		print "f" i "  [ class=fake]"

	# {
	print "}"
}
