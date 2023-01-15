#Source from https://registry.terraform.io/providers/hashicorp/oci/latest/docs/data-sources/identity_availability_domains

data "oci_identity_availability_domains" "ads" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaaktdirjeqe6r7hn2t75qaixaomhig4qqaiqumup3qc3pjpofxi5zq"
}