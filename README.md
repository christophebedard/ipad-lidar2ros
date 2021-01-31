# ipad-lidar2ros

Publish iPad Pro LiDAR data & more in ROS 2.

This repository only contains the source code.
To run it, set up an Xcode project and import the source code.

<!-- TODO link to app on the App Store once it's published -->

<!-- TODO add screenshot/demo -->

## Using the app

Display a simple help page in the app by pressing the help button in the lower right corner.

<!-- TODO add more info, link to ros2-web-bridge -->

<!-- TODO add table with all the types of data that the app can publish -->

## Modifying the app icon

The source file for the app icon is [`lidar2ros_appicon.psd`](./lidar2ros_appicon.psd).
Modify it using your favourite PSD-compatible editor (e.g. [Photopea](https://www.photopea.com)), then export the necessary PNGs.

Make sure [`brew`](https://brew.sh) is installed, then install `imagemagick`.

```zsh
% brew install imagemagick
```

To simply export the PSD file to a PNG:

```zsh
% convert 'lidar2ros_app_logo.psd[0]' -resize 167x167 logo.png
```

Xcode requires various sizes for the app icon.
Run the provided script to generate them all:

```zsh
% ./gen_appicon_assets.sh
```
