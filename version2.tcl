#!/usr/bin/env tclsh
# Enhanced ICMP Test Script for Cisco Routers with Cellular Capabilities
# Version: 2.0
# Author: Enhanced version based on lgpr@Feb-2020 original

# =========================================================
# Configuration Section - Modify as needed
# =========================================================
array set element {
    MGMT_SERVER_PRIMARY      192.168.1.1
    MGMT_SERVER_BACKUP       10.1.1.1
    MONITORING_SERVER        172.168.2.1
    DNS_SERVER              10.1.1.2
}

# Router model configurations
array set router_config {
    C111,port       "0/2/0"
    C111,metric     "ECIO"
    C111,sim        "Active SIM"
    
    C819,port       "0"
    C819,metric     "SNR"
    C819,sim        "Active SIM"
    
    CISCO1921,port  "0/0/0"
    CISCO1921,metric "SNR"
    CISCO1921,sim    "SIM Status"
}

# Default configuration values
namespace eval config {
    variable ping_size 100
    variable ping_count 5
    variable show_router_info 1
    variable show_output 0
    variable show_templates 0
    variable max_ping_count 1000
    variable min_ping_count 1
    variable max_ping_size 1450
    variable min_ping_size 36
}

# =========================================================
# Utility Procedures
# =========================================================

proc display_help {} {
    puts "\nEnhanced ICMP Test Script for Cisco Routers"
    puts "=========================================="
    puts "\nUSAGE:"
    puts "  test \[options\]"
    puts "\nOPTIONS:"
    puts "  /h, /?              Display this help message"
    puts "  /r=<number>         Number of ping packets (1-1000, default: 5)"
    puts "  /s=<size>           Ping packet size in bytes (36-1450, default: 100)"
    puts "  /b                  Display banner"
    puts "  /n                  Skip router identification output"
    puts "  /t                  Add visual separators in output"
    puts "  /v                  Show verbose ping output"
    puts "  /l                  List configured hosts"
    puts "\nEXAMPLES:"
    puts "  Router(tcl)#test"
    puts "  Router(tcl)#test /r=10 /s=500 /t"
    puts "  Router#tclsh tftp://10.21.72.35/test.tcl /v"
    puts ""
}

proc display_banner {} {
    puts "\n╔═══════════════════════╗"
    puts "║    ICMP TEST TOOL     ║"
    puts "║    Version 2.0        ║"
    puts "╚═══════════════════════╝\n"
}

proc list_hosts {} {
    global element
    puts "\nConfigured Test Hosts:"
    puts "====================="
    foreach {name ip} [array get element] {
        puts [format "  %-20s : %s" $name $ip]
    }
    puts ""
}

proc validate_parameter {arg} {
    if {[regexp {^/r=(\d+)$} $arg match value]} {
        return [constrain_value $value $::config::min_ping_count $::config::max_ping_count]
    } elseif {[regexp {^/s=(\d+)$} $arg match value]} {
        return [constrain_value $value $::config::min_ping_size $::config::max_ping_size]
    }
    return 0
}

proc constrain_value {value min max} {
    if {$value < $min} {return $min}
    if {$value > $max} {return $max}
    return $value
}

proc extract_ios_value {output search_string} {
    set pos [string first $search_string $output]
    if {$pos == -1} {return "N/A"}
    
    set start [expr {$pos + [string length $search_string]}]
    set end [string first "\r" $output $start]
    if {$end == -1} {set end [string length $output]}
    
    return [string trim [string range $output $start [expr {$end - 1}]]]
}

proc print_separator {} {
    global config::show_templates
    if {$config::show_templates} {
        puts "─────────────────────────────────────────────────"
    }
}

proc detect_router_model {} {
    global router_config
    
    set inventory [exec "show inventory"]
    
    foreach model {C111 C819 CISCO1921} {
        if {[string match "*${model}*" $inventory]} {
            return $model
        }
    }
    return ""
}

proc get_cellular_info {model} {
    global router_config
    
    if {![info exists router_config($model,port)]} {
        return [dict create error "Unsupported model"]
    }
    
    set port $router_config($model,port)
    set metric $router_config($model,metric)
    set sim_cmd $router_config($model,sim)
    
    # Gather cellular information
    set info [dict create]
    
    catch {
        set cmd "show cellular $port all | include"
        dict set info rssi [extract_ios_value [exec "$cmd RSSI"] "= "]
        dict set info snr [extract_ios_value [exec "$cmd $metric"] "= "]
        dict set info sim [extract_ios_value [exec "$cmd $sim_cmd"] "= "]
        dict set info imei [extract_ios_value [exec "$cmd IMEI"] "= "]
    }
    
    catch {
        set serial_output [exec "show ver | include Processor"]
        dict set info serial [extract_ios_value $serial_output "ID "]
    }
    
    return $info
}

proc perform_ping {host ip repeat size verbose} {
    if {$verbose} {
        puts "\nPinging $host ($ip):"
        ping $ip repeat $repeat size $size
        return
    }
    
    # Silent mode - capture and parse output
    set result [exec "ping $ip repeat $repeat size $size"]
    
    # Extract success rate
    regexp {Success rate is (\d+) percent} $result match success_rate
    
    # Extract round-trip times
    set rtt "N/A"
    regexp {round-trip.*= ([\d/]+) ms} $result match rtt
    
    # Format output based on success rate
    set status_msg ""
    switch -- $success_rate {
        0 {
            set status_msg "UNREACHABLE"
            set color_code "\033\[31m"  ;# Red
        }
        100 {
            set status_msg "OK"
            set color_code "\033\[32m"  ;# Green
        }
        default {
            set status_msg "PARTIAL"
            set color_code "\033\[33m"  ;# Yellow
        }
    }
    
    puts [format "  %-20s : %-12s (Success: %3d%%, RTT: %s)" \
        $host $status_msg $success_rate $rtt]
}

# =========================================================
# Main Execution
# =========================================================

proc main {argv} {
    global element config::ping_size config::ping_count 
    global config::show_router_info config::show_output config::show_templates
    
    set show_help 0
    set show_banner 0
    set list_only 0
    
    # Parse command line arguments
    foreach arg $argv {
        set opt [string tolower [string range $arg 0 1]]
        switch -- $opt {
            "/h" - "/?" {
                display_help
                return
            }
            "/r" {
                set config::ping_count [validate_parameter $arg]
            }
            "/s" {
                set config::ping_size [validate_parameter $arg]
            }
            "/b" {
                set show_banner 1
            }
            "/n" {
                set config::show_router_info 0
            }
            "/t" {
                set config::show_templates 1
            }
            "/v" {
                set config::show_output 1
            }
            "/l" {
                set list_only 1
            }
            default {
                puts "Invalid option: $arg"
                display_help
                return
            }
        }
    }
    
    if {$show_banner} {
        display_banner
    }
    
    if {$list_only} {
        list_hosts
        return
    }
    
    # Detect router model
    set model [detect_router_model]
    if {$model eq ""} {
        puts "\n*** WARNING: This script is designed for Cisco routers with cellular capabilities ***"
        puts "*** Supported models: C111, C819, CISCO1921 ***"
        puts "*** Proceeding with basic ICMP tests only ***\n"
        set config::show_router_info 0
    }
    
    # Display router information if requested
    if {$config::show_router_info && $model ne ""} {
        print_separator
        puts "Router Information:"
        puts "==================="
        
        set info [get_cellular_info $model]
        if {[dict exists $info error]} {
            puts "  Error gathering cellular information"
        } else {
            puts "  Model              : $model"
            puts "  Serial Number      : [dict get $info serial]"
            puts "  IMEI               : [dict get $info imei]"
            puts "  SIM Status         : [dict get $info sim]"
            print_separator
            puts "Signal Information:"
            puts "==================="
            puts "  RSSI               : [dict get $info rssi]"
            puts "  SNR/ECIO           : [dict get $info snr]"
        }
        print_separator
    }
    
    # Perform ICMP tests
    puts "\nICMP Connectivity Tests:"
    puts "========================"
    puts "Configuration: $config::ping_count packets, $config::ping_size bytes each\n"
    
    # Sort hosts alphabetically
    foreach {host ip} [lsort -stride 2 [array get element]] {
        perform_ping $host $ip $config::ping_count $config::ping_size $config::show_output
    }
    
    print_separator
    puts "\nTest completed at [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
}

# Execute main procedure
main $argv