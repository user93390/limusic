# Release preparation script: validates version, sets up env for cargo.
# Usage: nu scripts/build/release.nu --tag v0.3.0 --os linux

export def main [tag: string, --os: string = "linux"] {
    print $"==> Release prep: ($tag) on ($os)"

    let repo_root = $env.PWD

    # Validate version matches tag
    let config = (open ($repo_root | path join "src-tauri/tauri.conf.json"))
    let version = $config.version

    if ($version == null or $version == "") {
        error make --unspanned { msg: "no version in tauri.conf.json" }
    }

    if $"v($version)" != $tag {
        error make --unspanned { msg: $"tag ($tag) doesn't match version ($version)" }
    }

    setup_env

    print "Release env ready. Version: ($version)"
}
 # Support both direct key (GitHub Actions) and key file (local dev)
def setup_env [] {
    let key_content = if not ($env.TAURI_SIGNING_PRIVATE_KEY? | is-empty) {
        $env.TAURI_SIGNING_PRIVATE_KEY
    } else if not ($env.TAURI_SIGNING_PRIVATE_KEY_FILE? | is-empty) {
        let key_file = ($env.TAURI_SIGNING_PRIVATE_KEY_FILE | path expand)
        if not ($key_file | path exists) {
            print "::warning::signing key not found"
            return
        }
        open $key_file
    } else {
        print "::warning::no signing key configured"
        return
    }

    let key_password = ($env.TAURI_SIGNING_PRIVATE_KEY_PASSWORD? | default "")

    # Write to .env for cargo to pick up after this script exits
    {
        TAURI_SIGNING_PRIVATE_KEY: $key_content,
        TAURI_SIGNING_PRIVATE_KEY_PASSWORD: $key_password,
    } | save -f ".env.release"

    print "Written .env.release"
}