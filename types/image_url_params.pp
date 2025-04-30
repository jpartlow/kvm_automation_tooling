# Parameters defining additional information needed to construct a
# download URL for a base image.
#
# This is platform dependent and intended for downloading historical
# or pre-release builds.
#
# Keys:
# - image_version: Detailed version string.#   Ex:
#   * debian: '20240703-1797', 'daily-20240703-1797', 'daily-latest'
#   * ubuntu: '20250429'
#   * almalinux: '9.4-20240507'
#   * rocky: '9.5-20241118.0'
# - image_url_override: This is an escape hatch. If specified,
#   this must be the complete URL to a specific image to download.
type Kvm_automation_tooling::Image_url_params = Struct[{
  Optional[image_version]      => String[1],
  Optional[image_url_override] => Stdlib::HTTPUrl,
}]
