# Prototype localStorage Migration

The legacy key is `aftifestCommandData`. Migration is explicit and admin-only.

1. Export JSON from the reference prototype.
2. Upload it to the migration preview endpoint.
3. Validate structure, size, supported keys, dates, URLs, and relationships.
4. Show counts, warnings, rejected records, and disputed facts without writing data.
5. Mark every proposed record `SAMPLE / UNAPPROVED`.
6. Require an explicit confirmation tied to the preview digest.
7. Import in one database transaction, preventing duplicate digests.
8. Record actor, source digest, counts, warnings, and resulting identifiers in the audit log.

The importer never silently treats prototype records as approved organizational truth.
