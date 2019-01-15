# Build Bash for Android

A script that patches & cross-compiles bash for Android

## Prerequisites

* Linux or Linux WSL on W10 (tested on Ubuntu WSL on W10 Pro)
* GNU Make
* Common sense

## Compile

	$ git clone ...
  $ ./build-bash.sh <options>

## Notes

  The android patches are for bash 4.4-23 and 5.0 stable. If you're compiling any other version of bash, make sure the patch files are targeting the correct lines (use check argument)
  
  If building fails, you likely need to add/remove/modify patches. Just place the patches in the patches folder and the script will apply them

## Issues

  Arm64 always compiles with dynamic linker (/lib/ld-linux-aarch64.so.1) for reasons unknown and so won't work
  
## Credits

* [GNU](https://www.gnu.org/software/bash/)
* [BlissRoms](https://github.com/BlissRoms/platform_external_bash/)
* [ATechnoHazard and koro666](https://github.com/ATechnoHazard/bash_patches)
* [Alexander Gromnitsky](https://github.com/gromnitsky/bash-on-android)
  
## License

  MIT
