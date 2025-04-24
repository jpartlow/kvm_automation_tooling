# Validates the given set of OpenVox install parameters and raises
# an error for any problems.
#
# If we're installing a released version, then collection will be
# matched to version. If collection does not exist, an error will be
# raised.
#
# If we're installing a pre-release version, then the version
# must be explicit, not 'latest', and collection is ignored.
#
# @return Kvm_automation_tooling::Openvox_install_params with
#   openvox_collection updated to match version as necessary.
function kvm_automation_tooling::validate_openvox_version_parameters(
  Kvm_automation_tooling::Openvox_install_params $params,
) >> Kvm_automation_tooling::Openvox_install_params {
  $released = $params['openvox_released']
  $version = $params['openvox_version']
  $collection = $params['openvox_collection']

  if $released {
    # Collection must match version
    $major_version = $version.split('\.')[0]
    $collection_version = $collection.split('openvox')[1]
    if $version != 'latest' and ($major_version != $collection_version) {
      $matched_collection = "openvox${major_version}"
      if $matched_collection !~ Kvm_automation_tooling::Openvox_collection {
        fail(@("EOS"/L))
          Version '${version}' suggests a collection \
          '${matched_collection}' that does not exist. \
          Valid collections: \
          ${Kvm_automation_tooling::Openvox_collection}.
          |- EOS
      } else {
        log::warn(@("EOS"/L))
          OpenVox collection '${collection}' does not match version \
          '${version}'. Using '${matched_collection}' instead.
          |- EOS
      }
    } else {
      $matched_collection = $collection
    }
  } else {
    # Version cannot be latest
    if $version == 'latest' {
      fail_plan(@("EOS"/L))
        You must supply an explicit version, not 'latest', when \
        installing a pre-release version.
        |- EOS
    }
    $matched_collection = $collection
  }

  $result = $params + {
    'openvox_collection' => $matched_collection,
  }

  return $result
}
