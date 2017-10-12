#!/bin/sh

# install automatic refresh daemon for Paragon EXTFS 10

cat << EOF
-- EXTFS 14 Refresh Scripts Installer --

This installer script demonstrates shell programming techniques such as how to
access .pkg files, install other scripts, run scheduled tasks, and more. Using
Paragon EXTFS 10 for Mac as an example, it shows how to regularly trash a
preferences file and restart the software. This is a common troubleshooting
technique, recommended by Apple when you have problems running an application.
This script does not modify the EXTFS 10 software in any way.

Before running it, you must have EXTFS 10 already installed, and the installer
file "extmac10_trial.dmg" mounted. If you no longer have it, you can download
it from the Paragon Software website. Your admin password will be required to
install the refresh scripts.

To completely uninstall, manually trash these files:
/Library/LaunchDaemons/com.paragon.extfs10.refresh.plist
/Library/Application Support/Paragon Software/extfs10refresh.sh
/Library/Application Support/Paragon Software/postflightinit10

This script is provided to you as a gift, and is for educational purposes only!
It is not authorized or endorsed by Paragon Software. There is no guarantee that
it won't cause damages, including loss of data. You run it solely at your own
risk. Do not run this script if doing so would violate your local laws.

EOF

while true; do
    read -p "Do you wish to install the scripts? " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# check that the installer is mounted, and extfs10 is already installed
if [ ! -f '/Volumes/ParagonFS.localized/FSInstaller.app/Contents/Resources/Paragon ExtFS for Mac.pkg' ]
    then
        echo "Error: Paragon EXTFS 10 installer (extmac10_trial.dmg) must be mounted." 1>&2
        exit 1
    fi
if [ ! -f '/Library/Application Support/Paragon Software/extfs210' ]
    then
        echo "Error: Paragon EXTFS 10 must be installed first." 1>&2
        exit 1
fi

# make a temporary folder
mkdir /tmp/paragon_refresh_$$
cd /tmp/paragon_refresh_$$

# extract the "postflightinit" file from the installer dmg and rename it
xar -xf '/Volumes/ParagonFS.localized/FSInstaller.app/Contents/Resources/Paragon ExtFS for Mac.pkg'
cat ExtFS.pkg/Scripts | gunzip -dc | cpio -i --quiet
mv postflightinit postflightinit10

# create the refresh shell script
cat << EOF > extfs10refresh.sh
#!/bin/sh
# refresh the EXTFS 10 installation.
# This file is NOT provided by Paragon Software.
# requires "postflightinit10", from EXTFS 10 installer dmg "postflightinit".
rm '/Library/Application Support/Paragon Software/extfs210'
'/Library/Application Support/Paragon Software/postflightinit10'
EOF
chmod 744 extfs10refresh.sh

# create the launchd plist to run the script once a week
cat << EOF > com.paragon.extfs10.refresh.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<!-- This file is NOT provided by Paragon Software -->
<dict>
    <key>Label</key>
    <string>com.paragon.extfs10.refresh</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Library/Application Support/Paragon Software/extfs10refresh.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>604800</integer>
</dict>
</plist>
EOF


# move files into place, check for errors

if ! sudo -p "Please enter your admin password:" chown root com.paragon.extfs10.refresh.plist
then
    echo "Error: could not set ownership of plist file. The scripts were not installed." 1>&2
    rm -rf /tmp/paragon_refresh_$$
    exit 1
fi

if ! sudo mv com.paragon.extfs10.refresh.plist /Library/LaunchDaemons
then
    echo "Error: could not install plist file. The scripts were not installed" 1>&2
    rm -rf /tmp/paragon_refresh_$$
    exit 1
fi

sudo rm -f /Library/LaunchAgents/com.paragon.extfs*.plist
rm -f '/Library/Application Support/Paragon Software/postflightinit10'
rm -f '/Library/Application Support/Paragon Software/extfs'*

if ! mv postflightinit10 '/Library/Application Support/Paragon Software/'
then
    echo "Error: could not install postflightinit file. The scripts were not installed." 1>&2
    rm -rf /tmp/paragon_refresh_$$
    sudo rm /Library/LaunchDaemons/com.paragon.extfs10.refresh.plist
    exit 1
fi

if ! mv extfs10refresh.sh '/Library/Application Support/Paragon Software/'
then
    echo "Error: could not install shell script file. The scripts were not installed." 1>&2
    rm -rf /tmp/paragon_refresh_$$
    sudo rm /Library/LaunchDaemons/com.paragon.extfs10.refresh.plist
    rm '/Library/Application Support/Paragon Software/postflightinit10'
    exit 1
fi

# successfully installed, delete the temporary folder
rm -rf /tmp/paragon_refresh_$$

echo "EXTFS 10 refresh scripts were installed, please restart your computer."
exit 0
