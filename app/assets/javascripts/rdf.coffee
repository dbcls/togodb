RDF = {
  properties: {
    rdf: [
      "first"
      "object"
      "predicate"
      "rest"
      "subject"
      "type"
      "value"]
    rdfs: [
      "comment"
      "domain"
      "isDefinedBy"
      "label"
      "member"
      "range"
      "seeAlso"
      "subClassOf"
      "subPropertyOf"]
    dc: [
      "contributor"
      "coverage"
      "creator"
      "date"
      "description"
      "format"
      "identifier"
      "language"
      "publisher"
      "relation"
      "rights"
      "source"
      "subject"
      "title"
      "type"]
    dcterms: [
      "abstract"
      "accessRights"
      "accrualMethod"
      "accrualPeriodicity"
      "accrualPolicy"
      "alternative"
      "audience"
      "available"
      "bibliographicCitation"
      "conformsTo"
      "contributor"
      "coverage"
      "created"
      "creator"
      "date"
      "dateAccepted"
      "dateCopyrighted"
      "dateSubmitted"
      "description"
      "educationLevel"
      "extent"
      "format"
      "hasFormat"
      "hasPart"
      "hasVersion"
      "identifier"
      "instructionalMethod"
      "isFormatOf"
      "isPartOf"
      "isReferencedBy"
      "isReplacedBy"
      "isRequiredBy"
      "issued"
      "isVersionOf"
      "language"
      "license"
      "mediator"
      "medium"
      "modified"
      "provenance"
      "publisher"
      "references"
      "relation"
      "replaces"
      "requires"
      "rights"
      "rightsHolder"
      "source"
      "spatial"
      "subject"
      "tableOfContents"
      "temporal"
      "title"
      "type"
      "valid"]
    foaf: ["account"
      "accountName"
      "accountServiceHomepage"
      "age"
      "aimChatID"
      "based_near"
      "birthday"
      "currentProject"
      "depiction"
      "depicts"
      "dnaChecksum"
      "familyName"
      "family_name"
      "firstName"
      "focus"
      "fundedBy"
      "geekcode"
      "gender"
      "givenName"
      "givenname"
      "holdsAccount"
      "homepage"
      "icqChatID"
      "img"
      "interest"
      "isPrimaryTopicOf"
      "jabberID"
      "knows"
      "lastName"
      "logo"
      "made"
      "maker"
      "mbox"
      "mbox_sha1sum"
      "member"
      "membershipClass"
      "msnChatID"
      "myersBriggs"
      "name"
      "nick"
      "openid"
      "page"
      "pastProject"
      "phone"
      "plan"
      "primaryTopic"
      "publications"
      "schoolHomepage"
      "sha1"
      "skypeID"
      "status"
      "surname"
      "theme"
      "thumbnail"
      "tipjar"
      "title"
      "topic"
      "topic_interest"
      "weblog"
      "workInfoHomepage"
      "workplaceHomepage"
      "yahooChatID"]
    skos: ["altLabel"
      "broadMatch"
      "broader"
      "broaderTransitive"
      "changeNote"
      "closeMatch"
      "definition"
      "editorialNote"
      "exactMatch"
      "example"
      "hasTopConcept"
      "hiddenLabel"
      "historyNote"
      "inScheme"
      "mappingRelation"
      "member"
      "memberList"
      "narrowMatch"
      "narrower"
      "narrowerTransitive"
      "notation"
      "note"
      "prefLabel"
      "related"
      "relatedMatch"
      "scopeNote"
      "semanticRelation"
      "topConceptOf"]
  }

  classes: {
    rdf: ["Alt"
      "Bag"
      "List"
      "Property"
      "Seq"
      "Statement"]
    rdfs: ["Class"
      "Container"
      "ContainerMembershipProperty"
      "Datatype"
      "Literal"
      "Resource"]
    dcterms: ["Agent"
      "AgentClass"
      "BibliographicResource"
      "FileFormat"
      "Frequency"
      "Jurisdiction"
      "LicenseDocument"
      "LinguisticSystem"
      "Location"
      "LocationPeriodOrJurisdiction"
      "MediaType"
      "MediaTypeOrExtent"
      "MethodOfAccrual"
      "MethodOfInstruction"
      "PeriodOfTime"
      "PhysicalMedium"
      "PhysicalResource"
      "Policy"
      "ProvenanceStatement"
      "RightsStatement"
      "SizeOrDuration"
      "Standard"]
    foaf: ["Agent"
      "Document"
      "Group"
      "Image"
      "LabelProperty"
      "OnlineAccount"
      "OnlineChatAccount"
      "OnlineEcommerceAccount"
      "OnlineGamingAccount"
      "Organization"
      "Person"
      "PersonalProfileDocument"
      "Project"]
    skos: ["Collection"
      "Concept"
      "ConceptScheme"
      "OrderedCollection"]
  }

  prefix2ns: (prefix) ->
    ns =
      "rdf":     "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
      "rdfs":    "http://www.w3.org/2000/01/rdf-schema#"
      "dc":      "http://purl.org/dc/elements/1.1/"
      "dcterms": "http://purl.org/dc/terms/"
      "foaf":    "http://xmlns.com/foaf/0.1/"
      "skos":    "http://www.w3.org/2004/02/skos/core#"
    ns[prefix];

  get_rdf_property: (prefix, property) ->
    RDF.prefix2ns(prefix) + property;

  onchange_property_prefix_selector: (elem) ->
    selector_id = $(elem).attr("id");
    column_id = $("#" + selector_id).attr("id").slice("togodb-column-rdf-property-prefix-selector".length + 1);
    selected_prefix = $("#" + selector_id + " option:selected").val();
    property_selector_id = "togodb-column-rdf-property-selector-" + column_id;
    properties = RDF.properties[selected_prefix];
    if (!properties)
      properties = ["----------"];

    $("select#" + property_selector_id).children().remove();
    $.each(properties, ->
      $("select#" + property_selector_id).append('<option value="' + this + '">' + this + '</option>')
      return
    );

    rdf_property = "";
    if selected_prefix isnt ""
      rdf_property = RDF.get_rdf_property(selected_prefix, properties[0]);
    $("#togodb-column-rdf-property-" + column_id).val(rdf_property);


  onchange_property_property_selector: (elem) ->
    selector_id = $(elem).attr("id");
    column_id = $("#" + selector_id).attr("id").slice("togodb-column-rdf-property-selector".length + 1);
    selected_prefix = $("select#togodb-column-rdf-property-prefix-selector-" + column_id + " option:selected").val();
    selected_property = $("#" + selector_id + " option:selected").val();
    $("#togodb-column-rdf-property-" + column_id).val(RDF.get_rdf_property(selected_prefix, selected_property));

  onchange_class_prefix_selector: (elem) ->
    selector_id = $(elem).attr("id")
    column_id = $("#" + selector_id).attr("id").slice("togodb-column-rdf-class-prefix-selector".length + 1)
    selected_prefix = $("#" + selector_id + " option:selected").val()
    property_selector_id = "togodb-column-rdf-class-selector-" + column_id
    properties = RDF.classes[selected_prefix]
    if (!properties)
      properties = ["----------"];
    $("select#" + property_selector_id).children().remove()
    $.each(properties, ->
       $("select#" + property_selector_id).append('<option value="' + this + '">' + this + '</option>')
       return
    )

    rdf_property = ""
    if selected_prefix isnt ""
      rdf_property = RDF.get_rdf_property(selected_prefix, properties[0])

    $("#togodb-column-rdf-class-" + column_id).val(rdf_property)

  onchange_class_property_selector: (elem) ->
    selector_id = $(elem).attr("id")
    column_id = $("#" + selector_id).attr("id").slice("togodb-column-rdf-class-selector".length + 1)
    selected_prefix = $("select#togodb-column-rdf-class-prefix-selector-" + column_id + " option:selected").val()
    selected_property = $("#" + selector_id + " option:selected").val()
    $("#togodb-column-rdf-class-" + column_id).val(RDF.get_rdf_property(selected_prefix, selected_property))
    return
}

# Column setting > RDF
$ ->
  $("select.togodb-column-rdf-property-prefix-selector").on 'change', ->
    RDF.onchange_property_prefix_selector this

  $("select.togodb-column-rdf-property-selector").on 'change', ->
    RDF.onchange_property_property_selector this

  $("select.togodb-column-rdf-class-prefix-selector").on 'change', ->
    RDF.onchange_class_prefix_selector this
  
  $("select.togodb-column-rdf-class-selector").on 'change', ->
    RDF.onchange_class_property_selector this
