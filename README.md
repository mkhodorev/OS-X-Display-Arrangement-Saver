OS-X-Display-Arrangement-Saver
==============================

Simple console tool for saving and restoring display arrangement on OS X.

For doing it, the tool uses serial numbers for the displays and not the IDs that OS X assigns to them.

[Download tool](https://github.com/oscii/OS-X-Display-Arrangement-Saver/releases)

#### Usage 

`da help` - prints help text <br />
`da list` - prints a list of all connected screens <br />
`da save <path_to_plist>` - saves current display arrangement to file <br />
`da load <path_to_plist>` - loads display arrangement from file <br />
If `<path_to_plist>` is not specified - the default is used: '~/Desktop/ScreenArrangement.plist'

#### Note
This fixes Y-axis arrangement and includes some work to ensure non-edid displays work, too
