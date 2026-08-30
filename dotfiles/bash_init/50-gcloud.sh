setpath -er GCLOUD_SDK_ROOT ~/.local/opt/google-cloud-sdk || return 0

sourcepath "${GCLOUD_SDK_ROOT}/path.bash.inc"
sourcepath "${GCLOUD_SDK_ROOT}/completion.bash.inc"
