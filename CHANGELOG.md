# Changelog

## 1.0.0 (2025-05-29)

* (maint) Pin to puppet-openvox_bootstrap < 1.0 via the forge
* (maint) Tighten license to AGPL 3
* (maint) Add redhat-rpm-config for el openvox_agent_acceptance
* (maint) Call apt update in pr_testing github workflow
* (gha-19) Ensure install_openvox#openvox_artifacts_url is respected
* (maint) Switch to voxpupuli/puppet-openvox_bootstrap
* (maint) Update overlookinfratech references to voxpupuli
* (maint) Float puppet-openvox_bootstrap on v0 tag
* (maint) Update openvox_bootstrap to puppet-openvox_bootstrap
* (plans,terraform) Check for valid ipv4 addresses in cluster
* (terraform) Only cloud-init network configure debian/ubuntu
* (plans) Mutate platform string to 'el' for alma/rocky for beaker
* (maint) Take just major version number for non ubuntu platform strings
* (plans) Retry terraform until we get valid ipv4 addresses
* (gha) Adds gha testing form almalinux 8, 9
* (os) Add almalinux 8, 9 support
* (gha) Test rocky 9 in gha plan_testing workflow
* (os) Add support for Rocky 8, 9
* (plans,gha) Add debian-13 pre-release test to beaker workflow
* (plans) Improve lookup_platform plan to handle debian pre-release
* (maint) Change get_os_version_name to translate version and codename
* (tasks) Fail download_image task for 400+ http responses
* (plans,gha) Thread an os_spec type through action and plans
* (os) Add a function to get normalized arch value for os
* (os) Provide pre-release and historical image url generation
* (os) Add codename resolution for debian 13 -> trixie
* (plans,gha) Simplify cluster_id
* (os) Add debian-13 as an allowed platform.
* (os) Add support for Debian 10, 11 and 12
* (plans) Add a function validate a set of openvox_install_params
* (plans) Add some puppet types to help manage install parameters
* (gha) Add a debug flag to action.yaml
* (gha) Adds a test of dev::openvox_agent_acceptance plan to gha
* (gha) Add standup_cluster ssh parameters to action.yaml
* (plans) Refactor with a task to add ssh public keys
* (plans) Add flag to allow host root access to cluster vms
* (plans) Rename setup_inter_cluster_ssh plan to setup_cluster_ssh
* (gha) Set setup_inter_cluster_root_ssh=true in action.yaml
* (plans) Add a dev plan to generate a beaker host file from inventory
* (gha) Add GHA composite-action to standup a cluster
* (plans) Plumb root_access flag through to setup_inter_cluster_ssh plan
* (plans) Add a dev plan to test running the openvox-agent acceptance
* (plans) Add a subplan to lookup target platform from facts
* (plans) Setup root access in setup_inter_cluster_ssh plan
* (plans) Add a subplan to setup inter vm ssh communication in a cluster
* (tasks) Add a task to generate an ssh keypair
* (net) Simplify vm domain to just 'vm'
* (plans) Add type and functions to support general vm specification
* (tf) Parameterize the libvirt uri for the terraform provider
* (plans,tf) Allow a primary count of 0
* (plans) Make installation of the openvox packages conditional
* (gha) Run the standup_cluster plan on a gha runner
* (plans) Turn off qemu security_driver in test vm
* (plans) Set path to private key explicitly in inventory
* (plans) Differentiate between pool name and path
* (tasks) Allow create pool task to generate pools with arbitrary paths
* (tf) Plumb a cpu_mode parameter through to the terraform vm module
* (libvirt) Modify libvirt_wrapper.create_pool to use permission defaults
* (plans) Add a plan for nested virtualization testing
* (doc) Add genisoimage to reqs
* (tf) Ensure that the user_password variable defaults to ''
* (plans) Ensure image_download_dir is created
* (gha) Add a github action workflow for pr testing
* (plans) Add a simple plan to teardown a cluster
* (plans) Add a subplan to install puppet on the cluster
* (bolt) Retrieve bolt inventory from a given terraform state file
* (plans) Add a subplan to manage download and import of base images
* (tasks) Add a task to create libvirt image pools
* (tasks) Add a bolt task to import a libvirt volume
* (tasks) Add a client library for using libvirt in tasks
* (tasks) Add a task to download a base image from a given url
* (tasks) Add a lib for common ruby open3 usage in tasks
* (bolt) Add a bolt-project.yaml and supporting configuration
* (tf) Remove libvirt pool/baseimage import from terraform manifests
* (puppet) Add a Puppet platform function generate platform strings
* (puppet) Add a puppet function to generate platform image urls
* (puppet) Add helper functions to translate ubuntu versions to codenames
* (rspec) Add rspec-puppet plumbing
* (tf/ci) Output ip addresses of the domains
* (tf) Move libvirt_pool management to root main.tf
* (tf) Add main.tf for primary and agents using the vm module
* (tf) Move vm manifest into its own module
* (tf/ci) Use cloud-init terraform templatesin main.tf
* (tf/ci) Rename cloud-init config as terraform templates
* (bolt) Beginings of a Bolt plan for standing up a cluster
* Get cloud-init network config working with terraform/dhcp
