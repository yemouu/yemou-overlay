# haiku
Random ebuilds for

Wacky experiments and

Updated ebuilds

# info
Some ebuilds here are just bumped from a previous version in ::gentoo. These ebuilds have most
likely been held back for a reason. Use are your own risk.

Other ebuilds are here for trying new things.

# how to use
Run the following commands (the first one can be skipped if eselect-repository is already installed):
```sh
emerge -an app-eselect/eselect-repository

eselect repository add yemou-overlay git https://gitlab.com/yemou/yemou-overlay

emaint sync -r yemou-overlay
```
