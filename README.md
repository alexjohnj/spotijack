# Spotijack (Experimental Recording Branch)

Spotijack is a macOS application that records songs playing in Spotify. This
branch contains a version of Spotijack that does not depend on Audio Hijack Pro
which means it can run on macOS 10.15 Catalina.

To use this version of Spotijack, you'll need to set up a local loopback device
that can be the output device for Spotify and the input device for Spotijack.

To compile this version of Spotijack, you will need to be using at least Xcode
12 Beta 2.

This version of Spotijack has several limitations compared to the master version
including:

- No control over the recording format (M4A files containing ALAC encoded audio
  only).
- No control over file naming (but the default naming is sensible).
- Lots of potential for funky audio glitches (since I'm no where near as
  experienced with audio programming as the Rouge Amoeba folks).

## Piracy

This is a fun side-project I made which I've used to develop my skills
(AppleScript, some advanced Objective-C and Swift, unit testing). I've published
it to showcase my development skills. I'm assuming nobody's going to actually
use Spotijack because there are _far_ more efficient ways of getting music. I'm
not publishing binaries to discourage people from using Spotijack.

## Requirements

Spotijack requires macOS 10.15 and a local loopback audio device. You (probably)
need a premium Spotify account since Spotijack makes no attempt to distinguish
between adverts and songs.

## Usage

Launch Spotijack, select the input device it should record from and then click
record.

If recording is ending immediately after starting, check the console for a
logged error.

## Building

Spotijack requires Xcode 12 Beta 2 to build. You should do a release build
because the optimisations provide a nice reduction in CPU usage.

## Implementation

Spotijack is the perfect example of an over engineered side project. Spotijack
is split into two parts, the GUI application _Spotijack_ and the library
_LibSpotijack_.

_LibSpotijack_ contains the core recording and application management logic. It
features a suite of unit tests (unit, not integration!) and, in theory, can be
used in other applications. _Spotijack_ is really just a GUI wrapper around
_LibSpotijack_.

_LibSpotijack_ doesn't do anything fancy to track recordings. It communicates
with Spotify and Audio Hijack Pro using the [ScriptingBridge
framework][scriptingbridge-framework-link] which is _so_ much fun to work with
in Swift (or Objective-C for that matter). _LibSpotijack_ just polls Spotify to
see if the current track has changed and if it has, it starts a new recording in
Audio Hijack Pro. Nothing fancy.

[scriptingbridge-framework-link]: https://developer.apple.com/library/mac/documentation/ScriptingAutomation/Reference/ScriptingBridgeFramework/

## Old Versions

Originally Spotijack was just a simple AppleScript I wrote one afternoon. Over
the years however, I've rewritten Spotijack as a native Cocoa application using
the [ScriptingBridge][scriptingbridge-framework-link] framework.

I have included the original AppleScript versions in the `Legacy` directory.
There's a changelog available in the `changelog.md` file. It's pretty sparse
since I didn't consider releasing this until 2015.

## License

Spotijack is licensed under the MIT license.
