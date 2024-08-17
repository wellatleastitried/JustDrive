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
);

# Log data
sub log_data {
    if (@_ == 5) {
        # [ err, essid, mac, file ]
        my ($err, $ssid, $mac, $file, $output_file) = @_;
        my $log_entry = "[\"$err\", \"$ssid\", \"$mac\", \"$file\"]\n";
        print "$log_entry";
        write_file($output_file, {append => 1}, $log_entry);
    } else {
        # [ lat, lon, essid, mac, file ]
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
    my $capture_file = "$cap_dir/$name.cap";
    # system("airodump-ng --bssid $bssid -c 6 -w $capture_file $interface") == 0 or Die("Failed to start airodump-ng: $!");
    # system("aireplay-ng --deauth 10 -a $bssid $interface") == 0 or Die("Failed to deauthenticate clients: $!");
    return $capture_file;
}

# Extract data from output
sub extract_info {
    my ($mode, $cap_dir, $output_file, @data) = @_;
    print "$output_file\n";
    my @info;
    my ($bssid, $essid);
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
                    $capture_file = capture_handshake($cap_dir, $essid, $bssid, $name_for_file);
                }
                push @info, ($essid, $bssid, $capture_file);
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
    my $config_file = "driver/data/config.cfg";
    open my $fh, '<', $config_file or Die("Could not read config file.");
    while (my $line = <$fh>) {
        if ($line =~ /^\[MODE\]/) {
            return substr($line, 7);
        }
    }
    close $fh;
    # TODO: Parse config file for mode, adapter information? 
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
