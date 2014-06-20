#!/usr/bin/perl
$htmlheader = '<html><head><title>Results</title></head><body><center><table border="2" cellspacing="1" cellpadding="1"><caption>Results</caption><tr><td align="center">Original Query</td><td align="center">Reverse Lookup</td><td align="center">IP Address</td><td align="center">AS Number</td><td align="center">AS Range</td><td align="center">AS Owner</td></tr>';
$htmlfooter = '</table></center></body></html>';
if($ARGV[0] eq "-f"){ 			#check for a file input of IP's on each line
    use Getopt::Std;
    getopts("f:");
    
    open (IPFILE, $opt_f) || die("Can't find the file: $!");
    @filearray = <IPFILE>;  		#read file into array, line by line
    close IPFILE;
    
    print $htmlheader; 			#print the necessary table code
    foreach(@filearray){		#print out the results for each line of the file
        chomp; 				#need to get rid of the annoying newline character
	$_ =~ s/\s+//g; 		#get rid of any spaces too
        &getASN($_,$_);                 #call the subroutine at the bottom - in this case the original query is the same as the IP
    }
    print $htmlfooter; 			#close out the html properly

}elsif($ARGV[0] eq "-u"){		#Next Option - check for a URL
    use Getopt::Std;
    getopts("u:");
    
    #we just need to get the ip address belonging to the URL - after stripping off http: etc. if necessary
    #after that it's pretty much the same

    @URLArray = split /\/+/, $opt_u;  	#split the URL into constituent parts using /

    if ($URLArray[0] eq 'http:'){	#check for a full URL as opposed to a host name
	$URL = $URLArray[1]; 		#the relevant part of the URL should be the 2nd element since it was entered as a full URL
        $orig = $URL;                   #for printing the Query field in the subroutine later
    } else {
	$URL = $URLArray[0]; 		#otherwise we should be dealing with just a hostname
        $orig = $URL;                   #for printing the Query field in the subroutine later
    }
    use Socket; 			#need to look up the hostname and, if multiple results feed into an array that will be iterated through

    @addresses = gethostbyname($URL)   or die "Can't resolve $URL: $!\n";
    @addresses = map { inet_ntoa($_) } @addresses[4 .. $#addresses];
    
    print $htmlheader; 			#print the necessary table code
    foreach(@addresses){
        &getASN($_,$orig);			#call the ASN Subroutine at the bottom
    }
    print $htmlfooter; 			#close out the html properly

}elsif($ARGV[0] eq "-w"){		#Next Option - a file of URL's/hostnames
    use Getopt::Std;
    getopts("w:");
    
    open (URLFILE, $opt_w) || die("Can't find the file: $!");
    @URLS = <URLFILE>;
    close URLFILE;

    print $htmlheader; 			#print the necessary table code
    foreach(@URLS){			#print out the results for each line of the file
        chomp;
        @stripurl = split /\/+/, $_;  	#split the URL into constituent parts using /

	    if ($stripurl[0] eq 'http:'){
		$hostname = $stripurl[1]; #the relevant part of the URL should be the 2nd element since it was entered as a full URL
	        $orig = $hostname;        #for printing the Query field in the subroutine later
    	    } else {
		$hostname = $stripurl[0]; #otherwise we should be dealing with just a hostname
    	    	$orig = $hostname;        #for printing the Query field in the subroutine later

	    }	
    
        use Socket; 			#need to look up the hostname and, if multiple results feed into an array that will be iterated through
	$hostname =~ s/\s+//g; 		#DOS formatting can cause problems if you don't do this
        @addresses = gethostbyname($hostname)   or die "Can't resolve $hostname: $!\n";
        @addresses = map { inet_ntoa($_) } @addresses[4 .. $#addresses];
    
        foreach(@addresses){
	    &getASN($_,$orig);
        }
    }
    print $htmlfooter; 			#close out the html properly

}elsif($ARGV[0] eq "-h"){		#Next Option - just home help instructions
    #print out some basic instructions for using the thing
    print "\nThis program takes an IP address or URL from the command line and ouputs the IP and AS Number\nin CSV format.  It will also accept files with IP's or URLs on each line and output in the same format.\n\nURL's may return more than one result since some web servers have multiple IP's returned.\n\nPlease Note that the program assumes fully qualified URL's - error checking isn't great so it is not very forgiving.\nIn other words it is assumed you know what you are doing :)\n"; 
    print "\nUsage:\n\n -f \<file\>  -  reads in IP addresses from a file\n"; 
    print " -w \<file\>  -  reads in URL's from a file\n"; 
    print " -u \<URL\>  -  reads in a URL from the command line\n";
    print " -h - displays this help message\n\n";

} else { 				#default option - we assume a proper IP
    
    print $htmlheader; 			#print the necessary table code
    $IPAddy = $ARGV[0]; 		#read in the IP
    &getASN($IPAddy,$IPAddy);		#again, the original query is the same as the IP
    print $htmlfooter; 			#close out the html properly
}

#############################################-----AS Number Subroutine-----#######################################################

sub getASN {
    $IPAddress = $_[0];
    $original = $_[1];
    $hostname = gethostbyaddr(inet_aton($IPAddress), AF_INET); 	#get the hostname for printing out

    @IPArray = split /\./, $IPAddress; 				#put the IP addy into an array
    foreach(reverse(@IPArray)){ 				#reverse the order of the array and iterate through
        $reverseip = $reverseip.$_."\."; 			#put the reversed array into a string
    }
    $reverseip = $reverseip.'asn.routeviews.org'; 		#add on the necessary domain

####################DNS Code##########################
                                                                                                                                                             
    use Net::DNS;
                                                                                                                                                             
    $res = Net::DNS::Resolver->new;             #initialise the resolver object
    $packet = $res->send($reverseip, 'TXT');    #sends the required TXT type query and returns an object of type DNS::Packet
    @answer = $packet->answer;                  #returns an array of DNS::RR objects
    $rr = $answer[0];                           #first response is the one we need
    $info = $rr->rdatastr;                      #extracts the necessary information from the response - gives AS Number, Range, CIDR

#####################################################
                                                                                                                                                             
    $info =~ s/\"//g;                           #get rid of the quotes
    @asinfo = split /\s+/, $info;               #so asinfo[0] = AS Number, asinfo[1] and asinfo[2] give us the AS Range
                                                                                                                                                             
    $ASN = $asinfo[0];                          #the ASN is in the first element of the array

    $range = $asinfo[1].' /'.$asinfo[2];   	#the AS Range is a combination of the 2nd and 3rd elements 

    $AS4query = "AS".$ASN;
    $owner = `whois $AS4query | grep as-name`;	#heresy calling grep external but who cares :)

    if ($owner){				#make sure the $owner variable is populated - some whois entries don't have as-name
    	$owner =~ s/\s+//g;	 		#remove the blanks
    	@owner = split /\:/ , $owner;		#separate the as-name:XXXX parts 
	$owner = @owner[1];			#essentially truncate it for printing
	if ($owner =~ m/UNSPECIFIED/i){		#some give unspcified in the field - annoying
		@descr = `whois $AS4query | grep descr`;#try the descr: parts instead
		$owner = $descr[0];			#we'll just give the first one - may be lucky
		$owner =~ s/\s+//g;			#remove any spaces
    		@owner = split /\:/ , $owner;		#separate the as-name:XXXX parts 
		$owner = @owner[1];			#essentially truncate it for printing
	}
    } else {
	@descr = `whois $AS4query | grep descr`;#try the descr: parts instead
	$owner = $descr[0];			#we'll just give the first one - may be lucky
	$owner =~ s/\s+//g;			#remove any spaces
    	@owner = split /\:/ , $owner;		#separate the as-name:XXXX parts 
	$owner = @owner[1];			#essentially truncate it for printing
    }
    $htmlstart = '<tr><td align="center">';	#split up the HTML code - bit easier to read this way
    $htmlmiddle = '</td><td align="center">';
    $htmlend = '</td></tr>';

    $reverseip = "";                            #have to flush this or Perl gets a bit confused after a few iterations

    if ($ASN eq "4294967295"){    			#some logic to handle errored results - eg for 127.0.0.1
    	print $htmlstart.$original.$htmlmiddle.'None'.$htmlmiddle.$IPAddress.$htmlmiddle.'Error'.$htmlmiddle.'Please try a non-private or'.$htmlmiddle.'more specific IP address'.$htmlend;
    } else {
    	print $htmlstart.$original.$htmlmiddle.$hostname.$htmlmiddle.$IPAddress.$htmlmiddle.$ASN.$htmlmiddle.$range.$htmlmiddle.$owner.$htmlend;
    }	
}
