openmrs-config-ces
==============================

### Prerequistes

Some utility scripts, "install.sh" and "watch.sh", have been written to ease having to manually run mvn install
and watch commands on both this project and the "openmrs-config-pihemr" project.

However, these scripts depend on finding your "openmrs-config-pihemr" relative to this project, so they should both be 
checked out into the same directory, and the "openmrs-config-pihemr" directory should be named "openmrs-config-pihemr"
or "config-pihemr".

Example directory structure:

openmrs-config-pihemr
openmrs-config-ces

or

config-pihemr
config-ces

### Steps to deploy new changes to your local development server

Run "./install.sh [serverId]" where [serverId] is the name of the SDK server you are deploying to.  This will first build 
the config-pihemr project, then build the config-ces project, (pulling in any changes to config-pihemr),
and finally deploying the changes to the server specified by [serverId].

#### To enable watching, you run the following:

"./watch.sh [serverId]" where [serverId] is the name of the SDK server you are deploying too.  This will watch
*both* the config-pihemr and config-ces projects for changes and redeploy when there are changes.  It runs
indefinitely, so you will need to cancel it with a "Ctrl-C".


### General usage

`mvn clean compile` - Will generate your configurations into "target/openmrs-packager-config/configuration"
`mvn clean package` - Will compile as above, and generate a zip package at "target/${artifactId}-${version}.zip"

In order to facilitate deploying configurations easily into an OpenMRS SDK server, one can add an additional parameter
to either of the above commands to specify that the compiled configuration should also be copied to an existing 
OpenMRS SDK server:

`mvn clean compile -DserverId=ces` - Will compile as above, and copy the resulting configuration to `~/openmrs/ces/configuration`

If the configuration package you are building will be depended upon by another configuration package, you must "install" it
in order for the other package to be able to pick it up.

`mvn clean install` - Will compile and package as above, and install as an available dependency on your system

For more details regarding the available commands please see:
https://github.com/openmrs/openmrs-contrib-packager-maven-plugin 


### Configuring Concepts for Chiapas

We currently used two different approaches to install concepts on the Mexico server.  For Diagnoses and Drugs, we are 
trialing using Initializer as easier and streamlined way to manage the diagnosis and drug lists.  For
other concepts (such as those used on Mexico forms) we use Metadata Sharing.

#### Adding New Diagnoses

The Diagnoses are groups into 4 Diagnoses sets:

* Mexico primary care diagnosis set (2791)
* Mexico MCH diagnosis set (5780)
* Mexico mental diagnosis set (5779)
* COVID-19 diagnosis set (5019)

Each set has a CSV file that defines all the concepts in the set, found in this directory:
https://github.com/PIH/openmrs-config-ces/tree/master/configuration/concepts

And then a separate file that explicitly sets up the set membership:
https://github.com/PIH/openmrs-config-ces/tree/master/configuration/concepts

To add a new concept:
* Search the Concept server (concepts.pih-emr.org) to determine if the concept currently exists in PIH EMR dictionary
* If it does not exist, search for it in the CIEL dictionary, using the Open Concept Lab:
  * Go to "https://openconceptlab.org/" and search for the term
  * Filter the results to "CIEL" and select the appropriate CIEL concept
  * (If no appropriate CIEL concept found, more analysis will likely be needed)
* Once you've found the concept, create a line in the appropriate diagnosis csv file for the new concept:
  * If the concept exists in the PIH EMR dictionary, set the uuid to the same uuid as the existing concept 
  * Otherwise, set the uuid to the "External ID" listed for the concept in OCL
  * Add the Spanish name you want to use as the Fully Specified Name to the "Fully Specified Name:es" column; add any Spanish short name or synonym to the "Short Name:es" column
    * Ideally, this would be the fully-specified Spanish name as defined on the Concept server or in CIEL
  * Add the English fully-specified name (taken from the PIH EMR dictionary or the CIEL dictionary) to the "Fully Specified Name:en" column
  * Add the description to the description column (OPTIONAL)
  * Add the appropriate Data Class and Data Type to the Data Class and Data Type column (generally "Diagnosis" and "N/A")
  * Add mapping codes as needed to the concept:
    * If the concept exists in the PIH EMR Dictionary, add the PIH mappings to the "PIH:Mappings|SAME-AS|PIH|Name" (for alphanumeric) and/or "Mappings|SAME-AS|PIH|Number" (for codes) as appropriate
    * Add the CIEL mapping to the "Mappings|SAME-AS|CIEL" column  (Look in the "Associations" section of OCL to find the Code, Source, and Relationship... note that it's the "Code" you want, not the "Name)
    * Add at least one ICD-10-WHO mapping to the appropriate "Mappings|*|ICD-10-WHO" column   (Again, look in the "Associations" section of OCL to find the Code, Source, and Relationship... note that it's the "Code" you want, not the "Name")
    * Any other mappings can be skipped
  * Move the row as necessary to maintain alphabetical sorting by "Fully Specified Name:es" (not necessary, but good practice)
* Update the concept set file:
  * Create a new row, setting the "Member" column to the "Fully Specified Name:es" of the new concept
    * Sort alphabetically and update the Sort Weight columns to maintain that order (not necessary, but good practice)
 

NOTE/TODO: we may want to consider simplifying this into a single diagnosis set, if this is easier.
NOTE/TODO: we may want to remove the other mapping columns we aren't using (AMPATH, etc) entirely

#### Adding New Drugs

TODO

#### Configuring other Concepts

(TODO: rework this when we next add a new form? what should the process be here?)

1. On the concepts server (concepts.pih-emr.org), create a "Mexico MoH (Ministry of Health, or equivalent..) concept set", similar to the “[Liberia MoH diagnosis set](https://concepts.pih-emr.org/openmrs/dictionary/concept.htm?conceptId=10595)”. Create child sets, e.g. “Mexico MoH diagnosis”, “Mexico MoH Labs”, etc. Add concepts to these subsets.

2. For each concept in the source data dictionary:

    1. If there is an existing concept in the concepts server that is an exact match, add a mapping to the "Mexico MoH" vocabulary item, and a Spanish translation if required.

    2. If there is no existing concept, create it and add vocabulary mapping and translation.

    3. Add this concept to appropriate concept set.

3. In the Metadata Sharing module, create a package called "Mexico Concepts" and create a new version. See example here for “[Liberia Concepts](https://concepts.pih-emr.org/openmrs/module/metadatasharing/export/details.form?group=c0dc491e-a26e-4dee-99c4-c4dc5cb2e787)”.

4. Download the zipped package of this version.

5. Add the zip file to the PIH openmrs-module-mirebalais-metadata Github repo [here](https://github.com/PIH/openmrs-module-mirebalaismetadata/tree/master/api/src/main/resources). This will add the metadata concepts to our build pipeline.

6. The concepts should then be available companero staging server.

#### Diagnoses

Add diagnoses concept set setting here: [https://github.com/PIH/openmrs-module-pihcore/blob/master/api/src/main/java/org/openmrs/module/pihcore/deploy/bundle/mexico/MexicoMetadataBundle.java](https://github.com/PIH/openmrs-module-pihcore/blob/master/api/src/main/java/org/openmrs/module/pihcore/deploy/bundle/mexico/MexicoMetadataBundle.java)

Example: [https://github.com/PIH/openmrs-module-pihcore/blob/master/api/src/main/java/org/openmrs/module/pihcore/deploy/bundle/haiti/HaitiMetadataBundle.java#L100](https://github.com/PIH/openmrs-module-pihcore/blob/master/api/src/main/java/org/openmrs/module/pihcore/deploy/bundle/haiti/HaitiMetadataBundle.java#L100)
