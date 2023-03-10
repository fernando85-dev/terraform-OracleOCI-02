# Variables
variable "compartment_id"   { type = string }
variable "vcn_display_name" { type = string }
#variable "vcn_dns_label"    { type = string }

variable "vnc_cidr_block" {
  type    = string
  default = "172.16.0.0.0/16"
}

variable "vnc_private_subnet_cidr_block" {
  type    = string
  default = "172.16.1.0/23"
}

variable "vnc_public_subnet_cidr_block" {
  type    = string
  default = "172.16.0.0/23"
}

variable "vcn_dns_label" {
  description = "A DNS label for the VCN, used in conjunction with the VNIC's hostname and subnet's DNS label to form a fully qualified domain name (FQDN) for each VNIC within this subnet"
  type        = string
  default     = "vcnmodule"

  validation {
  condition     = length(regexall("^[^0-9][a-zA-Z0-9_]+$", var.vcn_dns_label)) > 0
  error_message = "DNS label must be an alphanumeric string that begins with a letter."
  }
}

# Modules and Resources
module "vcn"{
  source                   = "oracle-terraform-modules/vcn/oci"
  version                  = "2.0.0"
  
  # Required
  compartment_id           = var.compartment_id
  region                   = var.region
  vcn_name                 = var.vcn_display_name
  vcn_dns_label            = var.vcn_dns_label

  # Optional
  #internet_gateway_enabled = true
  # Commented out for my free tier account.
  #nat_gateway_enabled      = true
  #service_gateway_enabled  = true
  vcn_cidr                 = var.vnc_cidr_block
}

resource "oci_core_subnet" "tf_vcn_private_subnet"{
  # Required
  compartment_id    = var.compartment_id
  vcn_id            = module.vcn.vcn_id
  cidr_block        = var.vnc_private_subnet_cidr_block

  # Optional
  route_table_id    = module.vcn.nat_route_id
  security_list_ids = [oci_core_security_list.tf_private_security_list.id]
  display_name      = "private-subnet"
}

resource "oci_core_subnet" "tf_vcn_public_subnet"{
  # Required
  compartment_id    = var.compartment_id
  vcn_id            = module.vcn.vcn_id
  cidr_block        = var.vnc_public_subnet_cidr_block

  # Optional
  route_table_id    = module.vcn.ig_route_id
  security_list_ids = [oci_core_security_list.tf_public_security_list.id]
  display_name      = "public-subnet"
}

resource "oci_core_security_list" "tf_private_security_list"{
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id
  display_name   = "security-list-for-private-subnet"

  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all" 
  }

  ingress_security_rules { 
    stateless   = false
    source      = var.vnc_cidr_block
    source_type = "CIDR_BLOCK"

    # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml TCP is 6
    protocol    = "6"
    tcp_options { 
      min = 22
      max = 22
    }
  }

  ingress_security_rules { 
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml ICMP is 1  
    protocol    = "1"

    # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
    icmp_options {
      type = 3
      code = 4
    } 
  }   
  
  ingress_security_rules { 
    stateless   = false
    source      = var.vnc_cidr_block
    source_type = "CIDR_BLOCK"
    # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml ICMP is 1  
    protocol    = "1"

    # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
    icmp_options {
      type = 3
    } 
  }
}

resource "oci_core_security_list" "tf_public_security_list"{
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id
  display_name   = "security-list-for-public-subnet"

  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all" 
  }

  ingress_security_rules { 
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml TCP is 6
    protocol    = "6"
    tcp_options { 
        min = 22
        max = 22
    }
  }

  # Example of adding ports 1521-1522.
  ingress_security_rules { 
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml TCP is 6
    protocol    = "6"
    tcp_options { 
        min = 1521
        max = 1522
    }
  }

  ingress_security_rules { 
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml ICMP is 1  
    protocol    = "1"

    # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
    icmp_options {
      type = 3
      code = 4
    } 
  }   
  
  ingress_security_rules { 
    stateless   = false
    source      = var.vnc_cidr_block
    source_type = "CIDR_BLOCK"
    # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml ICMP is 1  
    protocol    = "1"

    # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
    icmp_options {
      type = 3
    } 
  }

}

resource "oci_core_dhcp_options" "tf_dhcp_options"{
  # Required
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id

  #Options for type are either "DomainNameServer" or "SearchDomain"
  options {
    type        = "DomainNameServer"  
    server_type = "VcnLocalPlusInternet"
  }
  
  # Optional
  display_name = "default-dhcp-options"
}


# Outputs
output "vcn_id" {
  value = module.vcn.vcn_id
}

output "private_security_list_id" {
  value = oci_core_security_list.tf_private_security_list.id
}

output "public_security_list_id" {
  value = oci_core_security_list.tf_public_security_list.id
}

output "private_subnet_id" {
  value = oci_core_subnet.tf_vcn_private_subnet.id
}

#output "public_subnet_id" {
#  value = oci_core_subnet.tf_vcn_public_subnet.id
