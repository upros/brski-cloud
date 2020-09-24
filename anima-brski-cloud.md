---

title: "BRSKI Cloud Registrar"
abbrev: BRSKI-CLOUD
docname: draft-friel-anima-brski-cloud-03
category: std
ipr: trust200902

stand_alone: yes
pi: [toc, sortrefs, symrefs]

author:
 -
    ins: O. Friel
    name: Owen Friel
    org: Cisco
    email: ofriel@cisco.com
 -
    ins: R. Shekh-Yusef
    name: Rifaat Shekh-Yusef
    org: Auth0
    email: rifaat.s.ietf@gmail.com
 -
    ins: M. Richardson
    name: Michael Richardson
    org: Sandelman Software Works
    email: mcr+ietf@sandelman.ca

normative:
  RFC7030:
  RFC8366:
  I-D.ietf-anima-bootstrapping-keyinfra:

informative:
  RFC6125:
  IEEE802.1AR:
    target: "http://standards.ieee.org/findstds/standard/802.1AR-2018.html"
    title: "IEEE 802.1AR Secure Device Identifier"
    author:
      ins: "IEEE Standard"
    date: 2018

--- abstract

This document specifies the behaviour of a BRSKI Cloud Registrar, and how a
pledge can interact with a BRSKI Cloud Registrar when bootstrapping.

RFCED REMOVE: It is being actively worked on at https://github.com/anima-wg/brski-cloud

--- middle

# Introduction

Bootstrapping Remote Secure Key Infrastructures (BRSKI) {{I-D.ietf-anima-bootstrapping-keyinfra}} specifies automated bootstrapping of an Autonomic Control Plane.
BRSKI Section 2.7 describes how a pledge "MAY contact a well known URI of a cloud registrar if a local registrar cannot be discovered or if the pledge's target use cases do not include a local registrar".

This document further specifies use of a BRSKI cloud registrar and clarifies operations that are not sufficiently specified in BRSKI.

## Terminology

{::boilerplate bcp14}

This document uses the terms Pledge, Registrar, MASA, and Voucher from {{I-D.ietf-anima-bootstrapping-keyinfra}} and {{RFC8366}}.

- Local Domain: The domain where the pledge is physically located and bootstrapping from.
This may be different to the pledge owner's domain.

- Owner Domain: The domain that the pledge needs to discover and bootstrap with.

- Cloud Registrar: The default Registrar that is deployed at a URI that is well known to the pledge.

- Owner Registrar: The Registrar that is operated by the Owner, or the Owner's delegate.
There may not be an Owner Registrar in all deployment scenarios.

- Local Domain Registrar: The Registrar discovered on the Local Domain.
There may not be a Local Domain Registrar in all deployment scenarios.

## Target Use Cases

Two high level use cases are documented here.
There are more details provided in sections {{redirect2Registrar}} and {{voucher2EST}}.
While both use cases aid with incremental deployment of BRSKI infrastructure, for many smaller sites (such as teleworkers) no further infrastructure are expected.

The pledge is not expected to know which of these two situations it is in.
The pledge determines this based upon signals that it receives from the Cloud Registrar.
The Cloud Registrar is expected to make the determination based upon the identity presented by the pledge.

While a Cloud Registrar will typically handle all the devices of a particular product line from a  particular manufacturer there are no restrictions on how the Cloud Registrar is horizontally (many sites) or vertically (more equipment at one site) scaled.
It is also entirely possible that all devices sold by through a particular VAR might be preloaded with a configuration that changes the Cloud Registrar URL to point to a VAR.
Such an effort would require unboxing each device in a controlled environment, but the provisioning could occur using a regular BRSKI or SZTP {{?RFC8572}} process.

### Owner Registrar Discovery


A pledge is bootstrapping from a remote location with no local domain registrar (specifically: with no local infrastructure to provide for automated discovery), and needs to discover its owner registrar.
The cloud registrar is used by the pledge to discover the owner registrar.
The cloud registrar redirects the pledge to the owner registrar, and the pledge completes bootstrap against the owner registrar.

A typical example is an enduser deploying a pledge in a home or small branch office, where the pledge belongs to the enduser's employer.
There is no local domain registrar, and the pledge needs to discover and bootstrap with the employer's registrar which is deployed in headquarters.

### Bootstrapping with no Owner Registrar

A pledge is bootstrapping where the owner organization does not yet have an owner registrar deployed.
The cloud registrer issues a voucher, and the pledge completes trust bootstrap using the cloud registrar.
The voucher issued by the cloud includes domain information for the owner's EST {{RFC7030}} service the pledge should use for certificate enrollment.

In one use case, an organization has an EST service deployed, but does not have yet a BRSKI capable Registrar service deployed.
The pledge is deployed in the organizations domain, but does not discover a local domain, or owner, registrar.
The pledge uses the cloud registrar to bootstrap, and the cloud registrar provides a voucher that includes instructions on finding the organization's EST service.

# Architecture

The high level architecture is illustrated in {{architecture-figure}}.

The pledge connects to the cloud registrar during bootstrap.

The cloud registrar may redirect the pledge to an owner registrar in order to complete bootstrap against the owner registrar.

If the cloud registrar issues a voucher itself without redirecting the pledge to an owner registrar, the cloud registrar will inform the pledge what domain to use for accessing EST services in the voucher response.

Finally, when bootstrapping against an owner registrar, this registrar may interact with a backend CA to assist in issuing certificates to the pledge.
The mechanisms and protocols by which the registrar interacts with the CA are transparent to the pledge and are out-of-scope of this document.

The architecture shows the cloud registrar and MASA as being logically separate entities.
The two functions could of course be integrated into a single service.

[[TODO]] NONCE-less voucher.
If the Cloud Registrar issues a voucher directly, while it may include a nonce, because that nonce does not go through the Owner, which means that the MASA has no audit trail that the
pledge really connected to the Owner Registrar.

TWO CHOICES:
1. Cloud Registrar redirects to Owner Registrar
2. Cloud Registrar returns VOUCHER pinning Owner Register.

~~~
|<--------------OWNER------------------------>|     MANUFACTURER

 On-site                Cloud
+--------+                                         +-----------+
| Pledge |---------------------------------------->| Cloud     |
+--------+                                         | Registrar |
    |                                              +---+  +----+
    |                                                  |??|
    |                 +-----------+                +---+  +----+
    +---------------->|  Owner    |--------------->|   MASA    |
    |   VR-sign(N)    | Registrar |sign(VR-sign(N))+-----------+
    |                 +-----------+
    |                       |    +-----------+
    |                       +--->|    CA     |
    |                            +-----------+
    |
    |                 +-----------+
    +---------------->| Services  |
                      +-----------+
~~~
{: #architecture-figure title="High Level Architecture"}

## Interested Parties

1. OEM - Equipment manufacturer.  Operate the MASA.

2. Network operator. Operate the Owner Registrar.
Often operated by end owner (company), or by outsourced IT entity.

3. Network integrator. They operate a Cloud Registrar.


## Network Connectivity

The assumption is that the pledge already has network connectivity prior to connecting to the cloud registrar.
The pledge must have an IP address, must be able to make DNS queries, and must be able to send HTTP requests to the cloud registrar.
The pledge operator has already connected the pledge to the network, and the mechanism by which this has happened is out of scope of this document.

## Pledge Certificate Identity Considerations

BRSKI section 5.9.2 specifies that the pledge MUST send a CSR Attributes request to the registrar. The registrar MAY use this mechanism to instruct the pledge about the identities it should include in the CSR request it sends as part of enrollment.
The registrar may use this mechanism to tell the pledge what Subject or Subject Alternative Name identity information to include in its CSR request.
This can be useful if the Subject must have a specific value in order to complete enrollment with the CA.

For example, the pledge may only be aware of its IDevID Subject which includes a manufacturer serial number, but must include a specific fully qualified domain name in the CSR in order to complete domain ownership proofs required by the CA.

As another example, the registrar may deem the manufacturer serial number in an IDevID as personally identifiable information, and may want to specify a new random opaque identifier that the pledge should use in its CSR.

# Protocol Operation

## Pledge Requests Voucher from Cloud Registrar

### Cloud Registrar Discovery

BRSKI defines how a pledge MAY contact a well known URI of a cloud registrar if a local domain registrar cannot be discovered.
Additionally, certain pledge types may never attempt to discover a local domain registrar and may automatically bootstrap against a cloud registrar.

The details of the URI are manufacturer specific, with BRSKI giving the example "brski-registrar.manufacturer.example.com".

The Pledge SHOULD be provided with the entire URL of the Cloud Registrar, including the path component, which is typically "/.well-known/brski/requestvoucher", but may be another value.

### Pledge - Cloud Registrar TLS Establishment Details

The pledge MUST use an Implicit Trust Anchor database (see {{RFC7030}}) to authenticate the cloud registrar service.
The Pledge can be done with pre-loaded trust-anchors that are used to validate the TLS connection.
This can be using a public Web PKI trust anchors using {{RFC6125}} DNS-ID mechanisms, a pinned certification authority, or even a pinned raw public key.
This is a local implementation decision.

The pledge MUST NOT establish a provisional TLS connection (see BRSKI section 5.1) with the cloud registrar.

The cloud registrar MUST validate the identity of the pledge by sending a TLS CertificateRequest message to the pledge during TLS session establishment.
The cloud registrar MAY include a certificate_authorities field in the message to specify the set of allowed IDevID issuing CAs that pledges may use when establishing connections with the cloud registrar.

The cloud registrar MAY only allow connections from pledges that have an IDevID that is signed by one of a specific set of CAs, e.g. IDevIDs issued by certain manufacturers.

The cloud registrar MAY allow pledges to connect using self-signed identity certificates or using Raw Public Key {{?RFC7250}} certificates.

### Pledge Issues Voucher Request

After the pledge has established a full TLS connection with the cloud registrar and has verified the cloud registrar PKI identity, the pledge generates a voucher request message as outlined in BRSKI section 5.2, and sends the voucher request message to the cloud registrar.

## Cloud Registrar Handles Voucher Request

The cloud registrar must determine pledge ownership.
Once ownership is determined, or if no owner can be determined, then the registrar may:

- return a suitable 4xx or 5xx error response to the pledge if the registrar is unwilling or unable to handle the voucher request

- redirect the pledge to an owner register via 307 response code

- issue a voucher and return a 200 response code

### Pledge Ownership Lookup {#pledgeOwnershipLookup}

The cloud registrar needs some suitable mechanism for knowing the correct owner of a connecting pledge based on the presented identity certificate.
For example, if the pledge establishes TLS using an IDevID that is signed by a known manufacturing CA, the registrar could extract the serial number from the IDevID and use this to lookup a database of pledge IDevID serial numbers to owners.

Alternatively, if the cloud registrar allows pledges to connect using self-signed certificates, the registrar could use the thumbprint of the self-signed certificate to lookup a database of pledge self-signed certificate thumbprints to owners.

The mechanism by which the cloud registrar determines pledge ownership is out-of-scope of this document.

### Cloud Registrar Redirects to Owner Registrar

Once the cloud registar has determined pledge ownership, the cloud registrar may redirect the pledge to the owner registrar in order to complete bootstrap.
Ownership registration will require the owner to register their local domain.
The mechanism by which pledge owners register their domain with the cloud registrar is out-of-scope of this document.

The cloud registrar replies to the voucher request with a suitable HTTP 307 response code, including the owner's local domain in the HTTP Location header.

### Cloud Registrar Issues Voucher

If the cloud registrar issues a voucher, it returns the voucher in a HTTP response with a 200 response code.

The cloud registrar MAY issue a 202 response code if it is willing to issue a voucher, but will take some time to prepare the voucher.

The voucher MUST include the "est-domain" field as defined in [[TODO RFC draft needed ? ]].
This tells the pledge where the domain of the EST service to use for completing certificate enrollment.

The voucher MAY include the "additional-configuration" field as defined in [[ TODO RFC draft needed? ]].
This points the pledge to a URI where application specific additional configuration information may be retrieved.
Pledge and Registrar behavior for handling and specifying the "additional-configuration" field is out-of-scope of this document.

## Pledge Handles Cloud Registrar Response

### Redirect Response

The cloud registrar returned a 307 response to the voucher request.
The pledge should complete BRSKI bootstrap as per standard BRSKI operation after following the HTTP redirect.
The pledge should establish a provisional TLS connection with specified local domain registrar.
The pledge should not use its Implicit Trust Anchor database for validating the local domain registrar identity.
The pledge should send a voucher request message via the local domain registrar.
When the pledge downloads a voucher, it can validate the TLS connection to the local domain registrar and continue with enrollment and bootstrap as per standard BRSKI operation.

### Voucher Response

The cloud registrar returned a voucher to the pledge.
The pledge should perform voucher verification as per standard BRSKI operation.
The pledge should verify the voucher signature using the manufacturer-installed trust anchor(s), should verify the serial number in teh voucher, and must verify any nonce information in the voucher.

The pledge should extract the "est-domain" field from the voucher, and should continue with EST enrollment as per standard BRSKI operation.

# Protocol Details


## Voucher Request Redirected to Local Domain Registrar {#redirect2Registrar}

This flow illlustrates the Owner Registrar Discovery flow. A pledge is bootstrapping in a remote location with no local domain registrar.
The assumption is that the owner registrar domain is accessible and the pledge can establish a network connection with the owner registrar.
This may require that the owner network firewall exposes the registrar on the public internet.

~~~
+--------+                                       +----------+
| Pledge |                                       | Cloud RA |
|        |                                       |          |
+--------+                                       +----------+
    |                                                 |
    | 1. Mutual-authenticated TLS                     |
    |<----------------------------------------------->|
    |                                                 |
    | 2. Voucher Request                              |
    |------------------------------------------------>|
    |                                                 |
    | 3. 307 Location: owner-ra.example.com           |
    |<------------------------------------------------|
    |
    |                  +-----------+             +---------+
    |                  | Owner     |             |  MASA   |
    |                  | Registrar |             |         | 
    |                  +-----------+             +---------+
    | 4. Provisional TLS   |                          |
    |<-------------------->|                          |
    |                      |                          |
    | 5. Voucher Request   |                          |
    |--------------------->| 6. Voucher Request       |
    |                      |------------------------->|
    |                      |                          |
    |                      | 7. Voucher Response      |
    |                      |<-------------------------|
    | 8. Voucher Response  |                          |
    |<---------------------|                          |
    |                      |                          |
    | 9. Validate TLS      |                          |
    |<-------------------->|                          |
    |                      |                          |
    | 10. etc.             |                          |
    |--------------------->|                          |
~~~

The process starts, in step 1, when the Pledge establishes a Mutual TLS channel with the Cloud RA using artifacts created during the manufacturing process of the Pledge.

In step 2, the Pledge sends a voucher request to the Cloud RA.

The Cloud RA completes pledge ownership lookup as outlined in {{pledgeOwnershipLookup}}, and determines the owner registrar domain.
In step 3, the Cloud RA redirects the pledge to the owner registrar domain.

Steps 4 and onwards follow the standard BRSKI flow.
The pledge establishes a provisional TLS connection with the owner registrar, and sends a voucher request to the owner registrar.
The registar forwards the voucher request to the MASA.
Assuming the MASA issues a voucher, then the pledge validates the TLS connection with the registrar using the pinned-domain-cert from the voucher and completes the BRSKI flow.

## Voucher Request Handled by Cloud Registrar {#voucher2EST}

The Voucher includes the EST domain to use for EST enroll.
It is assumed services are accessed at that domain too.
As trust is already established via the Voucher, the pledge does a full TLS handshake against the local RA indicated by the voucher response.

The returned voucher contains an attribute, "est-domain", defined in {{redirected}} below.
The pledge is directed to continue enrollment using the EST registrar found at that URI.
The pledge uses the pinned-domain-cert from the voucher to authenticate the EST registrar.

~~~
+--------+                                       +----------+
| Pledge |                                       | Cloud RA |
|        |                                       | / MASA   |
+--------+                                       +----------+
    |                                                 |
    | 1. Mutual TLS                                   |
    |<----------------------------------------------->|
    |                                                 |
    | 2. Voucher Request                              |
    |------------------------------------------------>|
    |                                                 |
    | 3. Voucher Response  {est-domain:fqdn}          |
    |<------------------------------------------------|
    |                                                 |
    |                 +----------+                    |
    |                 | RFC7030  |                    |
    |                 |  EST     |                    |
    |                 | Registrar|                    |
    |                 +----------+                    |
    |                      |                          |
    | 4. Full TLS          |                          |
    |<-------------------->|                          |
    |                                                 |
    |     3a. /voucher_status POST  success           |
    |------------------------------------------------>|
    |     ON FAILURE 3b. /voucher_status POST         |
    |                                                 |
    | 5. EST Enrol         |                          |
    |--------------------->|                          |
    |                      |                          |
    | 6. Certificate       |                          |
    |<---------------------|                          |
    |                      |                          |
    | 7. /enrollstatus     |                          |
    |--------------------->|                          |
~~~

The process starts, in step 1, when the Pledge establishes a Mutual TLS channel with the Cloud RA/MASA using artifacts created during the manufacturing process of the Pledge.
In step 2, the Pledge sends a voucher request to the Cloud RA/MASA, and in response the Pledge receives an {{RFC8366} format voucher from the Cloud RA/MASA that includes its assigned EST domain in the est-domain attribute.
 
At this stage, the Pledge should be able to establish a TLS channel with the EST Registrar.
The connection may involve crossing the Internet requiring a DNS lookup on the provided name.
It may also be a local address that includes an IP address literal including both {{?RFC1918}} and IPv6 Unique Local Address.  
The EST Registrar is validated using the pinned-domain-cert value provided in the voucher as described in section 5.6.2 of {{I-D.ietf-anima-bootstrapping-keyinfra}}.
This involves treating the artifact provided in the pinned-domain-cert as a trust anchor, and attempting to validate the EST Registrar from this anchor only.  

There is a case where the pinned-domain-cert is the identical End-Entity (EE) Certificate as the EST Registrar.  
It also explicitly includes the case where the EST Registrar has a self-signed EE Certificate, but it may also be an EE certificate that is part of a larger PKI.
If the certificate is not a self-signed or EE certificate, then the Pledge SHOULD apply {{!RFC6125}} DNS-ID validation on the certificate against the URL provided in the est-domain attribute. 
If the est-domain was provided by with an IP address literal, then it is unlikely that it can be validated, and in that case, it is expected that either a self-signed certificate or an EE certificate will be pinned.  

The Pledge also has the details it needs to be able to create the CSR request to send to the RA based on the details provided in the voucher.
 
In step 4, the Pledge establishes a TLS channel with the Cloud RA/MASA, and optionally the pledge should send a request, steps 3.a and 3.b, to the Cloud RA/MASA to inform it that the Pledge was able to establish a secure TLS channel with the EST Registrar.
 
The Pledge then follows that, in step 5, with an EST Enroll request with the CSR and obtains the requested certificate.
The Pledge must validate that the issued certificate has the expected identifier obtained from the Cloud RA/MASA in step 3.

# YANG extension for Voucher based redirect {#redirected}

An extension to the {{RFC8366}} voucher is needed for the case where the client will be redirected to a local EST Registrar.

## YANG Tree

INSERT_TEXT_FROM_FILE ietf-redirected-voucher-tree.txt END

## YANG Voucher

INSERT_TEXT_FROM_FILE ietf-redirected-voucher@DATE.yang END

# IANA Considerations

TODO:MCR - Will need to add IETF YANG registration from templates.
[[ TODO ]]

# Security Considerations

[[ TODO ]]
