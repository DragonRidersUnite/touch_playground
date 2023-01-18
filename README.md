# DragonRuby GTK Touch Playground

Collection of demos for using `args.inputs.touch` (or just `args.inputs.mouse`) for making mobile games with DRGTK.

Built with DRGTK v4.1 Pro. Uses portrait & allscreen functions.

Replace `mygame` in the DRGTK engine folder with this repository.

A note on the state of the code: it's a sloppy mess and all contained in `app/main.rb`. This is a learning ground with no standards.

## Deploying to Mobile

- Set up iOS & Android for developing with DRGTK w/ proper certs and keystores and such
- Add in `metadata/ios_metadata.txt`
- iOS deploys: `$wizards.ios.start env: :hotload`
- Android deploys:

```
./dragonruby-publish --package-with-remote-hotload
adb install builds/dr-touch-playground-android.apk
```

## Recovering from Exceptions on Remote Device

The game starts up a server on `9001` on the device it's deployed to, so you can access via `DEVICE_IP:9001` in your browser and run commands. This usually works for recovering and getting hotloading working again:

```
$gtk.reset
# save a file
$gtk.console.hide
```
