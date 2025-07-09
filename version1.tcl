#log_user 0   
# #########################################################
# This array variable is a list that contain the router's #
# IP address and an a shot name description...            #
# You can modify this array using:                        #
#        _MAME_  (no spaces between)                      #
#        _IP-Address_  (IPv4 Only normal dot notation)    #
#                                                         #
# The output will be sorted alphabetically by _NAME_      #
#                                                         #
# #########################################################
array set element {
	SERVER_HOST_1_        192.168.1.1
    SERVER_HOST_2_        10.1.1.1
    SERVER_HOST_3_        172.168.2.1
    SERVER_HOST_4_        10.1.1.2
	};
# #########################################################

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# The HELP procedure display a help banner and
# instructions about how to use this script...
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
proc HELP {} {
	puts "\r";
	puts "Tcl/Tk script that execute an ICMP test agaings main hubs in the field, and servers in Management Network";
	puts "\r";
	puts {INSTRUCTIONS:};
	puts {test  [/r=NUMBER] [/s=NUMBER] [/b] [/n] [/t] [/v]};
	puts "\r";
	puts {test                       Run normal test with default values.};
	puts {test  /r=XXXX              ICMP test with XXXX number of packets. Default = 5.};
	puts {                           "r" must be a value between 1 and 1000.};
	puts {test  /s=XXXX              ICMP test with XXXX datagram size. Default = 100.};
	puts {                           "s" must be a value between 36 and 1450.};
	puts {test  /b                   Display banner.};
	puts {test  /n                   NO router ID, only ICMP Test.};
	puts {test  /t                   Template with lines in output results.};
	puts {test  /v                   Interactive Display the ICMP output.  }
	puts "\r\r";
	puts {EXAMPLES:};
	puts {Router(tcl)#test };
	puts {Router(tcl)#test /b /r=200 /s=200 /t};
	puts {Router#tclsh tftp://10.21.72.35/test.tcl};
	puts "\r\r";
	
}
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# The Procedure BANNER display the logo and 
# company banner ... just for fun  :D
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
proc BANNER {} {
	puts "  _____     	";
	puts "  I C M P 	";
    puts "  T E S T 	";
	puts "  _____     	";
	puts " ";
	puts "  v1.0  lgpr@Feb-2020";

}
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# The Procedure NUMERO validate the values of the 
# parameters in the PING command...
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
proc NUMERO { var } {
	set foundposition [string first "/r" $var];
	if {$foundposition > -1} {
		set cutoff [string length $var];
		set Valor  [string range $var 3  $cutoff ];
		# Setting the max and min ping repetitions
		if {$Valor > 1000} {
			set Valor 1000;
			}
		if {$Valor < 1} {
			set Valor 1;
			}
		}
	set foundposition [string first "/s" $var];
	if {$foundposition > -1} {
		set cutoff [string length $var];
		set Valor  [string range $var 3  $cutoff ];
		# Setting the max and min ping datagram size
		if {$Valor > 1450} {
			set Valor 1450;
			}
		if {$Valor < 36} {
			set Valor 36;
			}
		}
	return $Valor
}

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Initialization of default values of PING
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
set PingSize 100;
set PingQuantity 5;
set IdentifyRouter 2;
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Initialization of program control variables
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
set VIEWOUTPUT 0;     # If you want to view the PING progress = 1, Default = 0;
set PUTTEMPLATES 0;   # If you want to put lines separators = 1, Default =0;
set HELPBANNER 1;     # Control execution for input argument errors and help, and display banner.
set SNR 100;          # Control execution in routers this code was not intended for.


# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Procedure that get de string values of the command execution in the Router
# IOS Console
#
#
# input arg1, arg2 <--  IOS Command, Text string that equal the necesary data.
# return --> string with the value
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
proc GetIOSValue {commando cadena} {
	set foundposition [string first $cadena $commando];
	set cutoff [string length $cadena];
	set begin [expr $foundposition + $cutoff];
	set end [string first "\r" $commando $begin];
	set Valor [string range $commando $begin $end];

    return  $Valor
};

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Just a visual candy to present/display the results.
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
proc DIVISIONLINE { LINEA } {
	if { $LINEA > 0} {
		puts "_________________________________________________\r\r";
	}
}


# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# The next loop validates the arguments in the program initial run.
# If there is an invalid argument, the script will stop and display the help.
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
foreach arg $::argv {
	set option [string range $arg 0 1 ]
	set option [string tolower $option]
	switch $option {
		"/h" {
			HELP
			set HELPBANNER 0;
		}
		"/?" {
			HELP
			set HELPBANNER 0;
		}
		"/r" {
			set PingQuantity [ NUMERO $arg ]
		}
		"/s" {
			set PingSize [ NUMERO $arg ]
		}
		"/b" {
			BANNER
		}
		"/n" {
			set IdentifyRouter 0;
		}
		"/t" {
			set PUTTEMPLATES 2;
		}
		"/v" {
			set VIEWOUTPUT 2;
		}
		default {
			HELP;
			set HELPBANNER 0;
		}
	}
} 
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#                      ____ main body routine _____
puts " ";

# What if the router model in where this script are excuted?
# To assembly the right CLI IOS instructions depending of the model and
# retrieve the correct data from the outputs.
set RouterModel [exec "show inventory"];
set foundposition [string first "C111" $RouterModel]; #for Cisco C1111 LTE Model
if {$foundposition > 0} {
	set CellPort " 0/2/0 "
	set SNR "ECIO"
	set SIMs "Active SIM"
};
set foundposition [string first "C819" $RouterModel]; #For Cisco c819 3G/4G model
if {$foundposition > 0} {
	set CellPort " 0 "
	set SNR "SNR"
	set SIMs "Active SIM"
};
set foundposition [string first "CISCO1921" $RouterModel]; #For Cisco 1921 3G/4G/LTE model
if {$foundposition > 0} {
	set CellPort " 0/0/0 "
	set SNR "SNR"
	set SIMs "SIM Status"
};

# ###################################################################
# The next code is to avoid the execution of this program in a router
# different from the BNS Dominican Republic country without Cellular
# data capability..
if { $SNR == 100 } {
	puts "\r\r ";
	puts "#########################################################";
	puts "#                                                       #";
	puts "# THIS TCL/TK SCRIPT WAS NOT MADE FOR THIS ROUTER MODEL #";
	puts "#                                                       #";
	puts "#########################################################";
	puts "\r\r ";
	set HELPBANNER 0;
	exit;
	}
# ##########################################################




if {$HELPBANNER > 0} { 
	if {$IdentifyRouter > 0} {
		set command "show cellular $CellPort all | include "
		set RSSIValue    [exec "$command RSSI"];
		set SNRValue     [exec "$command $SNR"];
		set SIMStatus    [exec "$command $SIMs"];
		set IMEINumber   [exec "$command IMEI"];
		set SerialNumber [exec "show ver | include Processor"];
		DIVISIONLINE $PUTTEMPLATES;
		set a [GetIOSValue $SerialNumber "ID "];
		puts "ROUTER SERIAL NUMBER = $a";
		set a [GetIOSValue $IMEINumber " = "];
		puts "MODEM IMEI ID NUMBER = $a";
		set a [GetIOSValue $SIMStatus "= "];
		puts "SIM CARD PRESENCE    = $a";
		DIVISIONLINE $PUTTEMPLATES;
		set a [GetIOSValue $RSSIValue "= "];
		puts "Received Signal Strength (RSSI)= $a"
		set a [GetIOSValue $SNRValue "= "]
		puts "Signal to Noise Ratio    (SNR) = $a"
		DIVISIONLINE $PUTTEMPLATES;
	}	
	puts "\r ICMP test....\r";
	foreach i [array names element] {
		puts "\r\r ICMP Trying $i :\r"
		
		if { $VIEWOUTPUT > 1} {
			ping $element($i) repeat $PingQuantity size $PingSize
			}
		if { $VIEWOUTPUT < 1} {
			set PingElement [exec "ping $element($i) repeat $PingQuantity size $PingSize "];
			set foundposition [string first "Success" $PingElement];
			set cutoff [string length "Success rate is "];
			set begin [expr $foundposition + $cutoff];
			set end [string first " " $PingElement $begin];
			set PingResult [string range $PingElement $begin $end];

			set foundposition [string first "round-trip" $PingElement];
			set cutoff [string length "round-trip "];
			set begin [expr $foundposition + $cutoff];
			set end [string first "ms" $PingElement $begin];
			set end [expr $end + 1 ]
			set roundtrip [string range $PingElement $begin $end];

			switch $PingResult {
				"0 " {
				puts -nonewline "The $i is !NOT REACHEABLE! = $PingResult% $roundtrip\r";
				}
				"100 " {
				puts -nonewline "The $i is Reachable = $PingResult% $roundtrip\r";
				}
				default {
				puts -nonewline "The $i is reachable with packet lost = $PingResult% $roundtrip\r";
				}
			}
		}
}
puts " ";
DIVISIONLINE $PUTTEMPLATES;
puts " ";
}



