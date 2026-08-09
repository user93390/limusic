# Release build script for GitHub Actions.

export def main [tag: string, --os: string = "linux", --dry-run = false] {
    let repo_root = $env.PWD

    print $"==> Release pipeline: ($tag) on ($os)"

    let config = (open ($repo_root | path join "src-tauri/tauri.conf.json"))
    let version = $config.version

    if ($version == null or $version == "") {
        error make --unspanned { msg: "no version in tauri.conf.json" }
    }

    if $"v($version)" != $tag {
        error make --unspanned { msg: $"tag ($tag) doesn't match version ($version)" }
    }

    setup_env $repo_root
    build_bundle $repo_root $os

    if $dry_run {
        print "dry_run — build complete, not uploading"
        return { version: $version, tag: $tag, os: $os, artifacts: [] }
    }

    let artifacts = discover_artifacts $repo_root $os $version
    print $"artifacts: ($artifacts | to json)"

    { version: $version, tag: $tag, os: $os, artifacts: $artifacts }
}

def setup_env [repo_root: string] {
    let env_file = ($repo_root | path join ".env.build")
    let key = ($env.TAURI_SIGNING_PRIVATE_KEY_FILE? | default ($env.HOME | path join ".tauri/limusic.key"))

    if not ($key | path exists) {
        print "::warning::signing key not found"
        return
    }

    let key_password = ($env.TAURI_SIGNING_PRIVATE_KEY_PASSWORD? | default "")

    {
        TAURI_SIGNING_PRIVATE_KEY: (open $key),
        TAURI_SIGNING_PRIVATE_KEY_PASSWORD: $key_password,
    } | save -f $env_file
}

def build_bundle [repo_root: string, os: string] {
    let bundle = (match $os {
        "linux" => "appimage",
        "windows" => "msi,nsis",
        "mac" => "app",
        _ => { error make --unspanned { msg: $"unknown os: ($os)" } }
    })

    print $"Building ($bundle)..."
    cargo tauri build --bundles $bundle
}

def discover_artifacts [repo_root: string, os: string, version: string] {
    match $os {
        "linux" => {
            let appimage = ((ls ($repo_root | path join $"target/release/bundle/appimage/limusic_($version)_*.AppImage")
                | get 0 | get name) // "")

            if $appimage == "" {
                error make --unspanned { msg: $"no AppImage for ($version)" }
            }

            [{ type: "appimage", path: $appimage, sig: $"($appimage).sig" }]
        },
        "windows" => {
            let nsis = ($repo_root | path join $"target/release/bundle/nsis/limusic_($version)_x64-setup.exe")
            let msi = ((ls ($repo_root | path join $"target/release/bundle/msi/limusic_($version)_*.msi")
                | get 0 | get name) // "")

            [{ type: "nsis", path: $nsis, sig: $"($nsis).sig" }, { type: "msi", path: $msi }]
        },
        "mac" => {
            let app = ((ls ($repo_root | path join "target/release/bundle/app/limusic.app")
                | get 0 | get name) // "")

            [{ type: "app", path: $app }]
        },
        _ => {
            error make --unspanned { msg: $"unsupported: ($os)" }
        }
    }
}
