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

    # Strip leading 'v' from tag if present, so both 'v0.3.11' and '0.3.11' work
    let tag_version = ($tag | str replace --regex "^v" "")
    if ($tag_version == "") {
        error make --unspanned { msg: "tag is empty" }
    }

    if $version != $tag_version {
        error make --unspanned { msg: $"tag ($tag) doesn't match version ($version)" }
    }

    setup_env

    print "Release env ready. Version: ($version)"
}

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

    {
        TAURI_SIGNING_PRIVATE_KEY: $key_content,
        TAURI_SIGNING_PRIVATE_KEY_PASSWORD: $key_password,
    } | save -f ".env.release"

    print "Written .env.release"
}