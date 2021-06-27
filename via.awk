/INPUT/ {
	input=1
	policy=$4
	print "blockdiag {" # }
	print "orientation=portrait"
	#print "INPUT"
	last="INPUT"
	counter = 0
}

/^$/ {
	input=0
}

input && /^ *[0-9]/ {
	name="Node" counter++
	label=""
	for (i=3; i<=NF; i++)
		label=label $i " "
	print name " [label = \"" label "\"]"
	print last " -> " name
	print name " -> " $3
	last=name
	targets[num_targets++] = $3
};

END {
	print last " -> " policy
	print "group {"
	for ( i = 0; i < num_targets; i++ )
	   print targets[i];
	print policy
	print "}"
	print "}"
	}
