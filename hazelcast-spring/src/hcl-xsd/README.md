# Hazelcast Community License XSDs

The `hazelcast-spring-4.1.xsd` .. `hazelcast-spring-5.7.xsd` schemas are licensed under the
Hazelcast Community License, not Apache 2.0, so they are not packaged into the published
`hazelcast-spring` jar. They are kept here only so the Spring XML configuration tests in
`hazelcast-spring` and `hazelcast-spring-tests` can run; both modules add this directory as a
test resource.

The published jar ships only the Apache-licensed `hazelcast-spring-4.0.xsd`. Spring XML
configuration that references a newer schema version will have Spring resolve it from the
`schemaLocation` URL instead of the classpath.
