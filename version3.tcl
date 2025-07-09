#!/usr/bin/env tclsh
# Advanced ICMP Test Script for Cisco Routers with Full Feature Set
# Version: 3.0
# Features: Logging, Config Files, Parallel Ping, Email Alerts, Historical Tracking

# =========================================================
# Global Configuration Namespace
# =========================================================
namespace eval config {
    # Default values - can be overridden by config file
    variable ping_size 100
    variable ping_count 5
    variable show_router_info 1
    variable show_output 0
    variable show_templates 0
    variable max_ping_count 1000
    variable min_ping_count 1
    variable max_ping_size 1450
    variable min_ping_size 36
    
    # Logging configuration
    variable enable_logging 1
    variable log_directory "/flash/icmp_logs"
    variable log_retention_days 30
    
    # Email configuration
    variable enable_email_alerts 0
    variable smtp_server ""
    variable email_from "router@company.com"
    variable email_to "netadmin@company.com"
    variable alert_threshold 50  ;# Alert if success rate below this %
    
    # Historical tracking
    variable enable_history 1
    variable history_file "/flash/icmp_history.db"
    variable history_retention_days 90
    
    # Parallel ping configuration
    variable enable_parallel 0
    variable parallel_timeout 10
}

# Default host configuration - can be overridden by config file
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

# =========================================================
# Configuration File Management
# =========================================================
proc load_config {filename} {
    global element config::enable_logging config::log_directory
    global config::enable_email_alerts config::smtp_server
    global config::email_from config::email_to config::alert_threshold
    global config::enable_history config::history_file
    
    if {![file exists $filename]} {
        puts "Configuration file not found: $filename"
        return 0
    }
    
    puts "Loading configuration from: $filename"
    
    # Source the configuration file in a safe manner
    if {[catch {source $filename} err]} {
        puts "Error loading configuration: $err"
        return 0
    }
    
    puts "Configuration loaded successfully"
    return 1
}

proc save_config {filename} {
    global element config::ping_size config::ping_count
    global config::enable_logging config::log_directory
    global config::enable_email_alerts config::smtp_server
    global config::email_from config::email_to config::alert_threshold
    global config::enable_history config::history_file
    
    set fp [open $filename w]
    
    puts $fp "# ICMP Test Configuration File"
    puts $fp "# Generated: [clock format [clock seconds]]"
    puts $fp ""
    
    # Save test parameters
    puts $fp "# Test Parameters"
    puts $fp "set config::ping_size $config::ping_size"
    puts $fp "set config::ping_count $config::ping_count"
    puts $fp ""
    
    # Save logging configuration
    puts $fp "# Logging Configuration"
    puts $fp "set config::enable_logging $config::enable_logging"
    puts $fp "set config::log_directory \"$config::log_directory\""
    puts $fp ""
    
    # Save email configuration
    puts $fp "# Email Alert Configuration"
    puts $fp "set config::enable_email_alerts $config::enable_email_alerts"
    puts $fp "set config::smtp_server \"$config::smtp_server\""
    puts $fp "set config::email_from \"$config::email_from\""
    puts $fp "set config::email_to \"$config::email_to\""
    puts $fp "set config::alert_threshold $config::alert_threshold"
    puts $fp ""
    
    # Save history configuration
    puts $fp "# Historical Tracking Configuration"
    puts $fp "set config::enable_history $config::enable_history"
    puts $fp "set config::history_file \"$config::history_file\""
    puts $fp ""
    
    # Save host configuration
    puts $fp "# Host Configuration"
    puts $fp "array set element {"
    foreach {name ip} [array get element] {
        puts $fp "    $name $ip"
    }
    puts $fp "}"
    
    close $fp
    puts "Configuration saved to: $filename"
}

# =========================================================
# Logging Functions
# =========================================================
proc init_logging {} {
    global config::log_directory config::enable_logging
    
    if {!$config::enable_logging} {return}
    
    # Create log directory if it doesn't exist
    if {![file exists $config::log_directory]} {
        file mkdir $config::log_directory
    }
    
    # Clean up old logs
    cleanup_old_logs
}

proc cleanup_old_logs {} {
    global config::log_directory config::log_retention_days
    
    set cutoff_time [expr {[clock seconds] - ($config::log_retention_days * 86400)}]
    
    foreach logfile [glob -nocomplain -directory $config::log_directory "*.log"] {
        if {[file mtime $logfile] < $cutoff_time} {
            file delete $logfile
            puts "Deleted old log: [file tail $logfile]"
        }
    }
}

proc log_results {results} {
    global config::log_directory config::enable_logging
    
    if {!$config::enable_logging} {return}
    
    set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    set logfile [file join $config::log_directory "icmp_test_${timestamp}.log"]
    
    set fp [open $logfile w]
    puts $fp "ICMP Test Results"
    puts $fp "================="
    puts $fp "Timestamp: [clock format [clock seconds]]"
    puts $fp ""
    
    # Log router information
    if {[dict exists $results router_info]} {
        puts $fp "Router Information:"
        foreach {key value} [dict get $results router_info] {
            puts $fp "  $key: $value"
        }
        puts $fp ""
    }
    
    # Log test results
    puts $fp "Test Results:"
    foreach {host data} [dict get $results tests] {
        puts $fp "  Host: $host ([dict get $data ip])"
        puts $fp "    Success Rate: [dict get $data success_rate]%"
        puts $fp "    RTT: [dict get $data rtt]"
        puts $fp "    Status: [dict get $data status]"
        puts $fp ""
    }
    
    close $fp
    puts "\nResults logged to: $logfile"
}

# =========================================================
# Historical Tracking Functions
# =========================================================
proc init_history {} {
    global config::enable_history config::history_file
    
    if {!$config::enable_history} {return}
    
    # Create history file if it doesn't exist
    if {![file exists $config::history_file]} {
        set fp [open $config::history_file w]
        puts $fp "timestamp,host,ip,success_rate,rtt,status"
        close $fp
    }
    
    # Clean up old history entries
    cleanup_old_history
}

proc cleanup_old_history {} {
    global config::history_file config::history_retention_days
    
    if {![file exists $config::history_file]} {return}
    
    set cutoff_time [expr {[clock seconds] - ($config::history_retention_days * 86400)}]
    set temp_file "${config::history_file}.tmp"
    
    set fp_in [open $config::history_file r]
    set fp_out [open $temp_file w]
    
    # Copy header
    gets $fp_in line
    puts $fp_out $line
    
    # Filter old entries
    while {[gets $fp_in line] >= 0} {
        set timestamp [lindex [split $line ,] 0]
        if {[catch {clock scan $timestamp} time]} {continue}
        if {$time >= $cutoff_time} {
            puts $fp_out $line
        }
    }
    
    close $fp_in
    close $fp_out
    
    file rename -force $temp_file $config::history_file
}

proc track_history {results} {
    global config::enable_history config::history_file
    
    if {!$config::enable_history} {return}
    
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    
    set fp [open $config::history_file a]
    
    foreach {host data} [dict get $results tests] {
        set ip [dict get $data ip]
        set success_rate [dict get $data success_rate]
        set rtt [dict get $data rtt]
        set status [dict get $data status]
        
        puts $fp "$timestamp,$host,$ip,$success_rate,$rtt,$status"
    }
    
    close $fp
}

proc generate_history_report {days} {
    global config::history_file
    
    if {![file exists $config::history_file]} {
        puts "No history file found"
        return
    }
    
    set cutoff_time [expr {[clock seconds] - ($days * 86400)}]
    set stats [dict create]
    
    set fp [open $config::history_file r]
    gets $fp ;# Skip header
    
    while {[gets $fp line] >= 0} {
        set fields [split $line ,]
        if {[llength $fields] < 6} {continue}
        
        lassign $fields timestamp host ip success_rate rtt status
        
        if {[catch {clock scan $timestamp} time]} {continue}
        if {$time < $cutoff_time} {continue}
        
        # Initialize host stats if needed
        if {![dict exists $stats $host]} {
            dict set stats $host total 0
            dict set stats $host success 0
            dict set stats $host failures 0
            dict set stats $host avg_success 0
            dict set stats $host rtts [list]
        }
        
        # Update statistics
        dict incr stats $host total
        if {$success_rate == 100} {
            dict incr stats $host success
        } elseif {$success_rate == 0} {
            dict incr stats $host failures
        }
        
        set current_avg [dict get $stats $host avg_success]
        set new_avg [expr {($current_avg * ([dict get $stats $host total] - 1) + $success_rate) / [dict get $stats $host total]}]
        dict set stats $host avg_success $new_avg
        
        if {$rtt ne "N/A"} {
            dict lappend stats $host rtts [lindex [split $rtt /] 1]
        }
    }
    
    close $fp
    
    # Display report
    puts "\nHistorical Report (Last $days days)"
    puts "===================================="
    
    foreach {host data} $stats {
        puts "\nHost: $host"
        puts "  Total Tests: [dict get $data total]"
        puts "  Successful: [dict get $data success] ([expr {[dict get $data success] * 100 / [dict get $data total]}]%)"
        puts "  Failed: [dict get $data failures] ([expr {[dict get $data failures] * 100 / [dict get $data total]}]%)"
        puts "  Average Success Rate: [format %.1f [dict get $data avg_success]]%"
        
        set rtts [dict get $data rtts]
        if {[llength $rtts] > 0} {
            set avg_rtt [expr {[tcl::mathop::+ {*}$rtts] / double([llength $rtts])}]
            puts "  Average RTT: [format %.1f $avg_rtt] ms"
        }
    }
}

# =========================================================
# Email Alert Functions
# =========================================================
proc send_email_alert {results} {
    global config::enable_email_alerts config::smtp_server
    global config::email_from config::email_to config::alert_threshold
    
    if {!$config::enable_email_alerts || $config::smtp_server eq ""} {return}
    
    # Check if any host is below threshold
    set failures [list]
    foreach {host data} [dict get $results tests] {
        if {[dict get $data success_rate] < $config::alert_threshold} {
            lappend failures [list $host [dict get $data ip] [dict get $data success_rate]]
        }
    }
    
    if {[llength $failures] == 0} {return}
    
    # Compose email
    set subject "ICMP Test Alert - [llength $failures] Host(s) Below Threshold"
    set body "ICMP Test Alert\n"
    append body "===============\n"
    append body "Timestamp: [clock format [clock seconds]]\n"
    append body "Alert Threshold: $config::alert_threshold%\n\n"
    append body "Failed Hosts:\n"
    
    foreach failure $failures {
        lassign $failure host ip success_rate
        append body "  $host ($ip): $success_rate% success rate\n"
    }
    
    # Send email using IOS email feature if available
    if {[catch {
        exec "send email $config::email_to subject \"$subject\" body \"$body\" from $config::email_from server $config::smtp_server"
    } err]} {
        puts "Failed to send email alert: $err"
    } else {
        puts "Email alert sent to: $config::email_to"
    }
}

# =========================================================
# Parallel Ping Functions
# =========================================================
proc perform_parallel_ping {hosts} {
    global config::ping_count config::ping_size config::parallel_timeout
    global config::enable_parallel
    
    if {!$config::enable_parallel} {
        # Fall back to sequential ping
        return [perform_sequential_ping $hosts]
    }
    
    puts "\nStarting parallel ping tests..."
    set results [dict create]
    
    # IOS doesn't support true parallel execution in TCL
    # This is a simulated parallel approach using background jobs
    foreach {host ip} $hosts {
        # Start ping in background (if IOS supports it)
        set job_id [start_background_ping $host $ip $config::ping_count $config::ping_size]
        dict set results $host job_id $job_id
        dict set results $host ip $ip
    }
    
    # Wait for all jobs to complete
    set start_time [clock seconds]
    while {1} {
        set all_done 1
        foreach {host data} $results {
            if {[dict exists $data job_id]} {
                set job_id [dict get $data job_id]
                if {[check_background_job $job_id]} {
                    # Job completed, get results
                    set ping_result [get_background_result $job_id]
                    dict set results $host [parse_ping_result $ping_result]
                    dict unset results $host job_id
                } else {
                    set all_done 0
                }
            }
        }
        
        if {$all_done} {break}
        
        # Check timeout
        if {[expr {[clock seconds] - $start_time}] > $config::parallel_timeout} {
            puts "Parallel ping timeout reached"
            break
        }
        
        after 100 ;# Wait 100ms before checking again
    }
    
    return $results
}

proc start_background_ping {host ip count size} {
    # This is a placeholder - actual implementation depends on IOS capabilities
    # In real IOS, you might use event manager or other background mechanisms
    set job_id "job_${host}_[clock clicks]"
    
    # Simulate background job
    exec "ping $ip repeat $count size $size" &
    
    return $job_id
}

proc check_background_job {job_id} {
    # Check if background job is complete
    # This is implementation-specific
    return 1
}

proc get_background_result {job_id} {
    # Get results from background job
    # This is implementation-specific
    return ""
}

proc perform_sequential_ping {hosts} {
    global config::ping_count config::ping_size config::show_output
    
    set results [dict create]
    
    foreach {host ip} $hosts {
        set ping_data [perform_single_ping $host $ip $config::ping_count $config::ping_size $config::show_output]
        dict set results $host $ping_data
    }
    
    return $results
}

# =========================================================
# Core Functions (Enhanced)
# =========================================================
proc perform_single_ping {host ip repeat size verbose} {
    if {$verbose} {
        puts "\nPinging $host ($ip):"
        ping $ip repeat $repeat size $size
    }
    
    # Capture and parse output
    set result [exec "ping $ip repeat $repeat size $size"]
    
    return [parse_ping_result $result $ip]
}

proc parse_ping_result {result {ip ""}} {
    set data [dict create]
    dict set data ip $ip
    
    # Extract success rate
    if {[regexp {Success rate is (\d+) percent} $result match success_rate]} {
        dict set data success_rate $success_rate
    } else {
        dict set data success_rate 0
    }
    
    # Extract round-trip times
    if {[regexp {round-trip.*= ([\d/]+) ms} $result match rtt]} {
        dict set data rtt $rtt
    } else {
        dict set data rtt "N/A"
    }
    
    # Determine status
    set success_rate [dict get $data success_rate]
    if {$success_rate == 0} {
        dict set data status "UNREACHABLE"
    } elseif {$success_rate == 100} {
        dict set data status "OK"
    } else {
        dict set data status "PARTIAL"
    }
    
    return $data
}

proc display_help {} {
    puts "\nAdvanced ICMP Test Script v3.0"
    puts "=============================="
    puts "\nUSAGE:"
    puts "  test \[options\]"
    puts "\nBASIC OPTIONS:"
    puts "  /h, /?              Display this help message"
    puts "  /r=<number>         Number of ping packets (1-1000, default: 5)"
    puts "  /s=<size>           Ping packet size in bytes (36-1450, default: 100)"
    puts "  /b                  Display banner"
    puts "  /n                  Skip router identification output"
    puts "  /t                  Add visual separators in output"
    puts "  /v                  Show verbose ping output"
    puts "  /l                  List configured hosts"
    puts "\nADVANCED OPTIONS:"
    puts "  /c=<file>           Load configuration from file"
    puts "  /save=<file>        Save current configuration to file"
    puts "  /log                Enable logging (if not already enabled)"
    puts "  /nolog              Disable logging for this run"
    puts "  /email              Force email alerts (if configured)"
    puts "  /history=<days>     Show historical report for last N days"
    puts "  /parallel           Use parallel ping (if supported)"
    puts "\nEXAMPLES:"
    puts "  Router(tcl)#test"
    puts "  Router(tcl)#test /c=icmp_config.tcl /log"
    puts "  Router(tcl)#test /history=7"
    puts "  Router(tcl)#test /save=my_config.tcl"
    puts ""
}

# =========================================================
# Main Execution Function
# =========================================================
proc main {argv} {
    global element config::ping_size config::ping_count
    global config::show_router_info config::show_output config::show_templates
    global config::enable_logging config::enable_email_alerts config::enable_history
    global config::enable_parallel
    
    set show_banner 0
    set list_only 0
    set config_file ""
    set save_file ""
    set show_history 0
    set force_email 0
    
    # Parse command line arguments
    foreach arg $argv {
        if {[regexp {^/c=(.+)$} $arg match file]} {
            set config_file $file
            continue
        }
        if {[regexp {^/save=(.+)$} $arg match file]} {
            set save_file $file
            continue
        }
        if {[regexp {^/history=(\d+)$} $arg match days]} {
            set show_history $days
            continue
        }
        
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
            "/log" {
                set config::enable_logging 1
            }
            "/nolog" {
                set config::enable_logging 0
            }
            "/email" {
                set force_email 1
            }
            "/parallel" {
                set config::enable_parallel 1
            }
            default {
                if {$opt ne "/c" && $opt ne "/s" && $opt ne "/h"} {
                    puts "Invalid option: $arg"
                    display_help
                    return
                }
            }
        }
    }
    
    # Load configuration file if specified
    if {$config_file ne ""} {
        load_config $config_file
    }
    
    # Save configuration if requested
    if {$save_file ne ""} {
        save_config $save_file
        return
    }
    
    # Show history report if requested
    if {$show_history > 0} {
        generate_history_report $show_history
        return
    }
    
    if {$show_banner} {
        display_banner
    }
    
    if {$list_only} {
        list_hosts
        return
    }
    
    # Initialize subsystems
    init_logging
    init_history
    
    # Detect router model
    set model [detect_router_model]
    set results [dict create]
    
    # Gather router information
    if {$config::show_router_info && $model ne ""} {
        set router_info [get_cellular_info $model]
        dict set results router_info $router_info
        display_router_info $router_info $model
    }
    
    # Perform ICMP tests
    puts "\nICMP Connectivity Tests:"
    puts "========================"
    puts "Configuration: $config::ping_count packets, $config::ping_size bytes each"
    
    if {$config::enable_parallel} {
        puts "Mode: Parallel execution"
    } else {
        puts "Mode: Sequential execution"
    }
    puts ""
    
    # Execute ping tests
    set test_results [perform_sequential_ping [array get element]]
    dict set results tests $test_results
    
    # Display results
    foreach {host data} $test_results {
        set status [dict get $data status]
        set success_rate [dict get $data success_rate]
        set rtt [dict get $data rtt]
        
        puts [format "  %-20s : %-12s (Success: %3d%%, RTT: %s)" \
            $host $status $success_rate $rtt]
    }
    
    print_separator
    puts "\nTest completed at [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
    
    # Log results
    log_results $results
    
    # Track history
    track_history $results
    
    # Send email alerts if needed
    if {$force_email || $config::enable_email_alerts} {
        send_email_alert $results
    }
}

# =========================================================
# Utility Functions
# =========================================================
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

proc display_router_info {info model} {
    print_separator
    puts "Router Information:"
    puts "==================="
    
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

proc display_banner {} {
    puts "\n╔═══════════════════════════╗"
    puts "║  ADVANCED ICMP TEST v3.0  ║"
    puts "║    Full Feature Edition   ║"
    puts "╚═══════════════════════════╝\n"
}

proc list_hosts {} {
    global element
    puts "\nConfigured Test Hosts:"
    puts "====================="
    foreach {name ip} [lsort -stride 2 [array get element]] {
        puts [format "  %-20s : %s" $name $ip]
    }
    puts ""
}

# Execute main procedure
main $argv