package DriveUtils;

use strict;
use warnings;
use Net::GPSD3;
use Term::ReadKey;
use File::Slurp;
use Term::ANSIColor;
use IPC::System::Simple qw(system);
use Exporter 'import';

our @EXPORT = qw(
    log_data
    file_has_data
    get_gps_coords
    scan_networks
    extract_info
    is_dupe_ssid
    Die
    Notice
    Failure
    extract_settings_from_config
);

our @EXPORT_OK = qw(
    spoof_mac_address
    fix_mac_address
    parse_dump_file
);

# Parse captured data from deauth
sub parse_dump_file {
    # my $networkName = @_;
    # my $capFile = "$networkName.pcap";
    my $captureFile = @_;
    my @returnData;
    my $HASHFILE;
    if (my $match =~ /\/([^\/]+)\.pcap/) {
        $HASHFILE = $1;
    }

    open my $fh, '<', $captureFile or return (-1, @returnData);
    while (my $line = <$fh>) {
        # Regex to find hash in traffic dump
        if ($line =~ //) {

            write_file($HASHFILE, $line);
        }
    }
    close $fh;


    my $exit_status = `rm $captureFile`;
    return ($exit_status, @returnData);
}

# Log data
sub log_data {
    # Add functionality to log in wigle csv format so that this information can also be sent to Wigle
    # Example of Wigle csv format:
    # [BSSID],[SSID],[Capabilities],[First timestamp seen],[Channel],[Frequency],[RSSI],[Latitude],[Longitude],[Altitude],[Accuracy],[RCOIs],[MfgrId],[Type]
    # 1a:9f:ee:5c:71:c6,Scampoodle,[WPA2-EAP-CCMP][ESS],2018-08-01 13:08:27,161,5805,-43,37.76578028,-123.45919439,67,3.2160000801086426,5A03BA0000 BAA2D00000 BAA2D02000,,WIFI

    # Change this to determine whether the log data has the hash. Because that will affect the number of arguments
    if (@_ == 5) {
        # [ err, essid, mac, file, programOutputFile ]
        my ($err, $ssid, $mac, $file, $output_file) = @_;
        my $log_entry = "[\"$err\", \"$ssid\", \"$mac\", \"$file\"]\n";
        print "$log_entry";
        write_file($output_file, {append => 1}, $log_entry);
    } else {
        # [ lat, lon, essid, mac, file, programOutputFile ]
        my ($lat, $lon, $ssid, $mac, $file, $output_file) = @_;
        my $log_entry = "[\"$lat, $lon\", \"$ssid\", \"$mac\", \"$file\"]\n";
        write_file($output_file, {append => 1}, $log_entry);
    } 
}

sub file_has_data {
    my ($file) = shift;
    my $check = `stat $file | awk '/Size:/ {print \$2}'`;
    if ($check <= 0) {
        return 0;
    }
    return 1;
}
# Get GPS coordinates
sub get_gps_coords {
    my $gps = shift;
    my $lat;
    my $lon;
    my $fix = $gps->poll->fix;
    unless ($fix) {
        Notice("Warning: No GPS fix available");
    } else {
        $lat = $fix->lat;
        $lon = $fix->lon;
    }
    unless (defined $lat && defined $lon) {
        Notice("Warning: GPS coordinates not defined");
    } else {
        print "GPS: $lat, $lon";
    }
    return ($lat, $lon);
}

# Scan for networks
sub scan_networks {
    my $interface = shift;
    my $cmd = "iwlist $interface scan";
    my @list = `$cmd 2>&1`;
    my $exit_status = $? >> 8;
    if ($exit_status != 0) {
        Failure("Failed to scan for networks");
        undef @list;
    }
    return @list;
}

# Capture handshake
# TODO: Get this function working properly
sub capture_handshake {
    my $cap_dir = shift;
    my $ssid = shift;
    my $bssid = shift;
    my $name = shift;
    my $capture_file = "$cap_dir/$name.pcap";
    my $HASH;
    # Split thread off here
    # system("airodump-ng --bssid $bssid -c 6 -w $capture_file $interface") == 0 or Die("Failed to start airodump-ng: $!");
    # system("aireplay-ng --deauth 10 -a $bssid $interface") == 0 or Die("Failed to deauthenticate clients: $!");
    # Direct output to $capture_file
    my $HASHFILE = parse_dump_file($capture_file);
    open my $fh, '<', $HASHFILE;
    while (my $line = <$fh>) {
        $HASH = $line;
    }
    close $fh;
    return ($capture_file, $HASH);
}

# Extract data from output
sub extract_info {
    my ($mode, $cap_dir, $output_file, @data) = @_;
    my @info;
    my ($bssid, $essid);
    my $HASH;
    foreach my $line (@data) {
        chomp($line);
        if (!$bssid && $line =~ /Address:\s+([0-9A-Fa-f:]{17})\b/) {
            $bssid = $1;
            next;
        }
        if (!$essid && $line =~ /^\s*ESSID:"([^"]+)"/) {
            $essid = $1;
        }
        if (defined $bssid && defined $essid) {
            my $name_for_file = $essid;
            $name_for_file =~ s/ /_/g;
            # Check for duplicate ESSID and BSSID
            if (!is_dupe_ssid($name_for_file, $essid, $bssid, $output_file, $cap_dir, @info)) {
                my $capture_file;
                if ($mode eq 'safe') {
                    $capture_file = "$cap_dir/$name_for_file.cap";
                } else {
                    my @capData = capture_handshake($cap_dir, $essid, $bssid, $name_for_file);
                    $capture_file = $capData[0];
                    if (scalar @capData == 2) {
                        $HASH = $capData[1];
                    }
                    $capture_file = capture_handshake($cap_dir, $essid, $bssid, $name_for_file);
                }
                if (defined $HASH) {
                    push @info, ($essid, $bssid, $capture_file, $HASH);
                } else {
                    push @info, ($essid, $bssid, $capture_file, "No hash recieved");
                }
            }
            undef $bssid;
            undef $essid;
        }
    }
    return @info;
}

# Check if duplicate ESSID or BSSID exists in existing records 
sub is_dupe_ssid {
    my ($name, $ssid, $mac, $output_file, $cap_dir, @data) = @_;
    for (my $i = 0; $i < @data; $i += 3) {
        if ($data[$i] eq $ssid || $data[$i+1] eq $mac) {
            return 1;
        }
    }
    open my $fh, '<', $output_file or Die("Could not open \"$output_file\": $!");
    while (my $line = <$fh>) {
        chomp $line;
        if (index($line, $ssid) != -1 || index($line, $mac) != -1) {
            close $fh;
            return 1;
        }
    }
    close $fh;
    if (-e "$cap_dir/$name.cap") {
        return 1;
    }
    return 0;
}

# Convenience subs
sub Die {
    my ($message) = shift;
    print color('red'), "$message\n", color('reset');
    exit 1;
}

sub Notice {
    my ($message) = shift;
    print color('yellow'), "$message\n", color('reset');
}

sub Failure {
    my ($message) = shift;
    print color('red'), "$message\n", color('reset');
}

sub extract_settings_from_config {
    my %configs;
    my $config_file = "driver/data/config.cfg";
    open my $fh, '<', $config_file or Die("Could not read config file.");
    while (my $line = <$fh>) {
        if ($line =~ /^\[MODE\]/) {
            my $modeSwitch = substr($line, 7);
            print $modeSwitch;
            chomp($modeSwitch);
            if ($modeSwitch eq "safe" || $modeSwitch eq "unsafe") {
                $configs{'MODE'} = substr($line, 7);
            } else {
                Die("Invalid option in config file for MODE: $modeSwitch. Expected 'safe' or 'unsafe'.");
            }
        } elsif ($line =~ /^\[LOG\]/) {
            my $logSwitch;
            if (length($line) == 6) {
                $logSwitch = "file";
            } else {
                $logSwitch = substr($line, 6);
            }
            chomp($logSwitch);
            if ($logSwitch eq "wigle" || $logSwitch eq "file") {
                $configs{'LOG'} = substr($line, 6);
            } else {
                Die("Invalid option in config file for LOG: $logSwitch. Expected 'wigle' or 'file',");
            }
        }
    }
    close $fh;
    return %configs;
}


sub spoof_mac_address {
    # TODO: Implement this
    print "Generating a spoofed MAC address...";
}

sub fix_mac_address {
    my $old_mac = shift;
    # Change it back
}

1;
