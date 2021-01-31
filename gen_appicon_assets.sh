#!/bin/sh
# Generate all appicon image formats

# Source file for the appicon
appicon_source_file="lidar2ros_appicon.psd"
# Directory containing the assets
appicon_assets_directory="./Assets.xcassets/AppIcon.appiconset/"

do_convert()
{
    local id=$1
    local size=$2
    local filepath="${appicon_assets_directory}/appicon-${id}-${size}.png"
    # Delete if it exists
    rm -f ${filepath}
    # Generate using '[0]' to get a flattened output
    convert "${appicon_source_file}[0]" -resize "${size}x${size}" ${filepath}
}

# Formats/sizes are taken from the appicon page in the Xcode project
#   ipad-lidar2ros > Assets.xcassets > AppIcon

# iPhone Notification
do_convert iphone-notification 40
do_convert iphone-notification 60
# iPhone settings
do_convert iphone-settings 58
do_convert iphone-settings 87
# iPhone Spotlight
do_convert iphone-spotlight 80
do_convert iphone-spotlight 120
# iPhone App
do_convert iphone-app 120
do_convert iphone-app 180
# iPad Notifications
do_convert ipad-notifications 20
do_convert ipad-notifications 40
# iPad Settings
do_convert ipad-settings 29
do_convert ipad-settings 58
# iPad Spotlight
do_convert ipad-spotlight 40
do_convert ipad-spotlight 80
# iPad App
do_convert ipad-app 76
do_convert ipad-app 152
# iPad Pro (12.9-inch) App
do_convert ipad-pro-12p9-app 167
# App Store
do_convert app-store 1024
