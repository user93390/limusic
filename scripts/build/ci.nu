# Builds all supported binaries (Based on operating system).

def main [] {
    let os: string = sys host | get name

    let is_linux: bool = $os | str contains --ignore-case 'Linux'
    let is_mac: bool = $os | str contains --ignore-case 'macOS'
    let is_windows: bool = $os | str contains --ignore-case 'Windows'

    if (which cargo | is-empty) {
        print "Cargo must be installed to properly run ci actions."
        exit 1
    }

    # Load signing key from file only if env var not set
    if ($env.TAURI_SIGNING_PRIVATE_KEY? | is-empty) {
        let key = ($env.HOME | path join ".tauri/limusic.key")
        if ($key | path exists) {
            $env.TAURI_SIGNING_PRIVATE_KEY = (open $key)
            $env.TAURI_SIGNING_PRIVATE_KEY_PASSWORD = ($env.TAURI_SIGNING_PRIVATE_KEY_PASSWORD? | default "")
        }
    }

    if ($is_linux) {
        build_linux
        return
    }

    if ($is_mac) {
        build_mac
        return
    }

    if ($is_windows) {
        build_windows
        return
    }
}

# Builds:
# - deb
# - rpm
def build_linux [] {
    print sys host | hostname

    cargo tauri build --bundles rpm,deb
}

# Builds:
# - exe
# - msi
def build_windows [] {
    let host = sys host | hostname
    print "Building Windows on ($host)"

    cargo tauri build --bundles msi,nsis
}

# Builds:
# - app
def build_mac [] {
    let host = sys host | hostname
    print "Building Macos on ($host)"

    cargo tauri build --bundles app
}