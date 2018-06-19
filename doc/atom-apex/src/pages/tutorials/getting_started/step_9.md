---
title: "Monitor"
description: "Monitor"
buttonTitle: "Done"
parentId: "getting_started"
layout: "tutorial"
time: 90
weight: 9
---

## {$page.title}

When the governor limits are reached is determined by monitors.

Atom.apex has the following built-in monitors.

| Name | Description |
| ---- | ----------- |
| AggregateQueriesMonitor | Aggregate query limit |
| CalloutsMonitor | Call out limit |
| CpuTimeMonitor | Cpu time limit |
| DMLRowsMonitor | DML rows limit |
| DMLStatementsMonitor | DML statement limit |
| EmailInvocationsMonitor | Email invocation limit |
| FutureCallsMonitor | Future call limit |
| HeapSizeMonitor | Heap size limit |
| MobilePushApexCallsMonitor | Mobile push apex call limit |
| QueriesMonitor | Query limit |
| QueryLocatorRowsMonitor | Query locator row limit |
| QueryRowsMonitor | Query row limit |
| QueueableJobsMonitor | Queueable job limit |
| SoslQueriesMonitor | SOSL query limit |

Most of the time, you don't need to care about monitors. However, you could still provide your own monitor.

```java
public class CustomMonitor extends Atom.DefaultMonitor {
    public CustomMonitor() {
        super('Custom limit is reached');
    }

    public override Integer getCurrentValue(Atom.State s) {
        return (Integer)s.getData('count');
    }

    public override Integer getMaxValue(Atom.State s) {
        return 1000;
    }
}

Atom.registerMonitor(new CustomMonitor());
```

