stzcli() {
  if ! command -v docker &>/dev/null; then
    echo "stzcli requires docker"
    return 1
  fi

  docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "$PWD":/workspace \
    -w /workspace \
    ghcr.io/sebastienfi/structurizr-cli-with-bonus:latest \
    structurizr "$@"
}
