# Opencast

Opencast is a fork of the brilliant [Hazelcast](https://hazelcast.com), for releasing patched versions of the open-source edition of Hazelcast.

Hazelcast [announced in 2024](https://hazelcast.com/blog/changes-to-community-edition/) that they'd no longer provide CVE patches for their open-source releases.

That's entirely their prerogative. After all, they've gotta make money.

However, the net result is that Hazelcast OSS remains unpatched, often for months on end.

This fork is maintained by [Orbital](https://orbitalhq.com), a data integration and context layer platform.

We're big users of Hazelcast, and we run Opencast in our own platform. We're dogfooding it: every release goes into Orbital's own build and test suite before it ships.

## Using Opencast

Opencast is a drop-in replacement for the matching Hazelcast release. Only the Maven `groupId` changes. Package names (`com.hazelcast.*`), configuration and XML namespaces are the same as upstream, so no code changes are needed.

Releases are published to Orbital's Maven repository, not Maven Central:

```xml
<repositories>
   <repository>
      <id>orbital</id>
      <url>https://repo.orbitalhq.com/release</url>
   </repository>
</repositories>

<dependencies>
   <dependency>
      <groupId>com.orbitalhq.opencast</groupId>
      <artifactId>hazelcast</artifactId>
      <version>5.7.0-opencast-1</version>
   </dependency>
</dependencies>
```

Gradle:

```kotlin
repositories {
    maven("https://repo.orbitalhq.com/release")
}

dependencies {
    implementation("com.orbitalhq.opencast:hazelcast:5.7.0-opencast-1")
}
```

Snapshots of the next release are at `https://repo.orbitalhq.com/snapshot`.

### Published artifacts

| Artifact | Replaces |
|---|---|
| `com.orbitalhq.opencast:hazelcast` | `com.hazelcast:hazelcast` |
| `com.orbitalhq.opencast:hazelcast-spring` | `com.hazelcast:hazelcast-spring` |
| `com.orbitalhq.opencast:hazelcast-spring-boot3` | `com.hazelcast:hazelcast-spring-boot3` |
| `com.orbitalhq.opencast:hazelcast-spring-boot4` | `com.hazelcast:hazelcast-spring-boot4` |

### Don't end up with both

Libraries that depend on Hazelcast will still pull in `com.hazelcast:hazelcast`, and you don't want both jars on the classpath. The common one is Spring Boot's `spring-boot-starter-hazelcast`. Exclude it, and declare Opencast directly:

```xml
<dependency>
   <groupId>org.springframework.boot</groupId>
   <artifactId>spring-boot-starter-hazelcast</artifactId>
   <exclusions>
      <exclusion>
         <groupId>com.hazelcast</groupId>
         <artifactId>hazelcast</artifactId>
      </exclusion>
   </exclusions>
</dependency>
```

`mvn dependency:tree -Dincludes=com.hazelcast` should come back empty.

## Version numbers

Opencast versions are `<hazelcast version>-opencast-<n>`:

- `5.7.0-opencast-1` is Hazelcast 5.7.0, plus our first set of patches.
- `5.7.0-opencast-2` would be the next patch release on the same Hazelcast version.
- When Hazelcast ships a new OSS release, we start again at `-opencast-1` on top of it (e.g. `5.8.0-opencast-1`).

At runtime, members and clients report the upstream version (e.g. `5.7.0`, cluster version `5.7`). That's also why we don't use four-part versions like `5.7.0.1`: Hazelcast parses its own version number, and only accepts `major.minor.patch` with an optional suffix.

## Releases

Each release branch (e.g. `release/5.7`) is cut from the upstream release tag (`v5.7.0`). Releases are tagged on it, and `master` tracks upstream.

| Release | Based on | What's patched |
|---|---|---|
| `5.7.0-opencast-1` | Hazelcast 5.7.0 | Backports of the security fixes from Hazelcast's 5.7.1 and 5.7.2 Enterprise releases, where they apply to OSS. Shaded Jackson upgraded to 2.21.7 / 3.1.7, which fixes CVE-2026-54512, CVE-2026-54513, CVE-2026-68497, CVE-2026-91776, CVE-2026-91777 (jackson-databind) and CVE-2026-68494, CVE-2026-89407, CVE-2026-89425 (jackson-core). Netty 4.1.138, Spring 6.2.19 and Tomcat 10.1.61. |

Backports are cherry-picked from upstream where possible (`git cherry-pick -x`), so each commit links back to the original.

## What we will and won't do

- **We patch on a best-efforts basis.** There's no SLA. We maintain this because we need it, and we're sharing it because others probably do too.
- **We fix HIGH and CRITICAL CVEs.** We're happy to take PRs that fix CVEs of any severity.
- **We're not fixing bugs**, other than porting CVE fixes. Opencast deliberately stays as close to upstream as possible. Bug reports and feature requests belong with [Hazelcast](https://github.com/hazelcast/hazelcast).
- **We're only maintaining and releasing the Apache 2.0 modules.** Modules under the [Hazelcast Community License](http://hazelcast.com/hazelcast-community-license), such as `hazelcast-sql` and the Jet extensions, aren't published. Neither are the distribution zip and the Docker images.
- **We only maintain release lines we use.** Currently that's 5.7.

## Contributing

PRs that fix a CVE are welcome. Where there's an upstream fix, please backport that rather than writing your own, and keep the change as small as possible. Dependency upgrades that fix a CVE are welcome too. Target the release branch (e.g. `release/5.7`).

If you've found a vulnerability in Hazelcast itself, please report it to Hazelcast first, following their [security policy](https://github.com/hazelcast/hazelcast/security/policy).

## Licensing and trademarks

Everything Opencast publishes is under the [Apache License 2.0](LICENSE), the same as the upstream modules it comes from. The repository also contains upstream's Hazelcast Community License source, which we leave in place but don't publish (see [License](#license) below).

Hazelcast is a trademark of Hazelcast, Inc. Opencast isn't affiliated with, or endorsed by, Hazelcast, Inc. The code is theirs; the patches and the bugs we introduce are ours.

---

*The original Hazelcast README follows.*

# Hazelcast

[![Slack](https://img.shields.io/badge/slack-chat-green.svg)](https://slack.hazelcast.com/) 
[![javadoc](https://javadoc.io/badge2/com.hazelcast/hazelcast/latest/javadoc.svg)](https://javadoc.io/doc/com.hazelcast/hazelcast/latest)
[![Docker pulls](https://img.shields.io/docker/pulls/hazelcast/hazelcast)](https://hub.docker.com/r/hazelcast/hazelcast)

----

## What is Hazelcast

The world’s leading companies trust Hazelcast to modernize applications and take instant action on data in motion to create new revenue streams, mitigate risk, and operate more efficiently. Businesses use Hazelcast’s unified **real-time data platform** to process **streaming** data, enrich it with historical context and take instant action with standard or **ML/AI-driven automation** - before it is stored in a database or data lake. 

Hazelcast is named in the Gartner Market Guide to Event Stream Processing and a leader in the GigaOm Radar Report for Streaming Data Platforms. To join our community of CXOs, architects and developers at brands such as Lowe’s, HSBC, JPMorgan Chase, Volvo, New York Life, and others, visit [hazelcast.com](https://hazelcast.com).

## When to use Hazelcast

Hazelcast provides a platform that can handle multiple types of workloads for
building real-time applications.

* Stateful data processing over streaming data or data at rest
* Querying streaming and batch data sources directly using SQL
* Ingesting data through a library of connectors and serving it using
  low-latency SQL queries
* Pushing updates to applications on events
* Low-latency queue-based or pub-sub messaging  
* Fast access to contextual and transactional data via caching patterns such as
  read/write-through and write-behind
* Distributed coordination for microservices
* Replicating data from one region to another or between data centers in the
  same region

## Key Features

* [Stateful and fault-tolerant data processing and querying over data streams
  and data](#stateful-data-Processing) at rest using [SQL](https://docs.hazelcast.com/hazelcast/latest/sql/sql-overview) or dataflow API
* [A comprehensive library of connectors such as Kafka, Hadoop, S3, RDBMS, JMS
  and many more](https://docs.hazelcast.com/hazelcast/latest/integrate/connectors)
* Distributed messaging using [pub-sub](https://docs.hazelcast.com/hazelcast/latest/data-structures/topic.html) and [queues](https://docs.hazelcast.com/hazelcast/latest/data-structures/queue.html)
* [Distributed, partitioned, queryable key-value store with event listeners,
  which can also be used to store contextual data for enriching event streams
  with low latency](https://docs.hazelcast.com/hazelcast/latest/data-structures/map)
* Tight integration for deploying machine learning models with Python to a data
  processing pipeline
* Cloud-native, run everywhere architecture
* Zero-downtime operations with rolling upgrades
* At-least-once and exactly-once processing guarantees for stream processing
  pipelines
* Data replication between data centers and geographic regions using WAN 
* Microsecond performance for key-value point lookups and pub-sub
* Unique data processing architecture results in 99.99% latency of under 10ms
  for streaming queries with millions of events per second.
* Client libraries in [Java](https://github.com/hazelcast/hazelcast),
 [Python](https://github.com/hazelcast/hazelcast-python-client), [Node.js](https://github.com/hazelcast/hazelcast-nodejs-client), [.NET](https://github.com/hazelcast/hazelcast-csharp-client), [C++](https://github.com/hazelcast/hazelcast-cpp-client) and [Go](https://github.com/hazelcast/hazelcast-go-client)

### Stateful Data Processing

Hazelcast has a built-in data processing engine called
[Jet](https://docs.hazelcast.com/hazelcast/latest/pipelines/overview#what-is-the-jet-engine), which can be used to build both streaming/real-time
and batch/static data pipelines that are elastic. A single node of Hazelcast has been proven to [aggregate 10 million
events per second](https://foojay.io/today/sub-10-ms-latency-in-java-concurrent-gc-with-green-threads/) with
latency under 10 milliseconds. A cluster of Hazelcast nodes can process [billion
events per
second](https://hazelcast.com/blog/billion-events-per-second-with-millisecond-latency-streaming-analytics-at-giga-scale/).

## Get Started

Follow the [Getting Started
Guide](https://docs.hazelcast.com/hazelcast/latest/getting-started/install-hazelcast)
to install and start using Hazelcast.

## Documentation

Read the [documentation](https://docs.hazelcast.com/) for
in-depth details about how to install Hazelcast and an overview of the features.

## Get Help

You can use [Slack](https://slack.hazelcast.com/) for getting help with Hazelcast.

## How to Contribute

Thanks for your interest in contributing! The easiest way is to just send a pull
request.

### Building From Source

Building Hazelcast requires at minimum JDK 17. Pull the latest source from the
repository and use Maven install (or package) to build:

```bash
$ git pull origin master
$ ./mvnw clean package -DskipTests
```

It is recommended to use the included Maven wrapper script.
It is also possible to use local Maven distribution with the same 
version that is used in the Maven wrapper script.

Additionally, there is a `quick` build activated by setting the `-Dquick` system
property that skips validation tasks for faster local builds (e.g. tests, checkstyle
validation, javadoc, source plugins etc) and does not build `extensions` and `distribution` 
modules.

### Testing

Take into account that the default build executes thousands of tests which may
take a considerable amount of time. Hazelcast has 3 testing profiles:

* Default: 
  ```bash
  ./mvnw test
  ```
to run quick/integration tests (those can be run
  in parallel without using network by using `-P parallelTest` profile).
* Slow Tests: 
  ```bash
  ./mvnw test -P nightly-build
  ```
to run tests that are either slow
  or cannot be run in parallel.
* All Tests:
  ```bash
  ./mvnw test -P all-tests
  ```
to run all tests serially using
  network.

Some tests require Docker to run. Set `-Dhazelcast.disable.docker.tests` system property to ignore them.

When developing a PR it is sufficient to run your new tests and some 
related subset of tests locally. Our PR builder will take care of running
the full test suite.

## License

Source code in this repository is covered by one of two licenses:

 * [Apache License 2.0](https://docs.hazelcast.com/hazelcast/latest/index.html#licenses-and-support)
 * [Hazelcast Community
    License](http://hazelcast.com/hazelcast-community-license)

The default license throughout the repository is Apache License 2.0 unless the
header specifies another license.

## Acknowledgments
We owe (the good parts of) our CLI tool's user experience to
[picocli](https://picocli.info/).

## Copyright

Copyright (c) 2008-2026, Hazelcast, Inc. All Rights Reserved.

Visit [www.hazelcast.com](http://www.hazelcast.com/) for more info.
