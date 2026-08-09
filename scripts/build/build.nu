# Builds an rpm package of the entire app.

def main [args?: list<string>, notes: string = "See the commit history for changes."]  {
    let repo_root = $env.PWD

    let repo = "SimoHypers/limusic"
    let key = ($env.TAURI_SIGNING_PRIVATE_KEY_FILE? | default  ($env.HOME | path join ".tauri/limusic.key"))

    let config = open ($repo_root | path join "src-tauri/tauri.conf.json")
    let version = $config.version

    if ($version == null or $version == "") {
        print "no version in tauri.conf.json"
        exit 1
    }

    let tag = $"v($version)"
    print $"==> Releasing ($tag)"

    if not ($key | path exists) {
        print $"signing key not found at ($key)"
        exit 1
    }

    print $repo_root

    $env.TAURI_SIGNING_PRIVATE_KEY = (open $key)
    $env.TAURI_SIGNING_PRIVATE_KEY_PASSWORD = ($env.TAURI_SIGNING_PRIVATE_KEY_PASSWORD? | default "")

    print "==> Building the rpm…"

    cargo tauri build --bundles rpm

    let rpm = (ls ($repo_root | path join "target/release/bundle/rpm") | where name =~ $version | first 1).name

    if ($rpm == null) {
        print $"no rpm for ($version) in target/release/bundle/rpm"
        exit 1
    }

    mkdir ($repo_root | path join "target/release/bundle")

    let latest_json = {
        version: $version,
        notes: $notes,
        pub_date: (date now | format date "%Y-%m-%dT%H:%M:%SZ"),
        platforms: {}
    }

    $latest_json | save -f ($repo_root | path join "target/release/bundle/latest.json")

    let rpm_files = (ls ($repo_root | path join "target/release/bundle/rpm") | where name =~ $version)

    if ($rpm_files | is-empty) {
        print $"no rpm for ($version) in target/release/bundle/rpm"
        exit 1
    }

    let rpm = ($rpm_files | first 1).name

    print $rpm

    print $"===> Released ($tag) completed! <==="
}
