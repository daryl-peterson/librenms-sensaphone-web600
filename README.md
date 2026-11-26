# Sensaphone WEB600 support for LibreNMS

Adds SNMP discovery and monitoring for the Sensaphone WEB600. LibreNMS can show alarm status for enabled inputs and temperature readings for supported temperature probes.

## Requirements

- An existing LibreNMS installation with PHP 8.3 or later. The installer expects the root directory to contain `lnms`.
- A WEB600 with SNMP enabled and reachable from the LibreNMS poller.
- Write access to the LibreNMS installation directory. If you copy the files from Windows, use a mapped drive or network share that exposes that directory.

## Install on the LibreNMS host

Clone the repository and run the installer. It defaults to `/opt/librenms`.

```bash
git clone https://github.com/daryl-peterson/librenms-sensaphone-web600.git
cd librenms-sensaphone-web600
./install.sh
```

For a custom installation path, pass it as an argument.

```bash
./install.sh "/path/to/librenms"
```

Run as the account that owns the LibreNMS files, or use `sudo ./install.sh` if your account needs permission to write there. The script checks the PHP file and matches each destination file’s ownership to a neighboring LibreNMS file.

## Copy from Windows

In Command Prompt, open the cloned or extracted repository and run `install.bat` with the LibreNMS root. For example, use a mapped drive or a UNC path.

```bat
install.bat "Z:\LibreNMS"
install.bat "\\monitoring-server\librenms"
```

Use a share account that can write to the LibreNMS tree. Confirm on the LibreNMS host that its service account can read the copied files. Run device discovery and polling on that host.

Both installers skip identical files and stop if a destination file differs. Review any conflicting file before replacing it.

## Add or rediscover the WEB600

For a new device, open **Devices → Add Device** in LibreNMS and enter the WEB600 hostname or IP address and its SNMP settings. For command-line options, see the [LibreNMS guide to adding a device](https://docs.librenms.org/Support/Adding-a-Device/).

From the LibreNMS directory, run these commands as the LibreNMS service account. Replace `web600.example.local` with the hostname or IP address used when adding the device.

```bash
./lnms device:discover web600.example.local
./lnms device:poll web600.example.local
```

Open the device in LibreNMS and check that it identifies as **Sensaphone WEB600** and shows the available sensors under **Health**. If detection fails, verify that the poller can reach the device over SNMP and that the device reports `.1.3.6.1.4.1.8338.1.1.4` as its `sysObjectID`. See the [discovery guide](https://docs.librenms.org/Support/Discovery%20Support/) and [poller guide](https://docs.librenms.org/Support/Poller%20Support/).

## Files copied

The paths below are relative to the LibreNMS root.

- `resources/definitions/os_detection/sensaphone-web600.yaml`
- `LibreNMS/OS/SensaphoneWeb600.php`
- `html/images/os/sensaphone-web600.svg`
