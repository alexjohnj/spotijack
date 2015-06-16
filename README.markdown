# Spotijack

Spotijack is a program for OS X that helps record songs playing in
[Spotify][spotify-site] using [Audio Hijack Pro][audio-hijack-pro]. It uses
AppleScript to poll Spotify every 100 ms for track changes and to control Audio
Hijack Pro. When the current playing track changes, Spotijack starts a new
recording in Audio Hijack Pro and updates as much metadata as it can for the
current track.

Originally Spotijack was just a simple AppleScript I wrote one afternoon. Over
the years however, I've rewritten Spotijack as a native Cocoa application using
the [ScriptingBridge][scriptingbridge-framework-link] framework. I don't use
the program any more but it's a fun little side-project to work on.

[spotify-site]: http://spotify.com 
[audio-hijack-pro]: http://rogueamoeba.com/legacy/

## Piracy

Obviously this program enables music piracy which I don't like. I have thought
about _not_ releasing Spotijack because of this but, to put it bluntly, I
wanted to show off what I've made. In addition, I figured pirating music
through Spotijack is pretty inefficient so I'm kinda hoping this program won't
get used too much.

[scriptingbridge-framework-link]: https://developer.apple.com/library/mac/documentation/ScriptingAutomation/Reference/ScriptingBridgeFramework/

## Requirements

Spotijack only runs on Mac OS 10.10 or greater. It needs a licensed copy of
Audio Hijack Pro (that's version 2, not 3) and any version of Spotify. It
probably also needs a premium Spotify account as it makes no attempt to
distinguish between adverts and songs. 

## Usage

On first launch, Spotijack will handle creating a recording session in Audio
Hijack Pro as well as setting up Audio Hijack Pro and Spotify for scripting.
All you really need to do is start playing a song in Spotify and hit the record
button.

## Building

Spotijack uses CocoaPods to manage dependencies (there's only one). Before
opening the Xcode project, be sure to run `pod install` to get the
dependencies. 

Spotijack is written in Objective-C. I would really like to rewrite this in
Swift but, in 10.10 at least, the ScriptingBridge framework is almost totally
incompatible with Swift. You can get it working with Swift using some trickery
in the generated scripting headers but it's a horrible mess (I gave up half-way
through a Swift rewrite in early 2015). Maybe things will be better with OS
10.11 and/or Swift 2.

## Old Versions

I have included the original AppleScript versions in the `legacy` directory.
There's a changelog available in the `changelog.md` file. It's pretty sparse
since I didn't consider releasing this until recently. 

## License

Spotijack is licensed under the MIT license.
