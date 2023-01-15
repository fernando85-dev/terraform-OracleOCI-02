resource "oci_core_instance" "dev-oke-lacadordigital" {
    # Required
    availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
    #availability_domain = "dLjn:SA-SAOPAULO-1-AD-1"
    compartment_id = "ocid1.compartment.oc1..aaaaaaaaqo33regselc7io6torett3usrckxzxfgsmbi6z35kw4gjfug73na"
    shape = "VM.Standard.E2.1.Micro"

    source_details {
        source_id = "ocid1.image.oc1.sa-vinhedo-1.aaaaaaaap52b2aqfnl7hdlgfou3dhzv65a7ovfb4beoyzznaklnjcyn2wg2q"
        source_type = "image"
    }
    metadata = {
        ssh_authorized_keys = file("~/.ssh/ssh-infra-oci-lacadordigital.pub")
    }
    preserve_boot_volume = false
}