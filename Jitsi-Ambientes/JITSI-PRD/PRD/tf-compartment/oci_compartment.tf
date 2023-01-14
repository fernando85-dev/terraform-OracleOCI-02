resource "oci_identity_compartment" "tf-compartment" {
    # Required
    compartment_id = "ocid1.tenancy.oc1..aaaaaaaaktdirjeqe6r7hn2t75qaixaomhig4qqaiqumup3qc3pjpofxi5zq"
    description = "Compartment for Terraform resources."
    name = "DEV"
}