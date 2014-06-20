# First thing to do is look up the FQDN - everything follows from there
# So we'll use a DNS resolver object
use Net::DNS;
my $res = Net::DNS::Resolver->new;
# Perform the lookup
my $query = $res->query($ARGV[0]);

#determine the type of answer received, CNAME, A record
#and count how many of each
my $cname_counter = 0;
my $arecord_counter = 0;
foreach my $answer ($query->answer) {
	if ($answer->type eq 'CNAME') {
		$cname_counter++;
	} elsif ($answer->type eq 'A'){
		$arecord_counter++;
	}
}

#General Info about the FQDN
print "This FQDN has ", $cname_counter, " CNAME Record(s) and ", $arecord_counter, " A record(s).\n\n";

#use the counters, if there are no CNAME records, then the Domain is an A record 
#rotor, just need to look up the IPs and see where they live and skip all the CNAME checking

# if there are CNAME records, look through them and see if they match
# either Firstpoint or Foundry GSLB patterns and identify accordingly

	print '##################### CNAME Information #####################';
if ($cname_counter = 0) {
	#if there are no CNAME records, no sleuthing needed on the DNS
	print "No CNAME records Found, so probably not GSLB, moving on.\n\n";
} else {
	#If there are CNAME records, check each and print out appropriate info
	print "\n\n";
	foreach my $cname_answer ($query->answer) {
		#first get the type, if it's a CNAME, process it, otherwise ignore
		if ($cname_answer->type eq 'CNAME'){
			#first look for foundry GSLB pattern
			#www.aol.com --> www.gwww.aol.com etc.
			if ($cname_answer->cname =~ /(.?)\.g$1/) {
				print $cname_answer->cname, " - Looks like a Foundry GSLB address\n";
				#TODO - add a call/link to the foundry GSLB search 
			} elsif ($cname_answer->cname =~ /\.akadns\.net$/){
				print $cname_answer->cname, " - Looks like an Akamai Firstpoint GSLB Address\n";
				#TODO - add a call/link to Akamai FP config
			} else {
				print $cname_answer->cname, " - No obvious GSLB match\n";
			}
		}
	}
	print "\n";
}
#Next Up is A record processing


print '##################### A Record Information #####################';
if ($arecord_counter = 0) {
	#if there are no A records, then nothing to process 
	print "No A records Found, so nothing to do for this query.\n\n";
} else {
	#If there are A records, check each and print out appropriate info
	print "\n\n";
	foreach my $arecord_answer ($query->answer) {
		#first get the type, if it's a CNAME, process it, otherwise ignore
		if ($arecord_answer->type eq 'A'){
			# first look for Netscaler VIP signature
			# rather than trying to pattern match on the reverse lookup
			# just query EDC and find out if it's a Netscaler VIP or not
			# if it is, grab the site name and return the appropriate NSS URL
			# 
			$arecord_answer->address
			if ($arecord_answer->address =~ /(.?)\.g$1/) {
				print $arecord_answer->cname, " - Looks like a Foundry GSLB address\n";
				#TODO - add a call/link to the foundry GSLB search 
			} elsif ($arecord_answer->cname =~ /\.akadns\.net$/){
				print $arecord_answer->cname, " - Looks like an Akamai Firstpoint GSLB Address\n";
				#TODO - add a call/link to Akamai FP config
			} else {
				print $arecord_answer->cname, " - No obvious GSLB match\n";
			}
		}
	}
	print "\n";
}
