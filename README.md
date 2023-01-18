# DragonRuby GTK Touch Playground

Collection of demos for using `args.inputs.touch` (or just `args.inputs.mouse`) for making mobile games with DRGTK.

Built with DRGTK v4.1 Pro. Uses portrait & allscreen functions.

Replace `mygame` in the DRGTK engine folder with this repository.

## Deploying to Mobile

- Add in `metadata/ios_metadata.txt` with proper config
- Set up iOS & Android for developing with DRGTK
- iOS deploys: `$wizards.ios.start env: :hotload`
- Android deploys:

```
./dragonruby-publish --package-with-remote-hotload
adb install builds/dr-touch-playground-android.apk
```
