/INPUT/ {
	input=1
	policy=$4
	print "blockdiag {" # }
	print "orientation=portrait"
	#print "INPUT"
	last="INPUT"
	counter = 0
	print "group {"
	print "orientation=portrait"
	print "shape=line; style=none"
	print "group {"
	print "orientation=portrait"
	print "shape=line; style=none"
}

/^$/ {
	input=0
}

input && /^ *[0-9]/ {
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
	print name " [label = \"" label "\"]"
	print last " -> " name
	last=name
	nodes[num_targets++] = name
	targets[name] = $3
};

END {
	print "END  [shape=none]"
	print last " -- END -> " policy
	print "}"
	for ( node in nodes ) {
		name = nodes[node]
		target = targets[name]
		if ( ! used[target] || target == policy ) {
		   print name " -> " target;
		   used[target] = 1
	   }
	   else {
		   print target " <- " name;
	   }
	   if ( target == "ACCEPT" ) {
		   print "[color=\"green\"]"
			print "ACCEPT [color = \"lightgreen\"]"
		}
	   else if ( target == "REJECT" ) {
		   print "[color=\"red\"]"
			print "REJECT [color = \"red\"]"
		}
   }
	print "}"
	if ( policy == "REJECT")
		print "REJECT [color = \"red\"]"
	if ( policy == "ACCEPT")
		print "ACCEPT [color = \"lightgreen\"]"

	print "}"
	}
