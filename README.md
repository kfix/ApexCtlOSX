ApexCtl for OSX
----
Lightweight alternative to the SteelSeries Engine keyboard configurator for Apex keyboards.  

based on [tuxmark5/ApexCtl](http://github.com/tuxmark5/ApexCtl)

Install
----
```bash
make
make install
```

Usage
----
Run `apexctl -h` for some options. The .plist file can auto-set these for you whenever the keyboard is plugged in.

You should also install tekezo/Seil and tekezo/Karabiner to remap the extra keys.
After `apexctl -rawkeys`, they can now grab the 2 new arrow keys, the Win9x "Properties" key, and L1-L4.  

ToDo
--
* Something in IOUSBHIDDriver.kext is blocking the 22 extra MX & M keys, although user-land can grab those via the IOHIDManager API.  
* apexctl:
  *  Support passing raw bytes for more fuzz-testing
  *  Support passing arbitrary color map
