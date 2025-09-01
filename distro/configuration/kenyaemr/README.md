# KenyaEMR Configuration

This directory contains configuration files for KenyaEMR modules integration with the PeruHCE distribution.

## Modules Added

### Core KenyaEMR Modules
- **kenyacore-omod**: Core KenyaEMR functionality and data model
- **kenyadq-omod**: Data quality and validation features
- **kenyaui-omod**: KenyaEMR user interface components
- **kenyaemr-orderentry-omod**: Order entry and management system

### Additional Supporting Modules
- **appframework-omod**: Application framework for module development
- **groovy-omod**: Groovy scripting support
- **htmlformentry-omod**: HTML form entry system
- **logic-omod**: Logic and rule engine
- **facilityreporting-omod**: Facility-level reporting
- **apachehttpclient-omod**: HTTP client utilities
- **metadatadeploy-omod**: Metadata deployment tools
- **metadatasharing-omod**: Metadata sharing capabilities
- **reportingcompatibility-omod**: Reporting compatibility layer

## Configuration Files

- `kenyaemr-config.csv`: Basic KenyaEMR configuration entries
- `../globalproperties/globalproperties-kenyaemr.xml`: Global properties for KenyaEMR features

## Dependencies

All modules are configured with `provided` scope in the Maven POM, meaning they will be provided by the OpenMRS platform at runtime.

## Usage

These modules will be automatically loaded when the OpenMRS distribution starts. The configuration files will be processed by the Initializer module to set up the necessary metadata and settings.

## Notes

- KenyaEMR modules are designed for OpenMRS 2.x compatibility
- Some features may require additional configuration in the OpenMRS administration interface
- Test thoroughly in a development environment before deploying to production
