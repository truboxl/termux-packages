TERMUX_SUBPKG_DESCRIPTION="Common files for zig"
TERMUX_SUBPKG_DEPEND_ON_PARENT=false
TERMUX_SUBPKG_PLATFORM_INDEPENDENT=true
TERMUX_SUBPKG_BREAKS="zig (<< 0.17.0-1)"
TERMUX_SUBPKG_REPLACES="zig (<< 0.17.0-1)"

# lib/zig/doc/langref.html is different for each build
TERMUX_SUBPKG_INCLUDE="
lib/zig/lib
lib/zig/LICENSE
lib/zig/README.md
"
