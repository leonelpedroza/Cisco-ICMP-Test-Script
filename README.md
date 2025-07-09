# Cisco ICMP Test Script

A comprehensive TCL/TK script for performing ICMP connectivity tests on Cisco routers with cellular capabilities. This script evolved from a simple ping utility to a full-featured network monitoring solution with logging, alerting, and historical tracking capabilities.

## History

There are two ways to accomplish things. The easy way, and the complicated way. In February 2020, I was installing 70+ Wireless Cisco routers in the Caribbean and permanently needed to run an ICMP test between the new unit and the servers. 

There is a well-known TCL script in the Cisco community that can make the job fast, reliable, and easy, and it is:
```bash
foreach ipaddr {
 192.168.1.1
 10.1.1.1
 172.168.2.1
 10.1.1.2
} { ping $ipaddr}
exit

```

I have some extra hours, so I decided to polish my scripting abilities and created a more sophisticated version with log event possibilities, email alerts, help messages, and a banner.

And it works at that time with that IOS version.


## Overview

This script is designed specifically for Cisco routers with cellular interfaces (models C111, C819, and CISCO1921). It performs automated ICMP tests to multiple configured hosts while gathering cellular signal information and providing detailed reporting capabilities.

## Version Comparison

| Feature | Version 1.0 (Original) | Version 2.0 (Enhanced) | Version 3.0 (Advanced) |
|---------|------------------------|------------------------|------------------------|
| **Basic ICMP Testing** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Cellular Info Display** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Command Line Arguments** | ✅ Basic | ✅ Enhanced | ✅ Full |
| **Router Model Detection** | ✅ 3 Models | ✅ 3 Models + Fallback | ✅ 3 Models + Fallback |
| **Code Organization** | ❌ Procedural | ✅ Namespaced | ✅ Modular |
| **Configuration Management** | ❌ Hardcoded | ❌ Hardcoded | ✅ File-based |
| **Logging to File** | ❌ No | ❌ No | ✅ Yes |
| **Historical Tracking** | ❌ No | ❌ No | ✅ Yes |
| **Email Alerts** | ❌ No | ❌ No | ✅ Yes |
| **Parallel Ping** | ❌ No | ❌ No | ✅ Framework |
| **Host Listing** | ❌ No | ✅ Yes (`/l`) | ✅ Yes |
| **Output Formatting** | 🟡 Basic | ✅ Enhanced | ✅ Professional |
| **Error Handling** | 🟡 Basic | ✅ Improved | ✅ Comprehensive |
| **Help System** | ✅ Yes | ✅ Detailed | ✅ Extensive |
| **Visual Separators** | ✅ Optional | ✅ Better | ✅ Professional |
| **Report Generation** | ❌ No | ❌ No | ✅ Yes |
| **Log Rotation** | ❌ No | ❌ No | ✅ Automatic |
| **Colored Output** | ❌ No | 🟡 Mentioned | ✅ Implemented |
| **Timestamp Display** | ❌ No | ✅ Yes | ✅ Enhanced |
| **Statistical Analysis** | ❌ No | ❌ No | ✅ Yes |

### Legend
- ✅ Full Support
- 🟡 Partial/Basic Support
- ❌ Not Available

## Supported Router Models

- **Cisco C111** - LTE enabled routers
- **Cisco C819** - 3G/4G enabled routers
- **Cisco 1921** - With cellular modules

*Note: The script will work on other routers but without cellular information display.*

## Basic Setup

### 1. Transfer the Script to Your Router

```bash
# Option 1: Via TFTP
Router#copy tftp://YOUR_TFTP_SERVER/icmp_test_v3.tcl flash:test.tcl

# Option 2: Via USB
Router#copy usbflash0:icmp_test_v3.tcl flash:test.tcl

# Option 3: Via FTP
Router#copy ftp://username:password@YOUR_FTP_SERVER/icmp_test_v3.tcl flash:test.tcl
```

### 2. Verify the Script

```bash
Router#dir flash: | include test.tcl
Router#more flash:test.tcl
```

### 3. Create Required Directories (for v3.0)

```bash
Router#mkdir flash:icmp_logs
```

### 4. Set Up Email Alerts (Optional - v3.0 only)

```bash
Router(config)#ip domain-name your-domain.com
Router(config)#ip name-server 8.8.8.8
Router(config)#mail-server smtp.your-domain.com priority 1
```

## How to Use

### Basic Usage

#### Running the Script

```bash
# Method 1: Direct execution
Router#tclsh flash:test.tcl

# Method 2: With parameters
Router#tclsh flash:test.tcl /r=10 /s=500

# Method 3: From TFTP (no local copy needed)
Router#tclsh tftp://10.1.1.100/test.tcl
```

### Command Line Options

#### Version 1.0 Options
```bash
/r=XXX    # Number of pings (1-1000, default: 5)
/s=XXX    # Packet size (36-1450, default: 100)
/b        # Show banner
/n        # No router identification
/t        # Template with line separators
/v        # Verbose output
/h, /?    # Show help
```

#### Additional Version 2.0 Options
```bash
/l        # List configured hosts without testing
```

#### Additional Version 3.0 Options
```bash
/c=file          # Load configuration from file
/save=file       # Save current configuration
/log             # Force enable logging
/nolog           # Disable logging for this run
/email           # Force send email alert
/history=days    # Show historical report
/parallel        # Use parallel ping (if supported)
```

### Example Use Cases

#### 1. Quick Network Check
```bash
Router#tclsh flash:test.tcl
```

#### 2. Detailed Test with More Packets
```bash
Router#tclsh flash:test.tcl /r=20 /s=1000 /t
```

#### 3. Verbose Mode with Banner
```bash
Router#tclsh flash:test.tcl /b /v
```

#### 4. List Configured Hosts (v2.0+)
```bash
Router#tclsh flash:test.tcl /l
```

#### 5. Save Configuration (v3.0)
```bash
Router#tclsh flash:test.tcl /save=my_config.tcl
```

#### 6. Load Custom Configuration (v3.0)
```bash
Router#tclsh flash:test.tcl /c=my_config.tcl
```

#### 7. View 7-Day History Report (v3.0)
```bash
Router#tclsh flash:test.tcl /history=7
```

#### 8. Run with Email Alert (v3.0)
```bash
Router#tclsh flash:test.tcl /c=prod_config.tcl /email
```

### Configuration File Example (v3.0)

Create a configuration file to customize hosts and settings:

```tcl
# my_config.tcl
# Custom configuration for production environment

# Test Parameters
set config::ping_size 500
set config::ping_count 20

# Email Settings
set config::enable_email_alerts 1
set config::smtp_server "mail.company.com"
set config::email_from "router01@company.com"
set config::email_to "noc@company.com"
set config::alert_threshold 90

# Custom Hosts
array set element {
    DC_CORE_SWITCH      10.0.0.1
    INTERNET_GATEWAY    10.0.0.254
    PRIMARY_DNS         8.8.8.8
    BACKUP_DNS          8.8.4.4
    CLOUD_ENDPOINT      52.10.45.100
}
```

### Scheduling Automated Tests

#### Using Kron (Recommended)
```bash
Router(config)#kron policy-list ICMP_TEST
Router(config-kron-policy)#cli tclsh flash:test.tcl /c=prod_config.tcl /log

Router(config)#kron occurrence ICMP_TEST_DAILY at 08:00 recurring
Router(config-kron-occurrence)#policy-list ICMP_TEST
```

#### Using EEM (Event Manager)
```bash
Router(config)#event manager applet ICMP_TEST
Router(config-applet)#event timer cron cron-entry "0 8 * * *"
Router(config-applet)#action 1.0 cli command "enable"
Router(config-applet)#action 2.0 cli command "tclsh flash:test.tcl /c=prod_config.tcl"
```

## Output Examples

### Version 1.0 Output
```
ROUTER SERIAL NUMBER = FGL123456789
MODEM IMEI ID NUMBER = 359074000000000
SIM CARD PRESENCE    = OK

Received Signal Strength (RSSI)= -75 dBm
Signal to Noise Ratio    (SNR) = 12 dB

ICMP test....

ICMP Trying SERVER_HOST_1_ :
The SERVER_HOST_1_ is Reachable = 100% min/avg/max = 20/25/30 ms
```

### Version 3.0 Output
```
Router Information:
===================
  Model              : C819
  Serial Number      : FGL123456789
  IMEI               : 359074000000000
  SIM Status         : OK
─────────────────────────────────────────────────
Signal Information:
===================
  RSSI               : -75 dBm
  SNR/ECIO           : 12 dB
─────────────────────────────────────────────────

ICMP Connectivity Tests:
========================
Configuration: 10 packets, 500 bytes each

  DC_CORE_SWITCH       : OK           (Success: 100%, RTT: 2/3/5 ms)
  INTERNET_GATEWAY     : OK           (Success: 100%, RTT: 1/2/3 ms)
  PRIMARY_DNS          : OK           (Success: 100%, RTT: 15/20/25 ms)
  BACKUP_DNS           : PARTIAL      (Success:  80%, RTT: 20/45/100 ms)
  CLOUD_ENDPOINT       : UNREACHABLE  (Success:   0%, RTT: N/A)
─────────────────────────────────────────────────

Test completed at 2024-11-20 14:30:45

Results logged to: /flash/icmp_logs/icmp_test_20241120_143045.log
Email alert sent to: noc@company.com
```

## Troubleshooting

### Common Issues

1. **"TCL script was not made for this router model"**
   - Script detects unsupported router model
   - Will work but without cellular information

2. **"Permission denied" when creating logs**
   ```bash
   Router#mkdir flash:icmp_logs
   Router#verify /md5 flash:test.tcl
   ```

3. **Email alerts not working**
   - Verify SMTP configuration
   - Check DNS resolution
   - Ensure IP domain-name is set

4. **Script execution fails**
   ```bash
   # Check TCL support
   Router#show version | include TCL
   
   # Verify script integrity
   Router#more flash:test.tcl | include proc
   ```

### Debug Mode

For troubleshooting, add debug output to the script:
```tcl
# Add at the beginning of main procedure
puts "Debug: Starting with arguments: $argv"
```

## Best Practices

1. **Regular Configuration Backups**
   ```bash
   Router#tclsh flash:test.tcl /save=backup_[clock format [clock seconds] -format "%Y%m%d"].tcl
   ```

2. **Log Management**
   - Set appropriate retention periods
   - Monitor flash space usage
   - Archive logs to external storage

3. **Alert Tuning**
   - Set realistic thresholds
   - Test email delivery before production
   - Consider time-of-day for alerts

4. **Performance Considerations**
   - Limit parallel pings on low-memory routers
   - Adjust packet sizes for WAN links
   - Schedule during maintenance windows

## Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## License

This script is provided as-is for educational and operational purposes. Please review your organization's policies before deploying in production environments.

## Acknowledgments

- Original version by lgpr@Feb-2020
- Enhanced versions developed for the Cisco community
- Tested on IOS 15.x and IOS-XE platforms

## Version History

- **v1.0** (Feb 2020) - Initial release with basic ICMP testing
- **v2.0** (Nov 2024) - Enhanced with better organization and features
- **v3.0** (Nov 2024) - Advanced features including logging, alerts, and history

---

For more information or support, please open an issue on GitHub.
